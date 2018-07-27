class BPMProcessPortalPage
  include PageObject
  include DataMagic
  include FigNewton

  def initialize_page
    # gets called at end of page_object initialize
  end

  link(:work, id: 'processPortalWorkLink')

  def launch_work_tasks
    work
  end

  def open_task_by_id (task_id)
    max_wait = 600 # waiting for the task to become available
    if (task_id.nil? || task_id.empty?)
      raise "No BPM task instance number provided!"
    end
    search_box = @browser.div(class: "bpm-task-list-header-search").when_present
    item = nil
    cancel_box=@browser.div(class: "bpm-social-close-x")
    Watir::Wait.until(max_wait, "Task #{task_id} not available after searching for #{max_wait} seconds.") do
      if cancel_box.present?
        cancel_box.click
      end
      sleep 2
      search_box.input.to_subtype.set(task_id.to_i)
      search_box.input.to_subtype.send_keys :enter
      sleep 2 # search interval
      @browser.spans(class: "bpm-social-task-row-data-instance").each do |entry|
        if entry.text.match /#{task_id}/
          item = entry
        end
      end
      !item.nil?
    end
    item = item.parent until (item.class_name == "bpm-social-task-row" && item.attribute_value("role") == "listitem") # find clickable parent
    $log.info("Found task #{task_id} with name #{item.text}. Clicking to open it ...")
    item.link(css: 'a[role="button"][title="Click to work on the task"]').click
  end

end