# frozen_string_literal: true

class Components::Base < Phlex::HTML
  include Components
  include Views::IconHelper
  include Views::ItemsHelper
  include Views::ButtonHelper
  include Views::FlairHelper
  include Views::NoticeHelper

  # Include any helpers you want to be available across all components
  include Phlex::Rails::Helpers::Routes
  include Phlex::Rails::Helpers::DOMID
  include Phlex::Rails::Helpers::AssetPath
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::Pluralize
  include Phlex::Rails::Helpers::FieldSetTag
  include Phlex::Rails::Helpers::ImageTag
  include Phlex::Rails::Helpers::ImagePath
  include Phlex::Rails::Helpers::TurboFrameTag

  register_value_helper :policy
  register_value_helper :l
  register_value_helper :page_title
  register_value_helper :params
  register_value_helper :session

  register_output_helper :local_time_ago

  def time_ago_tag(time, options={})
    local_time_ago(time) if time
  end

  def formatted_body(str)
    return nil if str.blank?

    div(class: 'prose') do
      raw(safe(Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(hard_wrap: true)).render(str)))
    end
  end

  def current_skills_path(activity: 'adventuring')
    if params[:avatar_id] == 'none'
      return avatar_skills_path(avatar_id: 'none', activity: activity)
    end

    avatar = current_avatar
    return skills_path(activity: activity) unless avatar

    avatar_skills_path(avatar, activity: activity)
  end

  def current_avatar
    return nil if Current.user.null?

    if session[:current_avatar_id]
      avatar = Current.user.avatars.find_by(id: session[:current_avatar_id])
      if avatar.nil?
        session.delete(:current_avatar_id)
      else
        return avatar
      end
    end
    Current.user.avatars.detect(&:is_default)
  end

  def tile(type=nil, options={}, &block)
    css_class = "#{options[:class]} Tile"
    css_class += " Tile--#{type}" if type

    options[:class] = css_class
    div(**options, &block)
  end

  def tile_body(type=nil, &block)
    css_class = "Tile-body"
    css_class += " Tile-body--#{type}" if type
    div(class: css_class, &block)
  end

  def tile_heading(heading, subheading: nil, type: nil, &block)
    div(class: "Tile-heading") do
      h3 do
        raw(safe(heading.to_s))
        whitespace
        span(class: "Tile-subheading") { subheading }
      end
      div(class: "Tile-controls", &block) if block
    end
  end

  def tile_with_heading(heading, subheading=nil, options={}, &block)
    if Hash === subheading
      options, subheading = subheading, nil
    end
    tile(options[:type], options) do
      tile_heading(heading, subheading: subheading, type: options[:type])
      tile_body(&block)
    end
  end

  if Rails.env.development?
    def before_template
      comment { "Before #{self.class.name}" }
      super
    end
  end
end
