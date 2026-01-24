# frozen_string_literal: true

class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, null: false, default: "string"
      t.string :group, default: "general"
      t.text :description

      t.timestamps
    end

    add_index :settings, :key, unique: true
    add_index :settings, :group
  end
end
