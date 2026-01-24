class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  include SearchableTextColumn
  include Sortable
end
