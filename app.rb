require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'dotenv'
require 'resque'
require 'resque/server'
require 'resque/failure/slack'
require 'activerecord-postgis-adapter'
require 'rgeo/geo_json'

Resque.redis = Redis.new

# Resque::Failure::Slack.configure do |config|
#   config.channel = 'C03CFMGKM'  # required
#   config.token = ENV['SLACK_TOKEN'] || 'incorrect'   # required
#   config.level = :minimal # optional
# end

# Resque::Failure.backend = Resque::Failure::Slack

Dotenv.load

db = ENV['SINATRA_DB'] || 'postgis://Matt@localhost/craigslistscrape'
set :database, db


##########
# Models #
##########

class Source < ActiveRecord::Base
  has_many :listings

  def crawl 
    klass = Object.const_get(self.script)
    klass.crawl
  end
end

class Survey < ActiveRecord::Base
  has_many :listings
end

class Listing < ActiveRecord::Base
  belongs_to :source
  belongs_to :survey
end

class Municipality < ActiveRecord::Base
end
###########
# Helpers #
###########

class Crawl
  def initialize
    self.load_demux
    self.crawl_all
  end

  def crawl_all
    # dynamically trigger crawlers from db, found in ./demux. New Sources must be entered into the database.
    sources = Source.all
    sources.each do |r|
      klass = Object.const_get(r.script)
      klass.crawl
    end
  end

  def load_demux
    # Load in crawler scripts. Loads in case the files are edited. 
    Dir[File.dirname(__FILE__) + '/mux/*.rb'].each {|file| load file }
  end
end

module Job
  @queue = :default

  def self.perform
    Crawl.new
  end
end

##########
# Routes #
##########

get '/' do
  "This app is our continuous rental listing crawler. More information, including command line configuration, will go here. To manually crawl, visit /jobs/new"
end

get '/jobs/new' do
  erb :form
end

post '/jobs/new' do
  Resque.enqueue(Job)
end

# Surveys
get '/surveys.json' do
  Survey.all.to_json
end

get '/surveys/:id/listings/new' do
  Survey.find(:first, params[:id])
end

post '/surveys/:id/listings/new' do
  Survey.find(:first, params[:id]).listings.create(params)
end

post '/surveys/new' do
  survey = Survey.create
  "Go to surveys/{survey.id}/listings/new"
end

get '/sources' do
  Source.all.to_json
end

get '/resque_admin' do
  mount Resque::Server.new, :at => "/resque"
end

