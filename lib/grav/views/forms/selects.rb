# frozen_string_literal: true

begin
  require 'iso3166'
rescue LoadError
  # iso3166 is an optional dependency: only the projects that actually use
  # state_select_field need to add it to their own Gemfile. When it isn't
  # installed, state_select_field below simply isn't defined, so calling it
  # raises a plain NoMethodError instead of failing deep inside on a missing
  # ISO3166 constant.
end

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

    if defined?(ISO3166)
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
