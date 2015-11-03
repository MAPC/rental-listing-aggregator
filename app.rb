require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'dotenv'
require 'resque'
require 'activerecord-postgis-adapter'

Resque.redis = Redis.new

Dotenv.load

db = ENV['SINATRA_DB'] || 'postgis://Matt@localhost/craigslistscrape'
set :database, db


##########
# Models #
##########

class Source < ActiveRecord::Base
  has_many :listings
end

class Survey < ActiveRecord::Base
  has_many :listings
end

class Listing < ActiveRecord::Base
  belongs_to :source
  belongs_to :survey

  default_scope { Listing.limit(10) }
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
      Resque.enqueue(Job, r.script)
    end
  end

  def load_demux
    # Load in crawler scripts. Loads in case the files are edited. 
    Dir[File.dirname(__FILE__) + '/mux/*.rb'].each {|file| load file }
  end
end

module Job
  @queue = :default

  def self.perform(script)
    klass = Object.const_get(script)
    klass.crawl
  end
end

##########
# Routes #
##########

get '/' do
  "This app is our continuous rental listing crawler. More information, including command line configuration, will go here."
end

# Listings
get '/listings' do
  Listing.all.to_json
end

get '/listings/new' do
  erb :form
end

post '/listings/new' do
  "You said '#{params[:message]}'"
  erb :form
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

