# frozen_string_literal: true

class AddQrCodeDigestToTracks < ActiveRecord::Migration[8.0]
  def change
    add_column :tracks, :qr_code_digest, :string
  end
end
