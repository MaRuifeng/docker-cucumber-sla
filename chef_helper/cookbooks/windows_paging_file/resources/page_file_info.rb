#
# Author:: Ruifeng Ma (<ruifengm@sg.ibm.com>)
# Cookbook Name:: windows_paging file
# Provider:: get_page_file_setting
#
# Copyright (c) 2016 IBM, All Rights Reserved.

#####################################################
# This custom resource gets the current paging file information from a Windows Node.
# Tested Windows version: 2008, 2012
# Method: WMIC
#####################################################

actions :get
attribute :name, kind_of: String, name_attribute: true
default_action :get
