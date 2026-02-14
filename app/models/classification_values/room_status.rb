# frozen_string_literal: true

module ClassificationValues
  class RoomStatus < ClassificationValue
    default_scope { by_classification_code('room_statuses') }
  end
end
