# frozen_string_literal: true

module Grav::Views::Forms
  module BasicInputs

    # Options that Fields/Hints/Labels understand but that aren't real HTML
    # attributes, so they must not be spread onto the rendered tag.
    NON_HTML_OPTIONS = %i[ optional hint hint_options align label label_first label_class errors_from index array skip_label ].freeze

    def hidden_tag(attribute, **options)
      input_of_type('hidden', attribute, **options)
    end

    def labelled_value_field(attribute, **options, &block)
      field(attribute, **options) do
        div(class: 'labelled-value') { yield }
      end
    end


    def text_field(attribute, **options)
      field(attribute, **options) do
        input_of_type('text', attribute, **options)
      end
    end

    def number_field(attribute, **options)
      field(attribute, **options) do
        input_of_type('number', attribute, **options)
      end
    end

    def email_field(attribute, **options)
      field(attribute, **options) do
        input_of_type('email', attribute, **options)
      end
    end

    def password_field(attribute, **options)
      field(attribute, **options) do
        input_of_type('password', attribute, **options)
      end
    end

    def date_field(attribute, **options)
      field(attribute, **options) do
        value = input_value(attribute, **options)
        value = value.strftime('%Y-%m-%d') if value.respond_to?(:strftime)
        options[:value] = value
        input_of_type('date', attribute, **options)
      end
    end

    def time_field(attribute, **options)
      field(attribute, **options) do
        value = input_value(attribute, **options)
        options[:value] = value
        input_of_type('time', attribute, **options)
      end
    end

    def color_field(attribute, **options)
      field_in_label(attribute, **options) do
        input_of_type('color', attribute, **options)
      end
    end

    def text_area_field(attribute, **options)
      field(attribute, **options) do
        textarea(id: id_for(attribute, **options), name: input_name(attribute, **options),
          class: [ 'field-input', options[:class] ],
          **options.except(:class, *NON_HTML_OPTIONS)) { input_value(attribute, **options) }
      end
    end

    def file_field(attribute, **options)
      @is_upload_form = true
      field(attribute, **options) do
        options[:value] = nil
        input_of_type('file', attribute, **options)
      end
    end

    def input_of_type(type, attribute, **options)
      input(
        id: id_for(attribute, **options),
        class: [ 'field-input', options[:class] ],
        type: type,
        name: input_name(attribute, **options),
        value: input_value(attribute, **options),
        **options.except(:class, *NON_HTML_OPTIONS))
    end


  end
end
