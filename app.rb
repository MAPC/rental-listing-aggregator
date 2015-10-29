require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'dotenv'

Dotenv.load

db = ENV['SINATRA_DB'] || 'postgis://Matt@localhost/craigslistscrape'
set :database, db

# Models
class Listing < ActiveRecord::Base
  belongs_to :source
  belongs_to :survey

  default_scope { Listing.limit(10) }
end

class Survey < ActiveRecord::Base
  has_many :listings
end

class Source < ActiveRecord::Base
  has_many :listings
end


# Routes
get '/' do
  "Welcome. Start with surveys."
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
  # erb :form
end

# Sources
get '/sources' do
  Source.all.to_json
end

