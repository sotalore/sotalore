# frozen-string-literal: true

module FlairHelper

  def flair_primary(text)
    flair_tag("primary", :eye, text)
  end

  def flair_success(text)
    flair_tag("success", :badge_check, text)
  end

  def flair_danger(text)
    flair_tag("danger", :warning, text)
  end

  def flair_info(text)
    flair_tag("info", :'information_circle', text)
  end

  def flair_warning(text)
    flair_tag("warning", :warning, text)
  end

  private

  def flair_tag(modifier, icon, text)
    content_tag(:span, class: "Flair Flair--#{modifier}") do
      content_tag(:span, render_icon(icon, size: :sm), class: "Flair-icon") + text
    end
  end

end
