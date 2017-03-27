require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'activerecord-postgis-adapter'

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
  validates :location, :title, :uid, presence: true
end

###########
# Helpers #
###########

class Crawl
  def initialize
    print "Running crawler\n"
    load_demux
    crawl_all
  end

  def crawl_all
    # dynamically trigger crawlers from db, found in ./demux. New Sources must be entered into the database.
    sources = Source.all
    sources.each do |r|
      print '***SCRAPING ' + r.title + "***\n"
      klass = Object.const_get(r.script)
      klass.crawl
    end
  end

  def load_demux
    # Load in crawler scripts. Loads in case the files are edited. 
    Dir[File.dirname(__FILE__) + '/mux/*.rb'].each { |file| load file }
  end
end

module Job
  @queue = :default

  def self.perform
    Crawl.new
  end
end
