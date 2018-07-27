# Main page after log in
class MainPage
  include PageObject
  include DataMagic
  include FigNewton
  include UIHelper

  # menu
  link(:ssd, :text => /Self Service Delivery/)
  link(:admin, :text => /Admin/)
  link(:ssd_admin, :text => /SSD/)

  # menu items
  link(:server_page, href: '#/ssd/servers')
  link(:request_page, href: '#/ssd/requests')
  link(:app_config_page, href: '#/automation-provider-proxy-instances')
  
  link(:continuous_compliance, id: 'continuous_compliance')
  link(:cc_my_task_menu, id: 'nav_cc_tasks')
  link(:cc_my_request_menu, id: 'nav_cc_requests')
  link(:cc_manage_compliance_mode_menu, id: 'nav_cc_ManageComplianceMode')
  table(:cc_my_request_table, id: 'cc-my-request-table')
  table(:cc_my_task_table, id: 'serverDataList')
  button(:cc_my_task_submit_btn, class: 'request-submit-btn')
    
  select_list(:cc_search_options, id: 'searchOptions')
  text_field(:cc_search_input_box, id: 'searchBundle')
  button(:cc_apply_search_btn, id: 'applySearch')
  select_list(:server_page_size, id: 'serverPageSizeSelect')

  table(:filtered_table, id: 'cc-environment-summary-table')
  label(:approval_decision, :for => 'requestLevelDecision')
  text_area(:reject_reason, :id => 'rejection_comments')

  def initialize_page
    # gets called at end of page_object initialize
  end

  def open_ssd_work_pane
    begin
      ssd_element.image_element(class: 'show-nav-content').when_present(5)
      ssd
    rescue Watir::Wait::TimeoutError => error
      raise error, 'The SSD work pane is either not visible or already open.'
    end
  end

  def close_ssd_work_pane
    begin
      ssd_element.image_element(class: 'hide-nav-content').when_present(5)
      ssd
    rescue Watir::Wait::TimeoutError => error
      raise error, 'The SSD work pane is either not visible or already closed.'
    end
  end

  def open_admin_work_pane
    begin
      admin_element.image_element(class: 'show-nav-content').when_present(5)
      admin
    rescue Watir::Wait::TimeoutError => error
      raise error, 'The admin work pane is either not visible or already open.'
    end
  end

  def close_admin_work_pane
    begin
      admin_element.image_element(class: 'hide-nav-content').when_present(5)
      admin
    rescue Watir::Wait::TimeoutError => error
      raise error, 'The admin work pane is either not visible or already closed.'
    end
  end

  def open_ssd_admin_work_pane
    begin
      ssd_admin_element.image_element(class: 'show-nav-content').when_present(5)
      ssd_admin
    rescue Watir::Wait::TimeoutError => error
      raise error, 'The SSD admin work pane is either not visible or already open.'
    end
  end

  def close_ssd_admin_work_pane
    begin
      ssd_admin_element.image_element(class: 'hide-nav-content').when_present(5)
      ssd_admin
    rescue Watir::Wait::TimeoutError => error
      raise error, 'The SSD admin work pane is either not visible or already closed.'
    end
  end
  
  def cc_click_my_task_menu
    begin
      sleep 1
      unless self.cc_my_task_menu_element.visible?
        self.continuous_compliance_element.when_present.click
        wait_for_spinner
      end
      sleep 1
      self.cc_my_task_menu_element.when_present.click
      Watir::Wait.until(20, "Spinner is not visible. Waiting...") do
        @browser.div(id: 'opaqueOverlay').present?
      end
      wait_for_spinner
    rescue Watir::Wait::TimeoutError => error
      raise error, 'My Task Menu Not Found'
    end
  end
    
  def cc_click_my_request_menu
    begin
      sleep 1
      unless self.cc_my_request_menu_element.visible?
        self.continuous_compliance_element.when_present.click
        wait_for_spinner
      end
      sleep 1
      self.cc_my_request_menu_element.when_present.click
      wait_for_spinner
    rescue Watir::Wait::TimeoutError => error
      raise error, 'My Request Menu Not Found'
    end
  end

  def cc_server_page_size_select(page_size)
    begin
      correct_info = false
      
      pagesize = self.server_page_size

      if (pagesize == page_size)
        correct_info = true
      end
      
      correct_info      
    rescue Watir::Wait::TimeoutError => error
       raise error, 'Unable to get the Server Page Size'
    end
  end

  def cc_view_filter_table_by_release(env_release)
    begin
      correct_info = false
      
      trs = self.filtered_table_element.when_present.tbody.trs
      trs.each do | tr|
        if (tr[2].text == env_release) 
          correct_info = true
          break
        end
      end
      correct_info      
    rescue Watir::Wait::TimeoutError => error
       raise error, 'Unable to filter data by Environment Release'
    end
  end

  def cc_view_filter_table(env_filter)
    begin
      correct_info = false
      
      trs = self.filtered_table_element.when_present.tbody.trs
      trs.each do | tr|
        if (tr[1].text == env_filter) 
          correct_info = true
          break
        end
      end
      correct_info      
    rescue Watir::Wait::TimeoutError => error
       raise error, 'Unable to filter data by Environment Name'
    end
  end
  
  def cc_view_my_request_status(bundle_id, status, action)
    begin
      correct_info = false
      Watir::Wait.until { self.cc_search_options_element.enabled?}
      self.cc_search_options_element.when_present
      self.cc_search_options_element.select_value("bundleId") 
              
      Watir::Wait.until { self.cc_search_input_box_element.enabled?}
      self.cc_search_input_box = bundle_id
     
      self.cc_apply_search_btn_element.when_present.click
      wait_for_spinner
      trs = self.cc_my_request_table_element.when_present.tbody.trs
      trs.each do | tr|
        if ((tr[1].text == bundle_id) && (tr[3].text == action) && ((tr[4].text == "Execution Successful") || (tr[4].text == "Approved") || (tr[4].text == "Waiting for Approval")))
          correct_info = true
          break
        end
      end
      correct_info      
    rescue Watir::Wait::TimeoutError => error
       raise error, 'Request details on My Request Menu'
    end
  end
    
  def cc_view_my_task_status(bundle_id, status, action)
    begin
      correct_info = false
      Watir::Wait.until { self.cc_search_options_element.exists?}
      self.cc_search_options_element.when_present
      self.cc_search_options_element.select_value("bundleId")
        
      Watir::Wait.until { self.cc_search_input_box_element.enabled?}
      self.cc_search_input_box = bundle_id

      self.cc_apply_search_btn_element.when_present.click
      wait_for_spinner
      trs = self.cc_my_task_table_element.when_present.tbody.trs
      trs.each do | tr|
        if ((tr[3].text == bundle_id) && (tr[2].text == action) && ((tr[4].text == "Execution Successful") || (tr[4].text == "Approved") || (tr[4].text == "Rejected") ||(tr[4].text == "Waiting for Approval")))
          correct_info = true
          break          
        end
      end
      correct_info      
    rescue Watir::Wait::TimeoutError => error
      raise error, 'Request details on My Task Menu'
    end
  end
    
  def cc_click_my_task_request(bundle_id, action)
    begin
      trs = self.cc_my_task_table_element.when_present.tbody.trs
      trs.each do | tr|
        if (tr[3].text == bundle_id)
          tr[0].a.click
          wait_for_spinner
          break            
        end
      end
    rescue Watir::Wait::TimeoutError => error
      raise error, 'Open my task approval page'
    end
  end

  def cc_click_multiple_my_task_request(bundle_id, action)
    begin
      trs = self.cc_my_task_table_element.when_present.tbody.trs
      trs.each do | tr|
        if ((tr[3].text == bundle_id) && (tr[2].text == action))
          tr[0].a.click
          wait_for_spinner
          break            
        end
      end
    rescue Watir::Wait::TimeoutError => error
      raise error, 'Cannot Open my task approval page to approve multiple requests'
    end
  end
  

  def cc_reject_my_task_request
    begin
   
      self.reject_reason = "Test Reject Approval"
      
      Watir::Wait.until { self.approval_decision_element.visible?}
      self.approval_decision_element.click

      Watir::Wait.until { self.cc_my_task_submit_btn_element.visible?}
      self.cc_my_task_submit_btn_element.when_present(5).click
      wait_for_spinner                 
    rescue Watir::Wait::TimeoutError => error
      raise error, 'Reject Task'
    end
  end
    
  def cc_approve_my_task_request
    begin
      self.cc_my_task_submit_btn_element.when_present.click
      wait_for_spinner                 
    rescue Watir::Wait::TimeoutError => error
      raise error, 'Approve or Reject task'
    end
  end
    
  def cc_click_manage_compliance_mode_menu
    begin
      unless self.cc_manage_compliance_mode_menu_element.visible?
        self.continuous_compliance_element.when_present.click
      end
      wait_for_spinner  
      self.cc_manage_compliance_mode_menu_element.when_present.click
      wait_for_spinner
    rescue Watir::Wait::TimeoutError => error
      raise error, 'Manage Compliance Mode Menu Not Found'
    end
  end
end