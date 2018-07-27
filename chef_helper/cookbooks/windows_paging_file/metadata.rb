# Cookbook Name:: windows_paging_file
# Licensed Materials - Property of IBM
# Copyright (c) 2016 IBM, All Rights Reserved.
# Cookbook dependency: windows (https://github.com/chef-cookbooks/windows)

name 'windows_paging_file'
maintainer 'IBM'
maintainer_email 'ruifengm@sg.ibm.com'
license 'all_rights'
description 'Installs/Configures windows_paging_file'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.1.0'

# windows cookbook dependency
depends 'windows'
