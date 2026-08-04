# frozen_string_literal: true

module Grav::Views::Forms
  # The submit/cancel controls a form ends with.
  module Actions

    def form_actions(&block)
      div(class: 'form-actions', &block)
    end

    def cancel_button(text='Cancel', url: nil, **options)
      url ||= @cancel_url || polymorphic_path(@given_model)
      options[:class] = [ 'form-cancel-button', options[:class] ]
      a(href: url, **options) { text }
    end

    def submit_button(text=nil, **options)
      options[:class] = [ 'form-submit-button', options[:class] ]
      options[:name] ||= 'commit'
      if text.nil?
        if model
          text = model.persisted? ? 'Update' : 'Create'
        else
          text = 'Submit'
        end
      end
      input(type: 'submit', value: text, **options)
    end

  end
end
