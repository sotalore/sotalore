# frozen_string_literal: true


class Views::Adm::Styles::Icons < Views::Base

  def view_template
    Dir[Rails.root.join('app/components/icons/*.rb')].each { |file| require file }

    render Views::Adm::Styles::Menu.new

    Components::Tile(heading: 'Icons') do
      div(class: 'flex flex-row flex-wrap') do
        Components::Icons.constants.each do |icon_class|
          next if icon_class == :Base
          icon = Components::Icons.const_get(icon_class)
          div(class: 'flex flex-col inline-block text-center p-2 m-2 border rounded') do
            div { render icon.new }
            div { icon_class.to_s.underscore }
          end
        end
      end
    end

    Components::Tile(heading: 'Icon Variations') do
      div(class: 'flex flex-row flex-wrap') do
        Components::Icons::Base::SIZES.keys.each do |size|
          div(class: 'flex flex-col inline-block text-center p-2 m-2 border rounded') do
            div { render Components::Icons::Book.new(size: size, color: :orange) }
            div { size }
          end
        end
      end

      div(class: 'flex flex-row flex-wrap') do
        Components::Icons::Base::COLORS.keys.each do |color|
          div(class: [
            'flex flex-col inline-block text-center p-2 m-2 border rounded',
            ('bg-grey-700' if color == 'white')
            ]) do
            div { render Components::Icons::Book.new(color: color) }
            div(class: ('text-white' if color == 'white')) { color }
          end
        end
      end
    end
  end
end
