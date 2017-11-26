require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'activerecord-postgis-adapter'
require 'sentry-raven'


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
    puts 'Running crawler'
    load_mux
    crawl_all
  end

  def load_mux
    Dir[File.dirname(__FILE__) + '/mux/*.rb'].each { |file| load file }
  end

  def crawl_all
    Source.all.each do |source|
      puts "***SCRAPING #{source.title} ***"
      klass = Object.const_get(source.script)
      klass.crawl
    end
  end

  def send_mail

  end
end

module Job
  @queue = :default

  def self.perform
    Crawl.new
  end
end
