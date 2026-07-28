# frozen_string_literal: true

class Views::Avatars::Form < Views::Base

  def initialize(avatar:)
    @avatar = avatar
  end

  def view_template
    sl_form_for(@avatar) do |f|
      raw f.text_field(:name)
      raw f.check_box(:is_default, label: 'Set as default Avatar (for skills calculator)')
      raw f.actions {
        actions_html = "".html_safe
        actions_html << f.cancel('Cancel', avatars_path) if @avatar.persisted?
        actions_html << f.submit
        actions_html
      }
    end
  end

end
