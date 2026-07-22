# frozen_string_literal: true

class Views::Layouts::Authentication < Views::Base
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
        javascript_importmap_tags
        javascript_include_tag "https://challenges.cloudflare.com/turnstile/v0/api.js", async: true, defer: true
        action_cable_meta_tag

        link(rel: "apple-touch-icon", sizes: "180x180", href: "/apple-touch-icon.png")
        link(rel: "icon", type: "image/png", sizes: "32x32", href: "/favicon-32x32.png")
        link(rel: "icon", type: "image/png", sizes: "16x16", href: "/favicon-16x16.png")
        link(rel: "manifest", href: "/site.webmanifest")
      end

      body(class: "h-full min-h-screen bg-gradient-to-b from-slorange-700 to-slorange-500", data: { controller: "mousetrap", turbo_prefetch: "false" }) do
        div(class: "flex flex-col justify-stretch") do
          div(class: "p-4 md:p-8 text-center") do
            link_to("/", class: "text-xl md:text-4xl font-bold text-zinc-200") do
              span do
                img(src: asset_path("sota-icons/sota_crestcolor.png"), class: "h-6 md:h-12 inline-block")
                plain " SOTA LORE"
              end
            end
          end

          div(class: "content md:flex flex-row justify-around") do
            div(id: "flash-messages-container", class: "md:basis-1_2 l:basis-1_3") { render_flash_messages }
          end
          div(class: "content px-2") { yield }
        end
      end
    end
  end
end
