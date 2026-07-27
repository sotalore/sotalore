# frozen_string_literal: true

module Grav::Views::Forms
  module Selects

    def select_field(attribute, **options)
      field(attribute, **options) do
        select_id = id_for(attribute)
        select_name = select_tag_input_name(attribute, options)
        current_value = input_value(attribute, **options)

        hidden_tag_for_multiple_select(select_name, options)
        select = SelectTag.new(id: select_id, name: select_name, selected: current_value, **select_tag_options(options))
        yield select if block_given?
        render select
      end
    end

    def state_select_field(attribute, **options)
      field(attribute, **options) do
        select_id = id_for(attribute)
        select_name = select_tag_input_name(attribute, options)
        current_value = input_value(attribute, **options)

        hidden_tag_for_multiple_select(select_name, options)
        select = SelectTag.new(id: select_id, name: select_name, selected: current_value, **select_tag_options(options))
        usa = ISO3166::Country.new('US')
        state_list = usa.subdivisions.map { |k,v| [ k, v.name ] }
        select.options(state_list, display: :last, value: :first)
        yield select if block_given?
        render select
      end
    end

    private

    def select_tag_input_name(attribute, options)
      select_name = input_name(attribute, **options)
      select_name = "#{select_name}[]" if options[:multiple]
      select_name
    end

    def select_tag_options(options)
      options.slice(:data, :multiple, :autocomplete, :disabled)
    end

    def hidden_tag_for_multiple_select(name, options)
      return unless options[:multiple]

      input(name: name, type: 'hidden', value: '')
    end
  end
end
