# frozen_string_literal: true

class Room < ApplicationRecord
  belongs_to :host, class_name: 'User', optional: true
  belongs_to :current_track, class_name: 'Track', optional: true
  has_many :room_participants, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: ->(_) { room_status_values } }
  validates :revealed, inclusion: { in: [true, false] }

  before_validation :generate_code, on: :create

  scope :active, -> { where(status: 'active') }

  def self.room_status_values
    ClassificationValues::RoomStatus.ordered.pluck(:value)
  end

  def host?(user)
    return false if user.blank?
    host_id.present? && host_id == user.id
  end

  def active?
    status == 'active'
  end

  private

  def generate_code
    return if code.present?
    self.code = Rooms::CodeGenerationService.call
  end
end

# == Schema Information
#
# Table name: rooms
#
#  id               :bigint           not null, primary key
#  code             :string           not null
#  revealed         :boolean          default(FALSE), not null
#  status           :string           default("active"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  current_track_id :bigint
#  host_id          :bigint
#
# Indexes
#
#  index_rooms_on_code              (code) UNIQUE
#  index_rooms_on_current_track_id  (current_track_id)
#  index_rooms_on_host_id           (host_id)
#
# Foreign Keys
#
#  fk_rails_...  (current_track_id => tracks.id)
#  fk_rails_...  (host_id => users.id)
#
