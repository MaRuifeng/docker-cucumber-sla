class AppDetailsPage
  include PageObject
  include DataMagic
  include UIHelper

  def initialize_page
    # gets called at end of page_object initialize
  end

  paragraphs(:app_details)  # no further identifying selectors provided by developer...anyway...cross fingers

  def get_app_details
    app_details = Hash.new
    self.app_details_elements.each do |p|
      if p.text.include?(':')
        key_value_pair = p.text.split(':', 2)
        app_details[key_value_pair[0].lstrip.rstrip.to_sym] = key_value_pair[1].lstrip.rstrip
      end
    end
    app_details
  end
end