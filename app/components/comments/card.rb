# frozen_string_literal: true

class Components::Comments::Card < Components::Base

  def initialize(comment:, parent: nil)
    @comment = comment
    @parent = parent
  end

  def view_template
    can_delete = policy(@comment).destroy?
    can_edit = policy(@comment).edit?
    invisible = !@comment.visible

    div(id: dom_id(@comment), class: "Comment") do
      div(class: "Comment-author") do
        div(class: "Comment-authorName") do
          span(class: "text-semibold") { @comment.author_name }
          user_flair_tag(@comment.author)
        end
        div(class: "Comment-subject") do
          if @parent != :front_page && @comment.subject != @parent
            link_to(@comment.subject, @comment.subject, data: { "turbo-frame": "_top" })
          end
        end
        div(class: "Comment-authorTime") { local_time_ago(@comment.created_at) }
      end

      div(id: dom_id(@comment, :editable)) { comment_content }

      if can_delete || can_edit || invisible
        div(class: "Comment-controls border-t border-grey-300 px-2 py-1 flex flex-row justify-end items-center gap-x-1 bg-grey-100") do
          comment_visibility_button(@comment)
          destroy_icon_to([ @comment.subject, @comment ], control: true, size: :sm) if can_delete
          edit_icon_to([ :edit, @comment.subject, @comment ], control: true, size: :sm, data: { turbo_stream: "true" }) if can_edit
        end
      end
    end
  end

  private

  def comment_visibility_button(comment)
    if policy(comment).moderate?
      data = { turbo_method: :patch }
      path    = comment_path(comment, comment: { visible: !comment.visible })
      if comment.visible
        default_button_to('hide', path, size: :sm, data: data)
      else
        primary_button_to('show', path, size: :sm, data: data)
      end
    else
      if !comment.visible
        flair_info('waiting moderation')
      end
    end
  end

  def comment_content
    if @comment.message?
      div(class: "prose p-2") { formatted_body(@comment.body) }
    elsif @comment.revision?
      revision_table
    end
  end

  def revision_table
    table(class: "my-0 border-0") do
      tr do
        th(colspan: "4", class: "text-centered") { "Updates to this item" }
      end

      @comment.revision_changes.each do |name, (from, to)|
        tr(class: "border-0 border-t border-slate-200") do
          th(class: "text-right") { name }
          td { from ? plain(from.to_s) : em { "none" } }
          td { raw(safe("&rarr;")) }
          td { to ? plain(to.to_s) : em { "none" } }
        end
      end

      if @comment.revision_result_changes.present?
        revision_change_group("result changes", @comment.revision_result_changes)
      end

      if @comment.revision_ingredient_changes.present?
        revision_change_group("ingredient changes", @comment.revision_ingredient_changes)
      end
    end
  end

  def revision_change_group(heading, changes)
    tr(class: "border-0 border-t border-slate-200") do
      th(colspan: "4", class: "text-left") { heading }
    end

    %w[ added removed ].each do |action|
      Array(changes[action]).each do |name, count|
        tr(class: "border-0 border-t border-slate-200") do
          td(class: "text-right") { em { action } }
          td(colspan: "3") { plain "#{count} #{name}" }
        end
      end
    end

    Array(changes["changes"]).each do |name, (from, to)|
      tr(class: "border-0 border-t border-slate-200") do
        th(class: "text-right") { name }
        td { plain from.to_s }
        td { raw(safe("&rarr;")) }
        td { plain to.to_s }
      end
    end
  end

end
