# frozen_string_literal: true

module ClassificationValues
  class ImportStatus < ClassificationValue
    default_scope { by_classification_code('import_statuses') }
  end
end
