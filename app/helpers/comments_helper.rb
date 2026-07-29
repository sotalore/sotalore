# frozen-string-literal: true

module CommentsHelper

  def render_comments_for(parent)
    render Components::Comments::Subject.new(subject: parent)
  end
end
