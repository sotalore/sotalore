# frozen-string-literal: true

module DataConfirmationsHelper

  def confirmation_button(parent)
    default_button_to("#{icon_tag('check')} Confirm".html_safe,
                              [ parent, :data_confirmations ], method: :post)
  end

  def confirmation_icon(parent)
    if policy(parent).edit?
      default_button_to(icon_tag('check'), [ parent, :data_confirmations ], method: :post)
    end
  end

  def confirmation_tag(parent)
    if parent.last_confirmed_at
      content_tag(:em) do
        raw("confirmed #{local_time_ago(parent.last_confirmed_at)} ") +
          "by #{parent.last_confirmed_by || 'unknown'}"
      end
    else
      content_tag(:em, "never confirmed")
    end
  end

end
