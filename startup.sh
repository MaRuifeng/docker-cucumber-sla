#!/bin/bash

## Get arguments as environment variables
export APP_BUILD=$1
export TEST_PHASE=$2

## Start the ssh service
/usr/sbin/sshd

## Start the Xvfb virtual display service
cd 
# create an Xvfb virtual display in the background (another screen size: 1080x1440x24)
Xvfb :99 -ac -screen 0 1680x1080x24 &  
sleep 5 # wait for Xvfb display server session to be ready  
export DISPLAY=:99

## Start a vnc session to the virtual display created above
x11vnc -forever -usepw -display :99 &
# -geometry 1680x1080

# Grant user cobalt file permissions
chown -R cobalt:cobalt /home/cobalt/

# Modify the etc/hosts file with additional host/ip pairs
echo -e "\n\n" >> /etc/hosts
cat /home/cobalt/cucumber/config/environments/${TEST_PHASE}/host.info >> /etc/hosts

# [Chef helper] Resolve cookbook dependencies using berkshelf and upload them to the Chef server
# [Chef helper] Check data bags and upload them to the Chef server
su cobalt <<'EOF'
source /home/cobalt/.rvm/scripts/rvm
echo $(ruby -v)
cd /home/cobalt/cucumber/chef_helper
PATH=$HOME/.chefdk/gem/ruby/2.1.0/bin:/opt/chefdk/bin:$PATH
knife ssl fetch
knife ssl check
berks install
echo -e "\n\n\033[0;34mRunning berks to upload the cookbooks ...\n\033[0m"
berks upload --no-ssl-verify
[[ $? -ne 0 ]] && echo -e "\033[0;31m\nBerks upload failed!\n\n\033[0m"
# Note that directory names for data bag items should not contain white spaces
data_bags=$(ls data_bags)
data_bags_on_chef=$(knife data bag list)
cd data_bags
for item in ${data_bags[@]}; do
	if [[ $data_bags_on_chef != *$item* ]]; then  # wildcard check
		[ -d $item ] && knife data bag create $item # create data bag on Chef
	fi
	[ -d $item ] && knife data bag from file $item $item/*.json # update data bag items
done
echo "Current data bags on the Chef server: " && knife data bag list
EOF

# [Chef helper] Bootstrap endpoint server
su cobalt <<'EOF'
source /home/cobalt/.rvm/scripts/rvm
echo $(ruby -v)
cd /home/cobalt/cucumber/chef_helper
while IFS=$'\t' read -r -a item_array
do
	item_count=${#item_array[@]}
	managed_nodes=$(knife node list)
	for (( i=0; i<${item_count}; i++ )) 
	do
	    item=${item_array[$i]}
	    set -- $(echo $item | awk '{ print $1, $2, $3, $4, $5, $6 }')
	    hostname=$1
	    ip=$2
	    platform=$3
	    testphase=$6

        shopt -s nocasematch

	    if [[ $testphase != ${TEST_PHASE} ]]; then
	        continue
	    fi

	    if [[ $platform =~ "windows" ]]; then
			username=$4
	    	password=$5
	    	if [[ $managed_nodes != *$hostname* ]]; then
	    		echo -e "\n\n\033[0;34mBootstrapping server $ip with node name $hostname ...\033[0m\n"
	    		knife bootstrap windows winrm $ip --winrm-user $username --winrm-password $password --node-name $hostname
	    		if [[ $? -ne 0 ]]; then
	    		    echo -e "\033[0;31m\nBootstrapping server $hostname failed!\033[0m"
	    		    knife node delete $hostname -y
	    		    knife client delete $hostname -y
	    		fi
	    	fi
	    fi

	    if [[ $platform =~ "linux" ]]; then
	        username=$4
	    	key_path=$5
	    	if [[ $managed_nodes != *$hostname* ]]; then
	    	    echo -e "\n\n\033[0;34mBootstrapping server $ip with node name $hostname ...\033[0m\n"
	    	    knife bootstrap $ip -x $username -i $key_path --sudo --node-name $hostname
	    	    if [[ $? -ne 0 ]]; then
	    		    echo -e "\033[0;31m\nBootstrapping server $hostname failed!\033[0m"
	    		    knife node delete $hostname -y
	    		    knife client delete $hostname -y
	    		fi
	    	fi
	    fi
	    
	    shopt -u nocasematch
    done
done < <(< endpoint.list grep -vE '(^#|^\s*$|^\s*\t*#)')
echo -e "\n\n\033[0;34mShowing bootstrapped nodes:\033[0m \n"
knife node list
EOF

## Run cucumber
su cobalt <<'EOF'
cd
source /home/cobalt/.rvm/scripts/rvm
echo $(ruby -v)
# It's good to create the required directories in advance because there might be some conflicts during parallel tests if creating on the fly
mkdir cuke_report_logs
mkdir -p ccssd-test/$APP_BUILD/$TEST_PHASE/cucumber-result/ui/logs
mkdir -p ccssd-test/$APP_BUILD/$TEST_PHASE/cucumber-result/ui/screenshots
mkdir -p ccssd-test/$APP_BUILD/$TEST_PHASE/cucumber-result/ui/cuke-reports
mkdir -p ccssd-test/$APP_BUILD/$TEST_PHASE/cucumber-result/ui/junit
cd /home/cobalt/cucumber
echo "Xvfb display number:"
echo $DISPLAY
echo "Installing/updating gems..."
bundle install
echo "Running cucumber..."
# bundle exec parallel_cucumber features/compliance_console -o "-p ${TEST_PHASE}"
# bundle exec parallel_cucumber features/continuous_compliance -o "-p ${TEST_PHASE}"
cucumber -p ${TEST_PHASE} --tags @${TEST_PHASE} features
cucumber_exit_code=$?
if [[ ( $cucumber_exit_code -ne 0 ) && ( $cucumber_exit_code -ne 1 ) ]]; then
	echo "Cucumber failed abnormally with exit code $cucumber_exit_code. Re-run it to capture the error stack trace..."
	export CUCUMBER_STDERR=$(cucumber -p ${TEST_PHASE} --tags @${TEST_PHASE} features 2>&1 >/dev/null)
	# echo "$CUCUMBER_STDERR"
	export CUCUMBER_ERROR=true
fi
echo "Reporting..."
cd /home/cobalt/cucumber/report
ruby report.rb
erb /home/cobalt/cucumber/cucumber_nginx.conf.erb > /home/cobalt/cucumber/cucumber_nginx.conf
EOF

## Copy cucumber html results to the default Nginx content folder
# cp -rf /home/cobalt/ccssd-test/$APP_BUILD/$TEST_PHASE/cucumber-result/* /usr/share/nginx/html

## Start Nginx server
# using global directive 'daemon off' to 
# ensure the docker container does not halt after Nginx spawns its processes
echo "Starting Nginx server with customized configuration..."
/usr/sbin/nginx -g 'daemon off;' -c /home/cobalt/cucumber/cucumber_nginx.conf
