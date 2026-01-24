# frozen_string_literal: true

class AddIsrcToTracks < ActiveRecord::Migration[8.0]
  def change
    change_table :tracks, bulk: true do |t|
      t.string :isrc, comment: 'ISRC information for the track'
    end
  end
end
