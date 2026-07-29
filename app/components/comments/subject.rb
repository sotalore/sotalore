# frozen_string_literal: true

class Components::Comments::Subject < Components::Base

  def initialize(subject:)
    @subject = subject
  end

  def view_template
    if policy(Comment).new?
      div(id: "new-comment", class: "mb-4") do
        render Components::Comments::Form.new(subject: @subject, comment: Comment.new)
      end
    end

    div(id: "comments") do
      comments = Comment.for_subject(@subject).includes(:actual_author).for_feed(Current.user)

      comments.each do |comment|
        render Components::Comments::Card.new(comment: comment, parent: @subject)
      end

      unless comments.last_page?
        div(class: "text-right") do
          link_to("view all comments", [ @subject, :comments ])
        end
      end
    end
  end

end
