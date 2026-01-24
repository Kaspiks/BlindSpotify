# frozen_string_literal: true

class AddSpotifyOauthToUsers < ActiveRecord::Migration[8.0]
  def change
    # Remove password-based auth fields (making them nullable for migration)
    change_column_null :users, :email, true
    change_column_default :users, :email, nil
    change_column_null :users, :encrypted_password, true
    change_column_default :users, :encrypted_password, nil

    # Add Spotify OAuth fields
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    add_column :users, :spotify_access_token, :text
    add_column :users, :spotify_refresh_token, :text
    add_column :users, :spotify_token_expires_at, :datetime
    add_column :users, :name, :string
    add_column :users, :image_url, :string
    add_column :users, :spotify_product, :string
    add_column :users, :spotify_country, :string

    # Add index for OAuth lookup
    add_index :users, [:provider, :uid], unique: true

    # Remove password reset fields (no longer needed)
    remove_index :users, :reset_password_token
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
  end
end
