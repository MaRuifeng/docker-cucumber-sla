class BundleDetailsPage
  include PageObject
  include DataMagic
  include UIHelper

  def initialize_page
    # gets called at end of page_object initialize
  end

  paragraph(:bpm_process_id, text: /BPM Process ID/)

  def get_bpm_process_id
    bpm_process_id_element.when_present.span_element.when_present.text
    # sleep 5
    # @browser.p(text: /BPM Process ID/).span.text
  end
end