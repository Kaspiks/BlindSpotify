# frozen_string_literal: true

module ClassificationValues
  class QrStatus < ClassificationValue
    default_scope { by_classification_code('qr_statuses') }
  end
end
