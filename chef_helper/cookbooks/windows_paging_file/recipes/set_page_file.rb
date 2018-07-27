# Cookbook Name:: windows_paging_file
# Recipe:: set paging file with given parameters
# Licensed Materials - Property of IBM
# Copyright (c) 2016 IBM, All Rights Reserved.
# Cookbook dependency: windows (https://github.com/chef-cookbooks/windows)

#########################################################
# Author: Ruifeng Ma
# Date: 2016-May-13
# Purpose: Set the virtual memory (paging file) of the Windows OS
# Attributes: 
# 	name              >>            path to the customized paging file and must be "X:/pagefile.sys" where X is the drive name
#	initial_size      >>            initial page file size in MegaBytes; check Windows support document for acceptable value
#       maximum_size      >>            maximum page file size in MegaBytes; check Windows support document for acceptable value
# 	system_managed    >>            true/false
#       automatic_managed >>            true/false
# Note: the page file name must be pagefile.sys (case sensitive), otherwise a nasty error termed as 'Provider does not support put extensions' occurs. See http://blog.mpecsinc.ca/2011/09/wmic-pagefileset-create-error-provider.html
# 
# Windows paging file size management rules: 
#	1. Automatically managed for all drives
#	2. If not, the user has the authority with below setting options for a selected drive
#	    a. Set custom size (Initial and Maximum in MegaBytes)
#	    b. System managed
#	    c. No paging file
# 
# Chef system reboot resource: https://docs.chef.io/resource_reboot.html
#########################################################

windows_pagefile 'set_page_file' do
	name 'C:/pagefile.sys'
	initial_size 6888  # in MegaBytes
	maximum_size 10009 
	system_managed false
	automatic_managed true
	notifies :reboot_now, 'reboot[restart_node]', :immediately
  # action :set
end

reboot 'restart_node' do
  action :nothing
end

