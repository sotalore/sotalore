# frozen_string_literal: true

module Grav::Views::Forms
  module CheckBoxes

    # input_value always stringifies the model attribute before it gets here
    # (`nil.to_s` => ''), so '' has to be listed alongside the string forms of
    # the other falsy values, or an unset attribute reads as "checked".
    NOT_CHECKED_VALUES = [ 0, '0', false, 'false', nil, '' ].freeze

    def checkbox(attribute, **options)
      currently_checked = input_value(attribute, **options)
      if options.key?(:checked)
        options[:checked] = 'checked' if options[:checked]
      else
        options[:checked] = 'checked' unless NOT_CHECKED_VALUES.include?(currently_checked)
      end

      input_name = input_name(attribute, **options)

      # This sends the "not-checked" value, since HTML won't send a value when unchecked.
      # However, when disabled, nothing gets sent, so we don't want this.
      input(type: 'hidden', name: input_name, value: '0') unless options[:disabled]
      input(
        type: 'checkbox',
        id: id_for(attribute, **options),
        class: 'form-checkbox',
        name: input_name,
        **options.except(*NON_HTML_OPTIONS))
    end
    alias check_box checkbox

    def checkbox_field(attribute, **options)
      field_in_label(attribute, **options) do
        check_box(attribute, **options)
      end
    end
    alias check_box_field checkbox_field

    def collection_checkboxes(attribute, collection, value:, display:, **options)
      data_options = options.delete(:data)
      div(class: 'application-form-section') do
        input_name = input_name(attribute, array: true, **options)
        input(type: 'hidden', name: input_name, value: '')

        collection.each_with_index do |item, idx|
          field_in_label(attribute, label: item.public_send(display), index: idx, **options) do
            input(
              type: 'checkbox',
              id: id_for(attribute, index: idx, **options),
              class: 'form-checkbox',
              name: input_name,
              value: item.public_send(value),
              data: data_options,
              **options.except(*NON_HTML_OPTIONS))
          end
        end
      end
    end

  end
end
