#
# Cookbook Name:: windows_task_schedule
# Recipe:: create_default_ssd_tasks
#
# Licensed Materials - Property of IBM
# Copyright (c) 2016 IBM, All Rights Reserved.
# Copyright (c) 2016 The Authors, All Rights Reserved.

#########################################################
# Author: Ruifeng Ma
# Date: 2017-Mar-07
# Purpose: Create all default Windows tasks to be used in test automation of SSD
#########################################################

# search through the data bags
search(:win_task, '*:*').each do |task|
  windows_task_schedule_ssd_task task['task_name'] do

    user task['user']
    password task['password']
    task_name "\\SSDtasks\\#{task[:task_name]}"
    cwd task[:cwd]
    command task[:command]
    run_level task[:run_level].intern
    frequency task[:frequency].intern
    frequency_modifier task[:frequency_modifier]
    idle_time task[:idle_time]
    start_day task[:start_day]
    start_time task[:start_time]
    day task[:day]
    months task[:months]

    action :create_ssd_task
end

end