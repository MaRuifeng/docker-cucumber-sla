class AppListPage
  include PageObject
  include DataMagic
  include UIHelper

  def initialize_page
    # gets called at end of page_object initialize
  end

  # table(:app_list, id: 'serverDataList') # remember to remove the sleep added before page loading
  table(:app_list, class: 'ibm-data-table')
  button(:add_new, text: /New/)

  def wait_for_page_to_load
    app_label_element.when_present(5)
  end

  def get_app_info_in_table(app_fqdn)
    app_info = Hash.new
    app_info[:app_type] = app_list_element[app_fqdn]['Automation Provider'].text
    app_info[:app_name] = app_list_element[app_fqdn]['Name'].text
    app_info
  end

  def get_all_app_names_in_table
    # app_list_element.column_values('Name')
    app_names = Array.new
    app_list_element.each do |row|
      app_names.push(row['Name'].text)
    end
    app_names
  end

  def show_app_details(app_fqdn)
    row = app_list_element[app_fqdn]
    row.button_element(text: /Show/).click
  end

  def delete_app(app_fqdn)
    row = app_list_element[app_fqdn]
    row.button_element(text: /Delete/).click
    confirm_dialog = div_element(id: 'ibm-overlaywidget-NS_OKCancelOverlay')
    confirm_dialog.button_element(id: 'NS_okCancelOKButton').when_present.click
  end

  def edit_app(app_fqdn)
    row = app_list_element[app_fqdn]
    row.button_element(text: /Edit/).click
  end

  def add_new_app
    add_new_element.when_present(5)
    add_new
  end

end