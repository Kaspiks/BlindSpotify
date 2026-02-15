# frozen_string_literal: true

module ClassificationValues
  class QrStatus < ClassificationValue
    default_scope { by_classification_code('qr_statuses') }
  end
end

# == Schema Information
#
# Table name: classification_values
#
#  id                :bigint           not null, primary key
#  active            :boolean          default(TRUE), not null
#  description       :text
#  sort_order        :integer          default(0), not null
#  value             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  classification_id :bigint           not null
#
# Indexes
#
#  index_classification_values_on_classification_id            (classification_id)
#  index_classification_values_on_classification_id_and_value  (classification_id,value) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (classification_id => classifications.id)
#
