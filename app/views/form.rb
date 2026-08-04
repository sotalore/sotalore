# frozen_string_literal: true

class Views::Form < Views::Base

  protected

  def form_builder(model: nil, url: nil, **options, &block)
    Grav::Views::Forms::FormBuilder.new(model: model, url: url, **options, &block)
  end
end
