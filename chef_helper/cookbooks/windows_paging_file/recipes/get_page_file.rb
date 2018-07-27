#
# Cookbook Name:: windows_paging_file
# Recipe:: get page file information
# Licensed Materials - Property of IBM
# Copyright (c) 2016 IBM, All Rights Reserved.
# Copyright (c) 2016 The Authors, All Rights Reserved.

#########################################################
# Author: Ruifeng Ma
# Date: 2016-May-18
# Purpose: Set the virtual memory (paging file) information of the Windows OS
#########################################################

windows_paging_file_page_file_info 'get_page_file' do
  name 'C:/pagefile.sys'
  action :get
end