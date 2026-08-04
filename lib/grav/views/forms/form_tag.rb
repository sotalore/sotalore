# frozen_string_literal: true

module Grav::Views::Forms
  # The <form> element itself: its wrapping tag, method/verb handling
  # (including the GET/POST-only browser workaround below), and the CSRF
  # token.
  module FormTag

    def view_template(&block)
      # Capture the form contents before rendering the form, as
      # fields can change the form's attributes (e.g., for file uploading)
      form_contents = capture(&block)

      form(id: form_id(**form_options),
           action: form_action,
           method: html_form_method,
           class: form_classes,
           data: form_options[:data],
           **form_attributes) do
        form_authenticity_token_tag unless @exclude_authenticity_token
        form_method_tag(form_method) unless @exclude_method_tag
        raw form_contents
      end
    end

    # Browsers only support GET/POST on a <form>; anything else (patch/put/delete)
    # goes over POST with the real verb carried in the hidden _method field below.
    def html_form_method
      form_method == 'get' ? 'get' : 'post'
    end

    def form_authenticity_token_tag
      return if form_method == 'get'

      input(type: 'hidden', name: 'authenticity_token', value: form_authenticity_token, autocomplete: 'off')
    end

    def form_method_tag(method)
      return if %w[get post].include?(method.to_s)

      input(type: 'hidden', name: '_method', value: method.to_s, autocomplete: 'off')
    end

    def simple_get_form!
      @exclude_authenticity_token = true
      @exclude_method_tag = true
      form_options[:method] = 'get'
    end

    def form_classes
      case @style
      when :inline
        'application-form application-form-inline'
      else
        'application-form application-form-default'
      end
    end

    def form_section(**options, &block)
      options[:class] = [ 'application-form-section', options[:class] ]
      div(**options, &block)
    end

    def form_action
      return @url if @url
      return '#' unless model

      polymorphic_path(@given_model)
    end

    def form_method
      return form_options[:method] if form_options[:method]

      model&.persisted? ? 'patch' : 'post'
    end

    def form_attributes
      {}.tap do |attrs|
        attrs[:accept_charset] = 'UTF-8'
        attrs[:enctype] = 'multipart/form-data' if @is_upload_form
      end
    end

  end
end
