#
# Cookbook Name:: windows_task_schedule
# Recipe:: delete_all_ssd_tasks
#
# Licensed Materials - Property of IBM
# Copyright (c) 2016 IBM, All Rights Reserved.
# Copyright (c) 2016 The Authors, All Rights Reserved.

#########################################################
# Author: Ruifeng Ma
# Date: 2017-Mar-01
# Purpose: Delete all windows tasks created during automated test for SSD
#########################################################

windows_task_schedule_ssd_task 'delete_all_ssd_tasks' do
  action :delete_all_ssd_tasks
end