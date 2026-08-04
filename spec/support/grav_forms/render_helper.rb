# frozen_string_literal: true

module GravFormsRenderHelper
  # Renders a Grav::Views::Forms::FormBuilder through the real Rails render
  # pipeline, so Rails/Phlex helpers the library depends on
  # (form_authenticity_token, field_id, dom_id, polymorphic_path, params)
  # all work exactly as they do in the app, then returns the markup as a
  # parsed HTML fragment for easy assertions.
  #
  # The block is Phlex's "external content" convention: since it isn't
  # written lexically inside the form class the way real views write theirs
  # (`super do text_field(:x) end`), Phlex yields the form instance to it
  # explicitly, so the block must take it as an argument, e.g.:
  #
  #   render_grav_form(model: model) { |f| f.text_field(:name) }
  def render_grav_form(**options, &block)
    html = ApplicationController.renderer.render(Grav::Views::Forms::FormBuilder.new(**options, &block), layout: false)
    Nokogiri::HTML5.fragment(html)
  end
end
