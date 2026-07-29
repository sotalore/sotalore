# frozen_string_literal: true

class Components::Comments::Form < Components::Base
  include Grav::Views::Forms::Base
  include Phlex::Rails::Helpers::DOMID

  register_value_helper :require_turnstile?
  register_output_helper :turnstile_tag
  register_output_helper :notice_warning

  def initialize(subject:, comment:)
    @subject = subject
    super(model: [ subject, comment ].compact)
  end

  def view_template
    wrapper_id = model.persisted? ? dom_id(model) : "new-comment"

    div(id: wrapper_id, class: "my-2") do
      super do
        text_area_field(:body, skip_label: model.persisted?, rows: body_rows)

        if Current.user.null? && model.new_record?
          notice_warning do
            plain "You can post comments anonymously, or you can "
            link_to("sign-up", new_user_registration_path)
            plain ". Anonymous comments aren't visible until they are moderated by a site editor."
          end
        end

        form_actions do
          turnstile_tag if require_turnstile?
          cancel_button if model.persisted?
          submit_button(model.persisted? ? "Update Comment" : "Post Your Comment")
        end
      end
    end
  end

  private

  def body_rows
    [ model.body.to_s.scan("\n").count + 1, 3 ].max
  end

end
