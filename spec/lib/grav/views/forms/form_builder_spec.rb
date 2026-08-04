# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Grav::Views::Forms::FormBuilder do
  # FormBuilder itself is just Base (plus the Routes helper Base needs)
  # wired onto a real Phlex::HTML class, so all the widget/naming/error/
  # action behavior is already covered by the rest of this directory's
  # specs, run against FormBuilder directly. What's specific to FormBuilder
  # -- and not covered anywhere else -- is that it's meant to be `render`ed
  # with a block from *inside* another Phlex component's own view_template,
  # the same way `render SomeComponent.new(...) { |c| ... }` or Rails'
  # `form_with(model: x) { |f| ... }` work, rather than `include`d into it.
  it 'renders correctly when rendered with a yielded block from a parent Phlex component' do
    model = GravFormsTestModel.new(name: 'Ada')
    html = ApplicationController.renderer.render(
      GravFormsTestParentView.new(form_model: model), layout: false
    )
    frag = Nokogiri::HTML5.fragment(html)

    expect(frag.at_css('.parent-view form')).to be_present
    expect(frag.at_css('input[name="grav_forms_test_model[name]"]')['value']).to eq('Ada')
  end

  it "does not leak the host view's own method definitions into the form, or vice versa" do
    model = GravFormsTestModel.new(name: 'Ada')
    parent = GravFormsTestParentView.new(form_model: model)

    # The parent's #model is unrelated to the form's model, proving
    # FormBuilder's namespace doesn't collide with (or get shadowed by)
    # whatever the host view already defines -- the actual point of moving
    # widget helpers onto a standalone object instead of a shared mixin.
    expect(parent.model).to eq('the parent view has its own unrelated #model, and this is it')

    html = ApplicationController.renderer.render(parent, layout: false)
    expect(Nokogiri::HTML5.fragment(html).at_css('input[type="text"]')['value']).to eq('Ada')
  end

  it "isn't reachable through the app's own Components::Base/Views::Base helpers" do
    # FormBuilder < Phlex::HTML directly -- it never inherits Components::Base
    # or Views::Base, so none of this app's general-purpose view helpers
    # (tile, formatted_body, register_value_helper :params, etc.) are part of
    # its method surface, and can't collide with the library's own methods.
    expect(described_class.ancestors).not_to include(Components::Base)
  end
end
