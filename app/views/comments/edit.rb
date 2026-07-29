# frozen_string_literal: true

class Views::Comments::Edit < Views::Comments::Base

  def initialize(comment:)
    @comment = comment
  end

  def view_template
    page_title("Edit Comment")

    layout_main_content do
      tile do
        tile_heading("Edit Comment") { back_button_to("Cancel", @comment.subject) }

        tile_body do
          div(class: "Comment") do
            div(class: "Comment-author") do
              div(class: "Comment-authorName") do
                span(class: "text-semibold") { Current.user.name }
                user_flair_tag(Current.user)
              end
              div(class: "Comment-authorTime") { "now" }
            end
            div(class: "Comment-body p-2") do
              render Components::Comments::Form.new(subject: @comment.subject, comment: @comment)
            end
          end
        end
      end
    end
  end

end
