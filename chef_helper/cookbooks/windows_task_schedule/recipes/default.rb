###############################################################
#
# Cookbook Name:: windows_task_schedule
#
# Recipe:: default
#
# Licensed Materials-Property of IBM
# (C) Copyright IBM Corp. 2015
#
# Note to U.S. Government Users -- Restrictive Rights -- Use,
# Duplication or Disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#
##############################################################


#
# Delete all SSD tasks -- which is the default action for this cookbook
#
include_recipe 'windows_task_schedule::create_default_ssd_tasks'