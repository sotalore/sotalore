# frozen_string_literal: true

# A stand-in for a real app view (like Views::Scenes::Form), used only to
# prove that Grav::Views::Forms::FormBuilder works the way it's meant to be
# consumed: `render`ed with a block from inside another Phlex component,
# rather than `include`d into it. It deliberately defines its own #model,
# unrelated to the form's, to demonstrate that FormBuilder's namespace stays
# isolated from whatever the host view already defines.
class GravFormsTestParentView < Phlex::HTML
  def initialize(form_model:)
    @form_model = form_model
  end

  def model
    'the parent view has its own unrelated #model, and this is it'
  end

  def view_template
    div(class: 'parent-view') do
      render Grav::Views::Forms::FormBuilder.new(model: @form_model, url: '/somewhere') do |f|
        f.text_field(:name)
      end
    end
  end
end
