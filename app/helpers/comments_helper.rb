# frozen-string-literal: true

module CommentsHelper

  def comment_visibility_button(comment)
    if policy(comment).moderate?
      options = { method: :patch }
      path    = comment_path(comment, comment: { visible: !comment.visible})
      if comment.visible
        default_button_to('hide', path, options)
      else
        primary_button_to('show', path, options)
      end
    else
      if !comment.visible
        flair_info('waiting moderation')
      end
    end
  end
end
