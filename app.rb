require 'rubygems'
require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'dotenv'
require 'resque'
require 'resque/server'
require 'resque/failure/slack'
require 'activerecord-postgis-adapter'
# require 'rgeo/geo_json'

Resque.redis = Redis.new

# Resque::Failure::Slack.configure do |config|
#   config.channel = 'C03CFMGKM'  # required
#   config.token = ENV['SLACK_TOKEN'] || 'incorrect'   # required
#   config.level = :minimal # optional
# end

# Resque::Failure.backend = Resque::Failure::Slack

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
