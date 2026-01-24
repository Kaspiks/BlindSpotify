# frozen_string_literal: true

class CreatePermissions < ActiveRecord::Migration[8.0]
  def change
    create_table :permissions do |t|
      t.string :code, null: false
      t.text :description, null: false

      t.timestamps
    end

    add_index :permissions, :code, unique: true
  end
end
