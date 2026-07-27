# frozen_string_literal: true

module Grav::Views::Forms
  module Hints

    def hint_for(attribute, **options)
      text = hint_text(attribute, **options)
      return if text.blank?

      div(class: 'field-hint') do
        text
      end
    end

    def hint_text(attribute, **options)
      return options[:hint] if options[:hint].present?
      return nil if options.key?(:hint)

      hint = lookup_hint(attribute)
      return hint if hint.present?

      nil
    end

    def lookup_hint(attribute, **options)
      I18n.t(attribute, scope: hint_scope, default: '', **options)
    end

    def hint_scope
      @hint_scope ||= [ :helpers, :hint, @model&.model_name&.i18n_key ]
    end

  end
end
