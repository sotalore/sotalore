# frozen_string_literal: true

class Views::Adm::Styles::Menu < Views::Base
  def view_template
    div(class: 'flex flex-row items-center gap-x-4 justify-center') do
      menu_link(adm_styles_path, 'Styles')
      menu_link(forms_adm_styles_path, 'Forms')
      menu_link(phlex_adm_styles_path, 'Phlex')
      menu_link(tiles_adm_styles_path, 'Tiles')
      menu_link(items_adm_styles_path, 'Items')
      menu_link(icons_adm_styles_path, 'Icons')
    end
  end

  def menu_link(path, text)
    a(href: path, class: 'hover:underline') { text }
  end
end
