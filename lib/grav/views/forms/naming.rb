# frozen_string_literal: true

module Grav::Views::Forms
  # Derives HTML ids/names/values for a field from the form's model (or its
  # form_name, for model-less/filter forms), consistently across every
  # widget helper.
  module Naming

    def id_for(attribute, **options)
      return field_id(model.class.model_name.param_key, attribute, index: options[:index]) if model
      return field_id(form_name, attribute, index: options[:index]) if form_name

      attribute.to_s
    end

    def form_id(**options)
      return options[:id] if options.key?(:id)
      return dom_id(model) if model
      return form_name if form_name

      nil
    end

    def input_name(attribute, **options)
      return input_name_for_array(attribute, **options) if options[:array]
      return "#{model.class.model_name.param_key}[#{attribute}]" if model
      return "#{form_name}[#{attribute}]" if form_name

      attribute.to_s
    end

    def input_name_for_array(attribute, **options)
      return "#{model.class.model_name.param_key}[#{attribute}][]" if model
      return "#{form_name}[#{attribute}][]" if form_name

      "#{attribute}[]"
    end

    def input_value(attribute, **options)
      return options[:value] if options[:value]

      if model
        # There's likely other types we should handle here
        # E.g, time/date
        val = model.send(attribute)
        case val
        when Array
          val
        when Date, DateTime, Time
          val
        else
          val.to_s
        end
      else
        params[input_name(attribute)]
      end
    end

    def params
      view_context.params
    end

  end
end
