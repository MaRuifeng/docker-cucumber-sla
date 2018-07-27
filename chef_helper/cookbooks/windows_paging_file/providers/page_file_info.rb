#
# Author:: Ruifeng Ma (<ruifengm@sg.ibm.com>)
# Cookbook Name:: windows_paging file
# Provider:: get_page_file_setting
#
# Copyright (c) 2016 IBM, All Rights Reserved.

#####################################################
# This provider gets the current paging file information from a Windows Node.
# Tested Windows version: 2008, 2012
# Method: WMIC
#####################################################

use_inline_resources if defined?(use_inline_resources)

include Chef::Mixin::ShellOut

action :get do
  pagefile = @new_resource.name
  unless page_file_auto_managed?
    get_inti_size pagefile
    get_max_size pagefile
  end 
  get_page_file_info
end

private

def get_page_file_info 
  Chef::Log.debug("Retrieving page file information through wmic commands.")
  cmd = shell_out("#{wmic} pagefile list full")
  # check_for_errors(cmd.stderr)
  Chef::Log.info("Page file info: \n#{cmd.stdout}")
  cmd.stdout
end

def page_file_auto_managed? 
  Chef::Log.debug("Retrieving environment variable AutomaticManagedPageFile.")
  cmd = shell_out("#{wmic} computersystem where name=\"%computername%\" get AutomaticManagedPageFile /format:list")
  Chef::Log.info("Page file automatically managed for all drives? \n#{cmd.stdout}")
  cmd.stderr.empty? && (cmd.stdout =~ /AutomaticManagedPagefile=TRUE/i)
end

def get_inti_size pagefile
  Chef::Log.debug("Retrieving page file initial size.")
  cmd = shell_out("#{wmic} pagefileset where name=\"#{win_friendly_path(pagefile)}\" get InitialSize")
  Chef::Log.info("Page file initial size: \n#{cmd.stdout}")
  cmd.stdout
end

def get_max_size pagefile
  Chef::Log.debug("Retrieving page file maximum size.")
  cmd = shell_out("#{wmic} pagefileset where name=\"#{win_friendly_path(pagefile)}\" get MaximumSize")
  Chef::Log.info("Page file maximum size: \n#{cmd.stdout}")
  cmd.stdout
end

def wmic
  @wmic ||= begin
    locate_sysnative_cmd('wmic.exe')
  end
end

# account for Window's wacky File System Redirector
# http://msdn.microsoft.com/en-us/library/aa384187(v=vs.85).aspx
# especially important for 32-bit processes (like Ruby) on a
# 64-bit instance of Windows.
def locate_sysnative_cmd(cmd)
  if ::File.exist?("#{ENV['WINDIR']}\\sysnative\\#{cmd}")
    "#{ENV['WINDIR']}\\sysnative\\#{cmd}"
  elsif ::File.exist?("#{ENV['WINDIR']}\\system32\\#{cmd}")
    "#{ENV['WINDIR']}\\system32\\#{cmd}"
  else
    cmd
  end
end

# returns windows friendly version of the provided path,
# ensures backslashes are used everywhere
def win_friendly_path(path)
  path.gsub(::File::SEPARATOR, '\\\\\\\\') if path
  # NOTE: regex("\\\\") is intepreted as regex("\\" [escaped backslash] followed by "\\" [escaped backslash])
  #                     is intepreted as regex(\\)
  #                     is interpreted as a regex that matches a single literal backslash. --- Ruifeng Ma, May-18-2016
end
