# This module contains constant values used in this project

module Constants

  # Change request status
  DRAFT                    ||= 'Draft'
  PENDING_EXECUTION        ||= 'Pending Execution'
  PENDING_APPROVAL         ||= 'Pending Approval'
  PENDING_MODIFICATION     ||= 'Pending Modifications'
  EXECUTING                ||= 'Executing'
  COMPLETED                ||= 'Completed'
  FAILED                   ||= 'Failed'
  EXECUTION_FAILURE        ||= 'Execution Failed'
  EXECUTION_SUCCESS        ||= 'Executed Successfully'
  CANCELLED                ||= 'Cancelled'
  SUBMITTED                ||= 'Submitted'

  # Time out values
  MAX_EXECUTION_WAIT    ||= 900  # waiting for the change request to be executed
end
