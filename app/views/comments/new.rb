# frozen_string_literal: true

class Views::Comments::New < Views::Base

  def initialize(comment:)
    @comment = comment
  end

  def view_template
    page_title("New Comment")

    layout_main_content do
      tile do
        tile_heading("New Comment") { back_button_to("Cancel", @comment.subject) }

        tile_body do
          div(class: "Comment") do
            div(class: "Comment-author") do
              div(class: "Comment-authorName") do
                span(class: "text-semibold") { @comment.author_name }
                user_flair_tag(@comment.author)
              end
              div(class: "Comment-authorTime") { time_ago_tag(@comment.created_at) }
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
