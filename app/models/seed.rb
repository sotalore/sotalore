# frozen-string-literal: true

class Seed < Item
  store_accessor :type_data, :yield

  def self.model_name
    ActiveModel::Name.new(self, nil, "Item")
  end

  validates :yield, numericality: { only_integer: true, greater_than: 0 }, allow_nil: true

  private
  def nilify_blanks
    self.yield = nil if self.yield.blank?

    # Do this last, to clean out `type_data`
    super
  end
end
