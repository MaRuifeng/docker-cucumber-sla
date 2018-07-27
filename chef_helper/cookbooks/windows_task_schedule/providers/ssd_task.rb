#
# Author:: Ruifeng Ma (<ruifengm@sg.ibm.com>)
# Date:: 2017-Mar-01
# Cookbook Name:: windows_task_schedule
# Provider:: ssd_task
#
# Copyright (c) 2016 IBM, All Rights Reserved.

#####################################################
# This provider assists cucumber test automation of SSD for Windows Task Scheduling feature
# 1) Retrieve all tasks created by the automated test (listed under the SSDtasks folder)
# 2) Delete all of them
# 
# Tested Windows version: 2008, 2012
# Method: schtasks
#####################################################

use_inline_resources if defined?(use_inline_resources)

require 'chef/mixin/shell_out'
require 'rexml/document'
include Chef::Mixin::ShellOut

action :delete_all_ssd_tasks do
  task_list = load_all_ssd_task_list
  if task_list.respond_to?(:each)
    task_list.each do |task|
      Chef::Log.info "Deleting task #{task[:TaskName]}"
      # always need to force deletion
      run_schtasks 'DELETE', task[:TaskName], 'F' => ''
      new_resource.updated_by_last_action true
      Chef::Log.info "Task #{task[:TaskName]} deleted."
    end
  else
    Chef::Log.info "No SSD tasks found."
  end
end

# Note that this action is not self-sustaining
# The SSDtasks\ folder should not contain the intend-to-create entry before invoking this action
# Error validation checks on the input data are also excluded
action :create_ssd_task do
  options = {}
  options['F'] = '' if @new_resource.force
  options['SC'] = schedule
  options['MO'] = @new_resource.frequency_modifier if frequency_modifier_allowed
  options['I']  = @new_resource.idle_time unless @new_resource.idle_time.nil?
  options['SD'] = @new_resource.start_day unless @new_resource.start_day.nil?
  options['ST'] = @new_resource.start_time unless @new_resource.start_time.nil?
  options['TR'] = @new_resource.command
  options['RU'] = @new_resource.user
  options['RP'] = @new_resource.password unless @new_resource.password.nil?
  options['RL'] = 'HIGHEST' if @new_resource.run_level == :highest
  options['IT'] = '' if @new_resource.interactive_enabled
  options['D'] = @new_resource.day if @new_resource.day
  options['M'] = @new_resource.months unless @new_resource.months.nil?

  run_schtasks 'CREATE', @new_resource.task_name, options
  set_cwd(new_resource.cwd) if new_resource.cwd
  new_resource.updated_by_last_action true
  Chef::Log.info "#{@new_resource} task created."
end

private

def load_all_ssd_task_list 
  Chef::Log.info 'Loading all existing tasks under folder \\SSDtasks...'
  task_array = Array.new
  # we use shell_out here instead of shell_out! because a failure implies that no such tasks exist
  output = shell_out("schtasks /Query /FO LIST /V /TN SSDtasks\\").stdout
  if output.empty?
    return false
  else
    output.split(/\r\n\r\n/).map do |block| # split by 2 newlines
      task = {}
      block.split("\n").map! do |line| # split by newline
        line.split(':', 2).map!(&:strip)
      end.each do |field|
        if field.is_a?(Array) && field[0].respond_to?(:to_sym)
          task[field[0].gsub(/\s+/, '').to_sym] = field[1]
        end
      end
      Chef::Log.info "Found task #{task[:TaskName]}"
      task_array.push(task)
    end
  end
  Chef::Log.info 'All SSD tasks retrieved.'
  task_array
end

def run_schtasks(task_action, task_name, options = {})
  cmd = "schtasks /#{task_action} /TN \"#{task_name}\" "
  options.keys.each do |option|
    cmd += "/#{option} "
    cmd += "\"#{options[option]}\" " unless options[option] == ''
  end
  Chef::Log.debug('Running: ')
  Chef::Log.debug("    #{cmd}")
  shell_out!(cmd, returns: [0])
end

def schedule
  case @new_resource.frequency
    when :on_logon
      'ONLOGON'
    when :on_idle
      'ONIDLE'
    else
      @new_resource.frequency
  end
end

def frequency_modifier_allowed
  case @new_resource.frequency
    when :minute, :hourly, :daily, :weekly
      true
    when :monthly
      @new_resource.months.nil? || %w(FIRST SECOND THIRD FOURTH LAST LASTDAY).include?(@new_resource.frequency_modifier)
    else
      false
  end
end

def set_cwd(folder)
  Chef::Log.debug 'looking for existing tasks'

  # we use shell_out here instead of shell_out! because a failure implies that the task does not exist
  xml_cmd = shell_out("schtasks /Query /TN \"#{@new_resource.task_name}\" /XML")

  return if xml_cmd.exitstatus != 0

  doc = REXML::Document.new(xml_cmd.stdout)

  Chef::Log.debug 'Removing former CWD if any'
  doc.root.elements.delete('Actions/Exec/WorkingDirectory')

  unless folder.nil?
    Chef::Log.debug 'Setting CWD as #folder'
    cwd_element = REXML::Element.new('WorkingDirectory')
    cwd_element.add_text(folder)
    exec_element = doc.root.elements['Actions/Exec']
    exec_element.add_element(cwd_element)
  end

  temp_task_file = ::File.join(ENV['TEMP'], 'windows_task.xml')
  begin
    ::File.open(temp_task_file, 'w:UTF-16LE') do |f|
      doc.write(f)
    end

    options = {}
    options['RU'] = @new_resource.user if @new_resource.user
    options['RP'] = @new_resource.password if @new_resource.password
    options['IT'] = '' if @new_resource.interactive_enabled
    options['XML'] = temp_task_file

    run_schtasks('DELETE', @new_resource.task_name, 'F' => '')
    run_schtasks('CREATE', @new_resource.task_name, options)
  ensure
    ::File.delete(temp_task_file)
  end
end

