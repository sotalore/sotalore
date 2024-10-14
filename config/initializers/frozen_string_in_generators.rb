# frozen_string_literal: true

return unless defined?(::Rails::Generators)

module RailsGeneratorFrozenStringLiteralPrepend
  RUBY_EXTENSIONS = %w[.rb .rake].freeze

  def render
    return super unless RUBY_EXTENSIONS.include? File.extname(destination)
     original = super
    return original if original.include?("# frozen_string_literal: true\n")
    "# frozen_string_literal: true\n\n#{original}"
  end
end

Thor::Actions::CreateFile.prepend RailsGeneratorFrozenStringLiteralPrepend
