require 'sinatra'
require 'sinatra/activerecord'
require 'json'
require 'activerecord-postgis-adapter'
require 'sentry-raven'
require 'mailgun'
require 'dotenv/load'


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
    @results = []

    puts 'Running crawler'
    load_mux
    crawl_all
    send_mail
  end

  def load_mux
    Dir[File.dirname(__FILE__) + '/mux/*.rb'].each { |file| load file }
  end

  def crawl_all
    Source.all.each do |source|
      puts "***SCRAPING #{source.title} ***"
      klass = Object.const_get(source.script)
      quantity = klass.crawl

      @results << { "title" => source.title, "quantity" => quantity }
    end
  end

  def send_mail
    mail_file_path = File.join(File.dirname(__FILE__), 'config', 'mail.json')

    if File.exist?(mail_file_path)
      mail_info = JSON.parse(File.read(mail_file_path))
      sender = mail_info['sender']
      recipients = mail_info['recipients']

      if recipients.size > 0
        mailer = Mailgun::Client.new(ENV['MAILGUN_API_KEY'])
        batch = Mailgun::BatchMessage.new(mailer, ENV['MAILGUN_DOMAIN'])

        batch.from(sender["email"], sender["name"])
        batch.subject("Scrape Results from the Rental Listings Aggregator")

        message = @results.map { |result| "#{result['title']} provided #{result['quantity']} listings" }
        message = message.join("\n")

        batch.body_text(message)

        recipients.each do |recipient|
          batch.add_recipient(:to, recipient["email"], recipient["name"])
        end

        begin
          puts 'Sending emails'

          batch.finalize
        rescue Exception => e
          Raven.capture_exception(e)

          puts 'Could not send emails'
        end
      else
        puts 'No email recipients defined'
      end
    else
      puts "No #{mail_file} file in project root"
    end
  end
end

module Job
  @queue = :default

  def self.perform
    Crawl.new
  end
end
