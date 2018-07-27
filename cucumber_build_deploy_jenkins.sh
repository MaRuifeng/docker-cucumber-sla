#!/bin/bash -e
##########################################################################################
# SLA-UI cucumber build & deploy for development/test dockerized environment
# 1. Build docker images with proper version tag and push it to DTR
#    Note: this build script is primarily written for Jenkins use (https://itaas-build.sby.ibm.com:9443/),
#          and it takes git resources and environment variables from preceding steps.
# 2. Package deployment scripts/files into a tar ball
# 3. Transfer the tar ball to the designated server
# 4. Deploy the required containers via SSH
# 
# Note: this script is used by Jenkins job CCSSD-Cucumber_UI only

# Author:
#  Ruifeng Ma <ruifengm@sg.ibm.com>
# Date:
#  2017-Apr-03
##########################################################################################

export DTR_HOST='DTR_HOST'
export DTR_ORG='DTR_ORG'
# supply actual values to above two variables
export DTR_USER=${ARTIFACTORY_DTR_USER}
export DTR_PASS=${ARTIFACTORY_DTR_PASS}

################## Environment Variable Setup (Start) ##################
rm -f job.properties

if [ -z ${BUILD_VERSION_IN} ]; then
    # define version
    # check if it contains tag if yes, use tag as version, otherwise, use branch name
    TMP_VERSION=""
    if [[ $CCSSD_Core_TagName =~ .*refs/tags/.* ]]
    then
        TMP_VERSION=${CCSSD_Core_TagName#*refs/tags/}
    else
        TMP_VERSION=${CCSSD_Core_TagName##*/}
    fi

    export COMPONENT=sla-cuke
    # Get Timestamp
    export DATE_TIME=$(date "+%Y%m%d-%H%M")
    # Construct build version
    export BUILD_VERSION=${COMPONENT}.${TMP_VERSION}.${DATE_TIME}.${BUILD_NUMBER}
    # Get git commit hash
    cd $WORKSPACE/sla_ui
    # export COMMIT_HASH=$(git rev-parse refs/remotes/sla_ui/Development^{commit})
    export COMMIT_HASH=$(git rev-parse HEAD)
    cd $WORKSPACE

    echo "DATE_TIME="${DATE_TIME}  >> job.properties
    echo "BUILD_VERSION="${BUILD_VERSION} >> job.properties
    echo "COMMIT_HASH="${COMMIT_HASH} >> job.properties
else
    export BUILD_VERSION=${BUILD_VERSION_IN}
    echo "BUILD_VERSION="${BUILD_VERSION_IN} >> job.properties
fi

# Name tar balls
# export DEPLOY_TAR="cuke_deploy-${BUILD_VERSION}.tar.gz"
# echo "DEPLOY_TAR="${DEPLOY_TAR} >> job.properties

echo "TARGET_SERVER_IP="${TARGET_SERVER_IP} >> job.properties
echo "CHEF_HELPER_SERVER_IP"=${CHEF_HELPER_SERVER_IP} >> job.properties

################## Environment Variable Setup (End) ##################

################## Get .pem files for Chef helper (Start) ##################

echo -e "Copying the pem key file in place to communicate with the Chef helper server..."
# yes | cp -f /home/jenkins/.secure/bvt/cuke_test.pem $WORKSPACE/sla_ui/cucumber/chef_helper/.chef

ssh -o "StrictHostKeyChecking no" root@${CHEF_HELPER_SERVER_IP} <<EOF
echo -e "SSH Shell currently running on \$(hostname)."
docker cp chef_server_test:/etc/chef/cuke_test.pem /root
[[ \$? -ne 0 ]] && echo -e "Unable to obtain the cuke_test.pem file from the chef_server_test container!" && exit 1
echo -e "Dummy echo to overwrite the exit code of 1 from the condition check in previous command."
EOF

scp -o "StrictHostKeyChecking no" root@${CHEF_HELPER_SERVER_IP}:/root/cuke_test.pem $WORKSPACE/sla_ui/cucumber/chef_helper/.chef
################## Get .pem files for Chef helper (End) ##################

################## Get private key for Chef helper to bootstrap endpoint servers (Start) ##################

# Private key of the cucumber host server is selected
echo -e "Copying the private key for the Chef helper to bootstrap endpoint servers..."
scp -o "StrictHostKeyChecking no" root@${TARGET_SERVER_IP}:/root/.ssh/id_rsa $WORKSPACE/sla_ui/cucumber

################## Get private key for Chef helper to bootstrap endpoint servers (End) ##################


################## Build Images (Start) ##################
cd $WORKSPACE
# Set dir to store build artifacts
export ARTIFACT_DIR=$BUILD_VERSION"/cucumber"
rm -rf $ARTIFACT_DIR
mkdir -p $ARTIFACT_DIR

echo -e "Building cucumber docker image..."
cd $WORKSPACE/sla_ui/cucumber

# Build and push base cucumber image
# docker login -u $DTR_USER -p $DTR_PASS $DTR_HOST
# docker build -t "ui-cucumber-base" ./
# docker tag ui-cucumber-base $DTR_HOST/$DTR_ORG/ui-cucumber-base
# docker login -u $DTR_USER -p $DTR_PASS $DTR_HOST
# docker push $DTR_HOST/$DTR_ORG/ui-cucumber-base
# docker logout $DTR_HOST

# Build and push executional cucumber image
docker login -u $DTR_USER -p $DTR_PASS $DTR_HOST
docker build -t $DTR_HOST/$DTR_ORG/ui-cucumber:$BUILD_VERSION -f Dockerfile.exec --build-arg APP_BUILD=$BUILD_VERSION --build-arg TEST_PHASE=bvt ./
docker login -u $DTR_USER -p $DTR_PASS $DTR_HOST
docker push $DTR_HOST/$DTR_ORG/ui-cucumber:$BUILD_VERSION
docker logout $DTR_HOST

# Save image as tar balls for deployment
# docker save -o $ARTIFACT_DIR"/ui_cuke-"${BUILD_VERSION}".tar" 'cucumber' 
# gzip $ARTIFACT_DIR"/ui_cuke-"${BUILD_VERSION}".tar"

# Package cucumber source code
# echo -e "Packaging Cucumber source scripts..."
# pwd
# tar -zcvf ./$ARTIFACT_DIR"/ui-cuke-"${BUILD_VERSION}".tar.gz" --ignore-failed-read --exclude='*\.git*' ./sla_ui/cucumber/
################## Build Image (End) ##################

################## Deploy via SSH (Start) ##################

export RELEASE=$BUILD_VERSION

ssh -o "StrictHostKeyChecking no" root@${TARGET_SERVER_IP} <<EOF
echo -e "SSH Shell currently running on \$(hostname)."

# Pull docker images
echo -e "Pulling new $RELEASE ui-cucumber image from DTR..."
docker login -u $DTR_USER -p $DTR_PASS $DTR_HOST
docker pull $DTR_HOST/$DTR_ORG/ui-cucumber:$RELEASE

# Stop and remove running cucumber container
echo -e "Removing old running ui-cucumber container..."
docker rm -f ui-cucumber 

# Create data volumes if not existing
docker volume ls | grep '\bsla-test-auto-data\b' || docker volume create sla-test-auto-data
docker volume ls | grep '\bsla-test-auto-log\b' || docker volume create sla-test-auto-log

# Re-create and start up
echo "Starting new cucumber container..."
docker run --name ui-cucumber \
-v sla-test-auto-data:/home/cobalt/ccssd-test \
-v sla-test-auto-log:/home/cobalt/cuke_report_logs \
-v /root/.secure:/home/cobalt/cucumber/.secure \
-v /root/.secure/endpoint.list:/home/cobalt/cucumber/chef_helper/endpoint.list \
--env CHEF_HOSTNAME=$CHEF_HELPER_SERVER_HOSTNAME -d -P -p 9080:80 $DTR_HOST/$DTR_ORG/ui-cucumber:$RELEASE

# Useful command to read docker log
echo -e "To view cucumber stdout log        -  docker logs --tail=all ui-cucumber"
EOF
################## Deploy via SSH (End) ##################