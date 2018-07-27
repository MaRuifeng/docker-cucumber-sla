require 'rspec'
require 'page-object'
require 'require_all'
require 'data_magic'
require 'fig_newton'
require 'faker'
require 'time'
require 'active_support'
require 'active_support/core_ext'
require_relative 'constants'
require 'rest-client'

FigNewton.load(ENV['FIG_NEWTON_FILE'])
DataMagic.yml_directory = 'config/data' # the gem actually defaults to using this directory

require_rel 'pages'

World(PageObject::PageFactory)
World(UIHelper)

# Page object routes only come in handy when they can be re-used. No need to add route for every single flow!
PageObject::PageFactory.routes = {
  default: [[SplashPage, :get_started], [LoginPage, :login_as], [MainPage]]
}
