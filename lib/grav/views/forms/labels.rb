# frozen_string_literal: true

module Grav::Views::Forms
  module Labels

    def label_for(attribute, label: nil, **options)
      case label
      when nil
        lookup_label(attribute)
      when Symbol
        lookup_label(label)
      when String
        label
      when Proc
        label.call
      when Module
        nomenclature(label)
      end
    end

    def lookup_label(label, **options)
      I18n.t(label, scope: label_scope, default: label.to_s.titleize, **options)
    end

    def label_scope
      @label_scope ||= [ :helpers, :label, @model&.model_name&.i18n_key ]
    end

  end
end
