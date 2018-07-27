class SplashPage

  # Deprecated in sprint 15.2, to be replaced with WebFrontEnd dashboard page - Ruifeng Ma, May-09-2017


  # include PageObject
  # include DataMagic
  # include FigNewton
  #
  # def initialize_page
  #   #gets called at end of page_object initialize
  # end
  #
  # FigNewton.load(ENV['FIG_NEWTON_FILE'])
  # DataMagic.yml_directory = 'config/data' # the gem actually defaults to using this directory
  #
  # page_url("#{FigNewton.base_url}")
  #
  # link(:start, class: 'ibm-btn-pri')
  #
  # def get_started
  #   self.start_element.when_present
  #   sleep 2 # Wait for some NorthStar API calls to load the contents properly, otherwise link click won't work
  #   $log.debug("On element #{self.start_element.to_s} with text #{self.start_element.text}")
  #   start
  # end
end
