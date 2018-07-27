class AppAddNewPage
  include PageObject
  include DataMagic
  include UIHelper

  def initialize_page
    # gets called at end of page_object initialize
  end

  select_list(:provider_type, :class => 'ibm-drf-dropdown') # remember to remove the sleep added before page loading once a more meaningful selector is added
  button(:save, :text => 'Save')
  button(:cancel, :text => 'Cancel')

  def select_provider_type(app_type)
    provider_type_element.when_present(5)
    self.provider_type = app_type
  end

  def add_hmc(app_info)
    label_element(text: /username/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:username]
    label_element(text: /fqdn/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:fqdn]
    label_element(text: /ip-address/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:ip_address]
    save
  end

  def add_vmware(app_info)
    label_element(text: /username/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:username]
    label_element(text: /password/).parent.span_element.text_field_element(class: 'ember-text-field').value = (0...9).map { ('a'..'z').to_a[rand(26)] }.join
    label_element(text: /server/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:server]
    label_element(text: /expected-pubkey-hash/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:expected_pubkey_hash]
    if app_info[:ssl] == 'true'
      label_element(text: /ssl/).parent.span_element.checkbox_element(class: 'ember-checkbox').set
    end
    label_element(text: /rev/).parent.span_element.text_field_element(class: 'ember-text-field').value = app_info[:rev]
    save
  end


end