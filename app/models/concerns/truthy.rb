# frozen-string-literal: true

require 'set'

module Truthy
  extend ActiveSupport::Concern

  TRUE_VALS = [true, 1, '1', 't', 'T', 'true', 'TRUE', 'on', 'ON'].to_set
  #FALSE_VALUES = [false, 0, '0', 'f', 'F', 'false', 'FALSE', 'off', 'OFF'].to_set

  def equivalent_to_true?(val)
    TRUE_VALS.include? val
  end

  alias :truthy? :equivalent_to_true?

end
