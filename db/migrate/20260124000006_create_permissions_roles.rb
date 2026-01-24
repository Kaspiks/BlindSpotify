# frozen_string_literal: true

class CreatePermissionsRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :permissions_roles, id: false do |t|
      t.references :permission, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
    end

    add_index :permissions_roles, [:permission_id, :role_id], unique: true
  end
end
