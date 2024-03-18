# frozen-string-literal: true

module CommentsHelper

  def comment_visibility_button(comment)
    if policy(comment).moderate?
      data = { turbo_method: :patch }
      path    = comment_path(comment, comment: { visible: !comment.visible})
      if comment.visible
        default_button_to('hide', path, size: :sm, data: data)
      else
        primary_button_to('show', path, size: :sm, data: data)
      end
    else
      if !comment.visible
        flair_info('waiting moderation')
      end
    end
  end

  def render_comments_for(parent)
    render partial: 'comments/subject', object: parent
  end
end
