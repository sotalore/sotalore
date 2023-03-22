class ApplicationRecord < ActiveRecord::Base
  include Truthy
  self.abstract_class = true
end
