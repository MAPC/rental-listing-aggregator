class AddSurveyAndSourceAndListing < ActiveRecord::Migration
  def change
    add_reference :listings, :source, index: true
    add_reference :listings, :survey, index: true
  end
end
