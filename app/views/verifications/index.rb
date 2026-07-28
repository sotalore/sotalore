# frozen_string_literal: true

class Views::Verifications::Index < Views::Base
  include Phlex::Rails::Helpers::TimeAgoInWords

  register_value_helper :params
  register_output_helper :item_abstract_tag

  def initialize(verifiables:)
    @verifiables = verifiables
  end

  def view_template
    page_title("Verify #{params[:collection].titleize}")

    tile do
      tile_body do
        phlex_paginate @verifiables

        table(class: "Table") do
          thead do
            th { "ID" }
            th { "Name" }
            th { "Verified" }
            th { "Updated" }
          end

          tbody do
            @verifiables.each do |verifiable|
              tr do
                td { verifiable.id }
                td do
                  link_to(verifiable.name, verifiable)
                  item_abstract_tag(verifiable) if Item === verifiable
                end
                td do
                  if verifiable.verified?
                    plain "#{time_ago_in_words(verifiable.last_verified_at) if verifiable.last_verified_at} ago"
                  else
                    plain "never"
                  end
                end
                td { plain "#{time_ago_in_words(verifiable.updated_at)} ago" }
              end
            end
          end
        end

        phlex_paginate @verifiables
      end
    end
  end

end
