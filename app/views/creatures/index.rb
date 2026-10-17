# frozen_string_literal: true

# A list of creatures or gathering nodes, with the scenes they're in.
class Views::Creatures::Index < Views::Base

  def initialize(records:, title:)
    @records = records
    @title = title
  end

  def view_template
    page_title(@title)
    tile do
      tile_heading(@title)
      tile_body do
        p(class: "text-sm mb-2") { "From the game plugin's finds: where each is, and what gathering from it gives." }
        if @records.empty?
          p { em { "None yet." } }
        else
          table(class: "w-full text-sm") do
            @records.each do |record|
              tr(class: "border-b border-grey-200 dark:border-grey-700 align-top") do
                td(class: "py-1 pr-4 font-semibold") { link_to(record.name, record) }
                td(class: "py-1") { record.scenes.map(&:name).join(", ") }
              end
            end
          end
        end
      end
    end
  end
end
