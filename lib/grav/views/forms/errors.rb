# frozen_string_literal: true

module Grav::Views::Forms
  # Renders a model's validation errors, either inline per-field or as a
  # form-level summary.
  module Errors

    def errors_for(attribute, **options)
      return unless errors_on?(attribute, **options)

      div(class: 'form-errors') do
        model.errors[options[:errors_from] || attribute].join("; ")
      end
    end

    # A block-level summary of every error on the model (including
    # attribute-less/:base errors), for forms whose validations aren't
    # all attached to a single rendered field.
    def error_messages(heading: nil)
      return unless model && model.errors.any?

      heading ||= "Your #{model.class.model_name.human} could not be saved"
      div(class: 'form-errors-summary') do
        h4 { heading }
        ul do
          model.errors.full_messages.each { |message| li { message } }
        end
      end
    end

    def errors_on?(attribute, **options)
      model && model.errors.include?(options[:errors_from] || attribute)
    end

  end
end
