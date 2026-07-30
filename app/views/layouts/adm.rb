# frozen_string_literal: true

class Views::Layouts::Adm < Views::Layouts::Base
  include Phlex::Rails::Layout

  def view_template
    doctype
    html do
      head do
        meta(content: "text/html; charset=UTF-8", http_equiv: safe("Content-Type"))
        title { page_title ? "#{page_title} -- SOTA LORE: ADM" : "SOTA LORE: ADM" }
        csrf_meta_tags
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width, initial-scale=1.0")
        stylesheet_link_tag "trix", "actiontext", "tailwind", media: "all", data_turbo_track: "reload"
        javascript_importmap_tags
        javascript_include_tag "https://challenges.cloudflare.com/turnstile/v0/api.js", async: true, defer: true
        action_cable_meta_tag

        link(rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png")
        link(rel: "icon", type: "image/png", sizes: "32x32", href: "/favicon-32x32.png")
        link(rel: "icon", type: "image/png", sizes: "16x16", href: "/favicon-16x16.png")
        link(rel: "manifest", href: "/site.webmanifest")
      end

      body(class: "bg-white", data: { controller: "mousetrap", turbo_prefetch: "false" }) do
        div(class: "flex h-screen") do
          div(class: "bg-slorange-700 w-16 lg:w-40") do
            div(class: "h-12 p-3 text-center") do
              link_to("/", class: "text-xl font-bold text-zinc-200") do
                span(class: "hidden lg:inline") { "SOTA LORE" }
                span(class: "inline lg:hidden") { "SL" }
              end
            end
            div do
              nav(class: "main-navigation text-center lg:text-left") do
                site_nav_link_to("Users", adm_users_path, "book")
                hr(class: "my-2")
                site_nav_link_to("Styles", adm_styles_path, "key")
                hr(class: "my-2")
                site_nav_link_to("Sign Out", destroy_user_session_path, "sign_out")
              end
            end
          end

          div(class: "flex-1 flex overflow-hidden") do
            div(class: "flex-1 overflow-y-scroll") do
              div(class: "flex-grow flex flex-col z-50 bg-blue-700 h-12") do
                h2(class: "h-12 text-white") { "ADM" }

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
end
