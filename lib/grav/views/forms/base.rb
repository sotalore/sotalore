# frozen_string_literal: true

# The full set of field/label/error/action behavior this library provides,
# as a mixin for `include`ing directly into your own Phlex view class.
#
# For new forms, prefer Grav::Views::Forms::FormBuilder instead: it's this
# same module, already wired onto its own small Phlex::HTML class, meant to
# be `render`ed with a yielded block rather than `include`d -- see its
# comment for why. This module isn't going anywhere, and existing forms
# built directly on it keep working unchanged; there's no need to migrate
# everything just to start using FormBuilder for new ones.
module Grav::Views::Forms::Base
  include Phlex::Rails::Helpers::FieldID
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::FormAuthenticityToken

  include Grav::Views::Forms::Naming
  include Grav::Views::Forms::Errors
  include Grav::Views::Forms::Actions
  include Grav::Views::Forms::FormTag

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
end
