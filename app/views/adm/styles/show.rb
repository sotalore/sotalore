# frozen_string_literal: true

class Views::Adm::Styles::Show < Views::Adm::Styles::Base

  def view_template
    render Views::Adm::Styles::Menu.new

    div(class: "flex flex-row") do
      div(class: "basis-1_2") do
        tile_with_heading("Buttons") do
          div(class: "flex flex-row") do
            div(class: "flex flex-col text-center p-2 m-2 gap-4") do
              link_to("Default", "#", class: "Button")
              link_to("Default", "#", class: "Button Button--sm")
            end
            %w[ primary danger success warning info ].each do |color|
              div(class: "flex flex-col text-center p-2 m-2 gap-4") do
                link_to(color, "#", class: "Button Button--#{color}")
                link_to(color, "#", class: "Button Button--#{color} Button--sm")
              end
            end
          end
        end
      end
    end

    div(class: "flex flex-row") do
      div(class: "basis-1_2") do
        tile_with_heading("Flair") do
          p { flair_primary("This is flair primary message") }
          p { flair_info("This is flair info message") }
          p { flair_danger("This is flair danger message") }
          p { flair_success("This is flair success message") }
          p { flair_warning("This is flair warning message") }
        end
      end
      div(class: "basis-1_2") do
        tile_with_heading("Notice") do
          notice_info("This is notice info message")
          notice_danger("This is notice danger message")
          notice_success("This is notice success message")
          notice_warning("This is notice warning message")
        end
      end
    end

    tile do
      h3 { "Tailwind Colors" }
      shades = (1..9).to_a.map { |i| "#{i * 100}" }
      colors = %w[ slorange red orange golden green sky purple grey ]
      colors.each do |color|
        div(class: "flex flex-row") do
          shades.each do |shade|
            div(class: "px-2 py-4 flex-grow text-center bg-#{color}-#{shade} inline-block") { "#{color}-#{shade}" }
          end
        end
      end
    end

    tile_with_heading("Item Use Icons") do
      div do
        Views::ItemsHelper::USES_FOR_RECIPES.each do |use|
          raw item_use_for_recipe_tag(Item.new(use: use))
        end
        raw item_price_tag(Item.new(price: 12))
        CraftSkill::ALL.select { |skill| skill.gathering? }.each do |skill|
          raw item_gathering_tag(Item.new(gathering_skill: skill))
        end
        raw item_abstract_tag(Item.new(abstract: true))
        raw item_weight_tag(Item.new(weight: 2.2))
      end
      div(class: "flex flex-row flex-wrap") do
        Item::ITEM_USES.keys.each do |use|
          div { raw item_use_tag(Item.new(use: use)) }
        end
      end
      div(class: "flex flex-row flex-wrap mt-4") do
        Item::ITEM_USES.keys.each do |use|
          div { raw item_use_tag(Item.new(use: use), large: true) }
        end
      end
      div(class: "flex flex-row flex-wrap mt-4") do
        CraftSkill::ALL.select { |skill| skill.gathering? }.each do |skill|
          raw item_gathering_tag(Item.new(gathering_skill: skill), large: true)
        end
      end
    end

    div(class: "mb-8") { raw safe("&nbsp;") }
  end

end
