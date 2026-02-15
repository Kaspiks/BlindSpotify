# frozen_string_literal: true

class Room < ApplicationRecord
  belongs_to :host, class_name: 'User', optional: true
  belongs_to :current_track, class_name: 'Track', optional: true
  has_many :room_participants, dependent: :destroy

  validates :code, presence: true, uniqueness: true
  validates :status, inclusion: { in: ->(_) { room_status_values } }
  validates :revealed, inclusion: { in: [true, false] }

  before_validation :generate_code, on: :create
  after_create :set_initial_state_json

  scope :active, -> { where(status: 'active') }

  # Pattern B: session blob for RoomSessionChannel. Server is authoritative.
  def state_snapshot
    Rooms::SessionStateBuilder.call(room: self)
  end

  def sync_state_json!(event_type:, by: nil)
    snapshot = state_snapshot
    self.state_json = snapshot.merge(
      "last_event" => {
        "id" => next_event_id,
        "at" => Time.current.to_i,
        "type" => event_type.to_s,
        "by" => by
      }.compact
    )
    save!
    state_json
  end

  def next_event_id
    (state_json || {}).dig("last_event", "id").to_i + 1
  end

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

  def set_initial_state_json
    snapshot = state_snapshot
    snapshot["last_event"] = {
      "id" => 1,
      "at" => Time.current.to_i,
      "type" => "room_created",
      "by" => host_id.present? ? "p_#{host_id}" : nil
    }.compact
    update_column(:state_json, snapshot)
  end
end

# == Schema Information
#
# Table name: rooms
#
#  id               :bigint           not null, primary key
#  code             :string           not null
#  revealed         :boolean          default(FALSE), not null
#  state_json       :jsonb            not null
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
