# frozen_string_literal: true

class Views::Adm::Styles::Phlex < Views::Base
  def view_template
    div(class: 'max-w-2xl') do
      render Views::Adm::Styles::Menu.new

      render Components::Tile.new(heading: 'Phlex Tile', subheading: 'Just a thing') do |tile|
        tile.controls do
          button(class: 'Button Button--small') { 'Edit' }
        end
        p(class: 'text-red-500') { 'This is a p tag in the tile.'}
      end
    end
  end
end
