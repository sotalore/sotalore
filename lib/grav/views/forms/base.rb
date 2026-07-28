# frozen_string_literal: true

module Grav::Views::Forms::Base
  include Phlex::Rails::Helpers::FieldID
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::FormAuthenticityToken

  include Grav::Views::Forms::Fields
  include Grav::Views::Forms::Labels
  include Grav::Views::Forms::Hints
  include Grav::Views::Forms::BasicInputs
  include Grav::Views::Forms::Selects
  include Grav::Views::Forms::CheckBoxes
  include Grav::Views::Forms::Radios

  attr_reader :url, :form_options
  attr_accessor :cancel_url, :style, :form_name

  def initialize(model: nil, url: nil, cancel_url: nil, style: :default, **form_options)
    raise ArgumentError, 'model or url must be provided' unless model || url

    @given_model = model
    @url = url
    @cancel_url = cancel_url
    @style = style
    @form_name = form_options.delete(:form_name)
    @form_options = form_options
  end

  def model
    @model ||= case @given_model
    when Array
      @given_model.last
    else
      @given_model
    end
  end

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

  def errors_for(attribute, **options)
    return unless errors_on?(attribute, **options)

    div(class: 'form-errors') do
      model.errors[options[:errors_from] || attribute].join("; ")
    end
  end

  # A block-level summary of every error on the model (including
  # attribute-less/:base errors), for forms whose validations aren't
  # all attached to a single rendered field.
  def error_messages(heading: nil)
    return unless model && model.errors.any?

    heading ||= "Your #{model.class.model_name.human} could not be saved"
    div(class: 'form-errors-summary') do
      h4 { heading }
      ul do
        model.errors.full_messages.each { |message| li { message } }
      end
    end
  end

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

  def errors_on?(attribute, **options)
    model && model.errors.include?(options[:errors_from] || attribute)
  end
end
