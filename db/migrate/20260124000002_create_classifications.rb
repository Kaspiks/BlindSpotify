# frozen_string_literal: true

class CreateClassifications < ActiveRecord::Migration[8.0]
  def change
    create_table :classifications do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :classifications, :code, unique: true
    add_index :classifications, :name, unique: true
  end
end
