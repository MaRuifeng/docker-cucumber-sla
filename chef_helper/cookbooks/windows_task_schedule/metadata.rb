###############################################################
#
# Cookbook Name::windows_task_schedule
#
# Licensed Materials-Property of IBM
# (C) Copyright IBM Corp. 2015
#
# Note to U.S. Government Users -- Restrictive Rights -- Use,
# Duplication or Disclosure restricted by GSA ADP Schedule
# Contract with IBM Corp.
#
##############################################################

name             'windows_task_schedule'
maintainer       'IBM Corporation'
maintainer_email 'ruifengm@sg.ibm.com'
license          'All rights reserved'
description      'Cucumber test automation helper recipe.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.1.0'

#
# We need the windows cookbook.  Make it a dependency
#
depends 'windows'
