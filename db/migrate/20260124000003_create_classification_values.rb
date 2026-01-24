# frozen_string_literal: true

class CreateClassificationValues < ActiveRecord::Migration[8.0]
  def change
    create_table :classification_values do |t|
      t.references :classification, null: false, foreign_key: true
      t.string :value, null: false
      t.text :description
      t.integer :sort_order, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :classification_values, [:classification_id, :value], unique: true
  end
end
