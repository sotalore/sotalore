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
        value: value,
        # :value is excepted too: it's this radio's own HTML value (the
        # positional `value` above), not the options[:value] override that
        # input_value uses above to decide which radio is checked -- those
        # are different things that happen to share a key name.
        **options.except(*NON_HTML_OPTIONS, :value))
    end

    def radio_field(attribute, value, **options)
      field_in_label(attribute, **options) do
        radio(attribute, value, **options)
      end
    end

    # Renders one radio per collection item, all sharing the same name (only
    # one can ever be checked) and delegating to #radio for each one, so id
    # generation, NON_HTML_OPTIONS filtering, and checked-state all stay in
    # sync with a plain radio_field instead of a second copy to drift out of
    # sync with it. Unlike #collection_checkboxes, no leading hidden fallback
    # input is rendered: a radio group with nothing checked simply submits no
    # value for the attribute, same as Rails' own collection_radio_buttons.
    def collection_radios(attribute, collection, value:, display:, **options)
      div(class: 'application-form-section') do
        collection.each do |item|
          field_in_label(attribute, label: item.public_send(display), **options) do
            radio(attribute, item.public_send(value), **options)
          end
        end
      end
    end

    protected

    # Stolen from the Rails source code, as the value has to become part of the HTML ID.
    def sanitized_value(value)
      value.to_s.gsub(/[\s.]/, "_").gsub(/[^-[[:word:]]]/, "").downcase
    end
  end
end
