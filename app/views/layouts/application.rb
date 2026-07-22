# frozen_string_literal: true

class Views::Layouts::Application < Views::Base
  include Phlex::Rails::Layout

  def view_template
    doctype
    html do
      head do
        meta(content: "text/html; charset=UTF-8", http_equiv: safe("Content-Type"))
        title { page_title ? "#{page_title} -- SotA Lore" : "SotA Lore" }
        csrf_meta_tags
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width, initial-scale=1.0")
        stylesheet_link_tag "tailwind", data_turbo_track: "reload"
        stylesheet_link_tag "trix", "actiontext", "tailwind", media: "all", "data-turbolinks-track": "reload"
        stylesheet_link_tag(
          "https://cdnjs.cloudflare.com/ajax/libs/lightgallery/2.7.1/css/lightgallery.min.css",
          media: "all",
          integrity: "sha512-F2E+YYE1gkt0T5TVajAslgDfTEUQKtlu4ralVq78ViNxhKXQLrgQLLie8u1tVdG2vWnB3ute4hcdbiBtvJQh0g==",
          crossorigin: "anonymous",
          referrerpolicy: "no-referrer"
        )
        javascript_importmap_tags
        javascript_include_tag "https://challenges.cloudflare.com/turnstile/v0/api.js", async: true, defer: true
        action_cable_meta_tag

        link(rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png")
        link(rel: "icon", type: "image/png", sizes: "32x32", href: "/favicon-32x32.png")
        link(rel: "icon", type: "image/png", sizes: "16x16", href: "/favicon-16x16.png")
        link(rel: "manifest", href: "/site.webmanifest")
      end

      body(class: "bg-grey-100", data: { controller: "mousetrap", turbo_prefetch: "false" }) do
        div(class: "flex flex-row h-screen") do
          div(class: "bg-slorange-700 w-16 lg:w-40") do
            div(class: "h-12 p-3 pl-1 text-center") do
              link_to("/", class: "text-xl font-bold text-zinc-200") do
                span(class: "hidden lg:inline") do
                  img(src: asset_path("sota-icons/sota_crestcolor.png"), class: "h-6 inline-block")
                  plain " SOTA LORE"
                end
                span(class: "inline lg:hidden") { "SL" }
              end
            end

            nav do
              site_nav_link_to("My Recipes", user_recipes_path, "book") if current_user.not_null?
              site_nav_link_to("My Avatars", avatars_path, "shield", active: [ [ "avatars" ], [] ])
              site_nav_link_to("Skills", current_skills_path, "jewel", active: [ [ "skills" ], [] ])
              site_nav_link_to("Items", items_path, "box")
              site_nav_link_to("Recipes", recipes_path, "recipe")
              site_nav_link_to("Scenes", scenes_path, "map")
              site_nav_link_to("Cabalists", cabalists_path, "user_group")
              site_nav_link_to("Rifts", lunar_rifts_path, "location_marker")
              site_nav_link_to("Trainers", master_trainers_path, "location_marker")
              site_nav_link_to("Farming", farming_path, "hoe")
              site_nav_link_to("Planting", plantings_path, "seedling") if current_user.not_null?
              site_nav_link_to("Comments", comments_path, "chat")

              if policy(:default_admin).index?
                hr(class: "my-2")
                site_nav_link_to("ADM", adm_users_path, "key")
              end

              hr(class: "my-2")
              if current_user.not_null?
                site_nav_link_to("Sign Out", destroy_user_session_path, "sign_out", data: { turbo: "false" })
              else
                site_nav_link_to("Sign In", new_user_session_path, "sign_in", data: { turbo: "false" })
                site_nav_link_to("Register", new_user_registration_path, "user_plus", data: { turbo: "false" })
              end
            end
          end

          div(class: "flex-1 flex overflow-hidden") do
            div(class: "flex-1 overflow-y-scroll") do
              div(class: "z-50 bg-slorange-700 h-12") do
                div(class: "global-search text-slate-200 relative", data: { controller: "autocomplete", "autocomplete-url-value" => search_global_path }) do
                  form(class: "inline-block h-12 px-4", action: search_path, method: "GET") do
                    input(id: "global-search", class: "global-search-input", name: "q", placeholder: "Search", type: "text", data: { "autocomplete-target" => "input" })
                    div(class: "global-search-results", data: { "autocomplete-target" => "results" })
                  end
                end
              end

              div(class: "content grow") do
                div(id: "flash-messages-container") { render_flash_messages }
                yield
              end
            end
          end
        end
      end
    end
  end
end
