# frozen_string_literal: true

module Grav::Views::Forms
  module Fields

    def field(attribute, **options, &block)
      div(class: field_classes(attribute, **options)) do
        label(for: id_for(attribute, **options)) do
          plain label_for(attribute, **options)
          if options.key?(:optional) && options[:optional]
            span(class: 'form-input-optional') do
              " (optional)"
            end
          end
        end
        yield
        hint_for(attribute, **options)
        errors_for(attribute, **options)
      end
    end

    def custom_field(attribute=nil, **options, &block)
      div(class: field_classes(attribute, **options)) do
        yield
      end
    end

    def action_field(**options, &block)
      div(class: field_classes) do
        label { safe '&nbsp;' }
        yield
      end
    end

    def field_in_label(attribute, **options, &block)
      div(class: field_classes(attribute, **options)) do
        div do
          css = [
            'field-in-label',
            ('field-in-label-reverse' if options[:label_first] == false),
            label_classes(attribute, **options),
          ]
          label(class: css) do
            span { label_for(attribute, **options) }
            yield
          end
        end
        hint_for(attribute, **options)
        errors_for(attribute, **options)
      end
    end

    def field_classes(attribute=nil, **options)
      [
        'field-container',
        ('field-align-right' if options[:align] == :right),
        ('field-with-errors' if attribute && errors_on?(attribute, **options))
      ]
    end

    def label_classes(attribute=nil, **options)
      [ options[:label_class] ]
    end

  end
end
