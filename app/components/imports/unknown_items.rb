# frozen_string_literal: true

# On an import's review page: items the site doesn't know, each with Create
# (a new item) and Use (an existing one), and Create selected for many at
# once. The checkboxes belong to a form of their own, since each row has its
# own Use form. The forms redirect back to the review page, which Turbo
# refreshes by morphing (they're replace visits, so the redirect's ?open=
# still counts as the same page): it stays where it was scrolled to, with
# this list open.
#
# +action+ is where the forms post (the import's resolve path); +describe+
# gives an item's line under its name.
class Components::Imports::UnknownItems < Components::Base

  INPUT_CSS = 'border border-grey-400 rounded px-2 py-1 text-sm dark:bg-grey-700'

  def initialize(section:, title:, items:, hint:, action:, describe:, collapsed: false, open: false)
    @section = section
    @title = title
    @items = items
    @hint = hint
    @action = action
    @describe = describe
    @collapsed = collapsed
    @open = open
  end

  def render?
    @items.any?
  end

  def view_template
    div(id: @section, data: { controller: 'check-all' }) do
      if @collapsed
        details(class: 'mt-4', open: @open) do
          summary(class: 'cursor-pointer text-lg font-bold') { heading }
          body
        end
      else
        h2(class: 'mt-6 mb-1 text-lg font-bold') { heading }
        body
      end
    end
  end

  private

  def heading
    "#{@title} (#{@items.size})"
  end

  def form_id
    "create-#{@section}"
  end

  def body
    p(class: 'mb-2 text-sm max-w-prose') { @hint }
    form(id: form_id, action: @action, method: 'post', class: 'mb-2 flex flex-row flex-wrap items-center gap-3',
         data: { turbo_action: 'replace' }) do
      hidden_fields
      input(type: 'hidden', name: 'resolution', value: 'create_many')
      label(class: 'flex flex-row items-center gap-1 text-sm') do
        input(type: 'checkbox', data: { action: 'check-all#toggle' })
        plain 'Select all'
      end
      button(type: 'submit', class: 'Button Button--sm Button--primary') { 'Create selected' }
    end
    table(class: 'table-auto text-sm') { @items.each { |unknown| row(unknown) } }
  end

  def row(unknown)
    tr(class: 'border-b border-grey-200 dark:border-grey-700 align-top') do
      td(class: 'pr-2 py-1') do
        input(type: 'checkbox', name: 'selected[]', form: form_id, value: { name: unknown.name, key: unknown.key }.to_json,
              data: { check_all_target: 'box' }, aria: { label: "Select #{unknown.name}" })
      end
      td(class: 'pr-3 py-1') do
        strong { unknown.name }
        div(class: 'text-xs text-grey-500') { [ unknown.key || 'no key', @describe.(unknown) ].compact.join(' · ') }
      end
      td(class: 'py-1') do
        form(action: @action, method: 'post', class: 'flex flex-row flex-wrap items-center gap-1', data: { turbo_action: 'replace' }) do
          hidden_fields
          input(type: 'hidden', name: 'name', value: unknown.name)
          input(type: 'hidden', name: 'key', value: unknown.key) if unknown.key
          button(type: 'submit', name: 'resolution', value: 'create', class: 'Button Button--sm Button--default') { 'Create' }
          input(type: 'text', name: 'item_name', placeholder: 'or an existing item', class: "#{INPUT_CSS} w-48")
          button(type: 'submit', name: 'resolution', value: 'use', class: 'Button Button--sm Button--default') { 'Use' }
        end
      end
    end
  end

  def hidden_fields
    input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
    input(type: 'hidden', name: 'open', value: @section)
  end
end
