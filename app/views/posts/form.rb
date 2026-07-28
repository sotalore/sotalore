# frozen_string_literal: true

class Views::Posts::Form < Views::Posts::Base
  include Grav::Views::Forms::Base
  include Phlex::Rails::Helpers::RichTextArea

  def initialize(post:)
    super(model: [ post.parent, post ].compact)
  end

  def view_template
    super do
      text_field(:title)
      rich_content_field(:content)

      form_actions { submit_button }
    end
  end

  private

  def rich_content_field(attribute, **options)
    field(attribute, **options) do
      rich_textarea(model.class.model_name.param_key, attribute, object: model)
    end
  end

end
