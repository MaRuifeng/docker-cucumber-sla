class BPMApprovalPage
  include PageObject
  include DataMagic
  include FigNewton

  def initialize_page
    # gets called at end of page_object initialize
  end

  def process_change_request(action, resource_name)
    resource_name_regex = Regexp.new(resource_name.gsub("\\", "\\\\\\\\"), Regexp::IGNORECASE)
    # NOTE: regex("\\\\") is intepreted as regex("\\" [escaped backslash] followed by "\\" [escaped backslash])
    #                     is intepreted as regex(\\)
    #                     is interpreted as a regex that matches a single literal backslash. --- Ruifeng Ma, Apr-15-2016
    row = select_request_to_approve resource_name_regex
    #click the dropdown cell to change focus
    dropdown_cell = row.div(data_viewid: "Select1").when_present
    dropdown_cell.click
    select_item_from_dropdown row, "Select1", action
  end

  def submit_decision
    click_button 'submit'
  end

  private

  def coach
    @browser.div(class: "bpm-task-coach-container").iframe.when_present
  end

  def scroll_to_element(element)
    element.wd.location_once_scrolled_into_view
    element
  end

  def click_button tag_value
    tagged_button = coach.div(:data_sscm_button => tag_value).when_present
    # Note: Sometimes the button element itself is smaller than the tagged element, so it is safer to click the child button element.
    bpm_button = tagged_button.button
    # Sometimes the button click seems to happen too quickly.  Using 'focus' seems to make sure the click takes effect.
    Watir::Wait.until(180, "Button #{tag_value} is not focused after 180 seconds") do
      bpm_button.focus
      bpm_button.focused?
    end
    #scroll_to_element(bpm_button).when_present.click
    $log.debug("Clicking button: #{tag_value}")
    scroll_to_element(bpm_button).click
  end

  def select_request_to_approve(resource_name)
    pending_approval_table_section = coach.h2(text: 'Changes Requiring Approval').when_present.parent
    row = get_table_row_having_cell_value pending_approval_table_section, "Table1", "Text16", resource_name
    return row
  end

  def get_table_row_having_cell_value(node, table_name, cell_id, cell_value)
    table = node.div(data_viewid: table_name).when_present
    selector_cells = nil
    Watir::Wait.until(40, "No rows found in table #{table_name}.") do
      selector_cells = table.divs(data_viewid: cell_id)
      # selector_cells = table.divs(:class=>"dojoxGridRow")
      selector_cells.count > 0
    end
    row = nil
    begin
      selector_cells.each_with_index do |entry, index|
        if (cell_value.instance_of?(Regexp) && entry.span(class: "text").text =~ cell_value) || entry.span(class: "text").text == cell_value
          $log.debug("Table row containing #{cell_value} is found.")
          row = entry.parent.parent
          break
        end
      end

      # Continue on next page if not found
      if row == nil
        if table.div(id: /Paginator/).table(class: "dojoxGridPaginator").exists? # check for paginator bar of the table
          # Stop at the last page
          if table.div(title: "Last Page").class_name.include?("dojoxGridlastPageBtnDisable")
            $log.debug("Table row containing #{cell_value} is not found in table #{table_name}.")
            raise "#On last page already. #{cell_value} not found in table #{table_name}"
            break
          end
          $log.debug("Table row containing #{cell_value} is not found on current page. Start searching on next page...")
          table.div(title: "Next Page").click
        else # look for separate pagination section
          $log.debug("No table paginator bar found. Working on a separate pagination section...")
          current_page_num = coach.div(data_binding: "local.currentPageIndex", data_viewid: "Integer1").span.text.to_i
          total_page_num = coach.div(data_binding: "local.totalPageCount", data_viewid: "Integer2").span.text.to_i
          # Stop at the last page
          if current_page_num == total_page_num
            $log.debug("Table row containing #{cell_value} is not found in table #{table_name}.")
            raise "#On last page already. #{cell_value} not found in table #{table_name}"
            break
          end
          $log.debug("Table row containing #{cell_value} is not found on current page. Start searching on next page...")
          coach.div(data_viewid: "Button_with_FontAwesome2").link(class: "FAButton").click
          sleep(5) # wait for the table to reload data
        end
      end
    end until row != nil
    row
  end

  def select_item_from_dropdown node, dropdown_uid, item_text
    #find div with a role of "combobox" and grab the id
    #append _dropdown to the end of the id and use that to find the dropdown menu by id (wait until this is present before clicking on arrow)
    dropdown_root = node.div(data_viewid: dropdown_uid).when_present
    if item_text.empty?
      dropdown_root.input(class: "dijitInputInner").to_subtype.set(item_text)
      # fix the issue when empty input is not working when the textbox has preserved text - Ruifeng Ma
      dropdown_root.input(class: "dijitInputInner").to_subtype.send_keys :delete
    else
      dropdown_id = dropdown_root.div(css: 'div[role="combobox"]').id
      dropdown_menu_id = "#{dropdown_id}_dropdown"
      Watir::Wait.until do
        sleep(3)
        dropdown_root.input(class: "dijitArrowButtonInner").when_present.click
        begin
          menu = coach.div(class: "dijitComboBoxMenuPopup", id: dropdown_menu_id)
          menu.div(class: "dijitMenuItem").text == item_text
        rescue
          false
        else
          true
        end
      end
      coach.div(class: "dijitComboBoxMenuPopup", id: dropdown_menu_id).wait_until_present
      dropdown_menu = coach.div(class: "dijitComboBoxMenuPopup", id: dropdown_menu_id)
      scroll_to_element(dropdown_menu.div(class: "dijitMenuItem", text: item_text).when_present).click
    end
  end

end