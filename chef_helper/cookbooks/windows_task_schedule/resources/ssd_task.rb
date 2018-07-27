#
# Author:: Ruifeng Ma (<ruifengm@sg.ibm.com>)
# Date:: 2017-Mar-01
# Cookbook Name:: windows_task_schedule
# Provider:: ssd_task
#
# Copyright (c) 2016 IBM, All Rights Reserved.

#####################################################
# This resource assists cucumber test automation of SSD for Windows Task Scheduling feature
# 1) Retrieve all tasks created by the automated test (listed under the SSDtasks folder)
# 2) Delete all of them
# 
# Tested Windows version: 2008, 2012
# Method: schtasks
#####################################################

actions :delete_all_ssd_tasks, :create_ssd_task

attribute :task_name, kind_of: String, name_attribute: true, regex: [/\A[^\/\:\*\?\<\>\|]+\z/]
attribute :command, kind_of: String
attribute :cwd, kind_of: String
attribute :user, kind_of: String, default: 'SYSTEM'
attribute :password, kind_of: String, default: nil
attribute :run_level, equal_to: [:highest, :limited], default: :limited
attribute :force, kind_of: [TrueClass, FalseClass], default: false
attribute :interactive_enabled, kind_of: [TrueClass, FalseClass], default: false
attribute :frequency_modifier, kind_of: [Integer, String], default: 1
attribute :frequency, equal_to: [:minute,
                                 :hourly,
                                 :daily,
                                 :weekly,
                                 :monthly,
                                 :once,
                                 :on_logon,
                                 :onstart,
                                 :on_idle], default: :hourly
attribute :start_day, kind_of: String, default: nil
attribute :start_time, kind_of: String, default: nil
attribute :day, kind_of: [String, Integer], default: nil
attribute :months, kind_of: String, default: nil
attribute :idle_time, kind_of: Integer, default: nil

default_action :delete_all_ssd_tasks

def initialize(name, run_context = nil)
  super
  @action = :create_ssd_task
end

