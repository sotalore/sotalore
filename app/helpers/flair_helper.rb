# frozen-string-literal: true

module FlairHelper

  def flair_success(text)
    flair_tag("success", :check, text)
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
      content_tag(:span, render_icon(icon), class: "Flair-icon") + text
    end
  end

end
