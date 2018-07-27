require 'rubygems'

begin
  require 'cucumber'
  require 'cucumber/rake/task'
  # require 'parallel_tests/tasks'

  # Cucumber::Rake::Task.new(:features) do |t|
  # t.profile = 'default'
  # end
  #
  # task :default => :features
  # namespace :nfs do
  # Cucumber::Rake::Task.new(:export, "Exporting Test Script") do |t|
  # t.profile = "nothing"
  # t.cucumber_opts = "--tag @export"
  # end
  # Cucumber::Rake::Task.new(:mount, "Mounting Test Script") do |t|
  # t.profile = "nothing"
  # t.cucumber_opts = "--tag @mount"
  # end
  # Cucumber::Rake::Task.new(:unmount, "Unmounting Test Script") do |t|
  # t.profile = "nothing"
  # t.cucumber_opts = "--tag @unmount"
  # end
  # Cucumber::Rake::Task.new(:unexport, "Unexporting Test Script") do |t|
  # t.profile = "nothing"
  # t.cucumber_opts = "--tag @unexport"
  # end
  # desc "All NFS Test Scripts"
  # task :all => [:export, :mount, :unmount, :unexport]
  # end

  namespace :schedule_win_job do
    Cucumber::Rake::Task.new(:features) do |t|
      t.profile = 'dev'
      t.cucumber_opts = "--tag @schedule_job"
    end
    desc "All modify-scheduled-Windows-task scripts."
    task :all => [:features]
  end

  namespace :parallel_cukes do
    task :features do
      # cucumber_options = "-p dev_parallel -t @parallel_test -t @modify"
      # commands = ["bundle exec parallel_cucumber features/parallel_test/ -o '#{cucumber_options}'"]
      puts "Current directory: #{Dir.pwd}"
      commands = ["pkexec env DISPLAY=$DISPLAY XAUTHORITY=$XAUTHORITY #{Dir.pwd}/parallel_cukes.sh -d #{Dir.pwd}"] # Jenkins server
      # commands = ["pkexec env DISPLAY=:0 XAUTHORITY=/home/ruifeng/.Xauthority #{Dir.pwd}/parallel_cukes.sh -d #{Dir.pwd}"] # Jenkins server
      commands.each do |command|
        puts "Running command: #{command}"
        abort "Failed command: #{command}" unless system(command)
      end
      # sh "rake parallel:features[,,'#{cucumber_options}']"
    end
  end
rescue LoadError
  desc "Cucumber rake task not available"
  task :features do
    abort "Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin."
  end
end
