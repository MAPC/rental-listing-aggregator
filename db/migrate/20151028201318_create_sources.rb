class CreateSources < ActiveRecord::Migration
  def change
    create_table :sources do |t|
      t.string :title
      t.string :website
      t.string :script

      t.timestamps
    end
  end
end
