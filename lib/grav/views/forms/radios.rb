# frozen_string_literal: true

module Grav::Views::Forms
  module Radios

    def radio(attribute, value, **options)
      value = value.to_s
      current_value = input_value(attribute, **options).to_s

      if options.key?(:checked)
        options[:checked] = 'checked' if options[:checked]
      else
        options[:checked] = 'checked' if current_value == value
      end

      input_name = input_name(attribute, **options)

      input(
        type: 'radio',
        id: "#{id_for(attribute, **options)}_#{sanitized_value(value)}",
        class: 'form-radio',
        name: input_name,
        **options.except(*NON_HTML_OPTIONS))
    end

    def radio_field(attribute, value, **options)
      field_in_label(attribute, **options) do
        radio(attribute, value, **options)
      end
    end

    protected

    # Stolen from the Rails source code, as the value has to become part of the HTML ID.
    def sanitized_value(value)
      value.to_s.gsub(/[\s.]/, "_").gsub(/[^-[[:word:]]]/, "").downcase
    end
  end
end
