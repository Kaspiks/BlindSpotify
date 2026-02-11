# frozen_string_literal: true

class AddDeckTypeToPlaylists < ActiveRecord::Migration[8.0]
  def change
    change_table :playlists do |t|
      t.string :deck_type, comment: 'Deck type (e.g. static, dynamic)', default: 'static'
    end
  end
end
