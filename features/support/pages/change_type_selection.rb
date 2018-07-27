class ChangeTypeSelectionPage
  include PageObject
	include FigNewton
	
  def initialize_page
    # gets called at end of page_object initialize
  end

	select_list(:change_category, :id => "resourceCategory")
	select_list(:change_type, :id => "resourceType")
	
  def select_ssd_oracle_reporting_option change_type
		change_options = FigNewton.send(change_type).to_hash
		select_ssd_change_option change_options[:change_category], change_options[:change_type]
	end

  def select_ssd_change_option category, change_type
    select_ssd_change_category category
    select_ssd_change_type change_type
  end

  def select_ssd_change_category category
		change_category_element.select category
  end

  def select_ssd_change_type change_type
    change_type_element.select change_type
  end
end