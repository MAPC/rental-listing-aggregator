class CreateSurveys < ActiveRecord::Migration
  def change
    create_table :surveys do |t|
      t.timestamps
    end
  end
end
