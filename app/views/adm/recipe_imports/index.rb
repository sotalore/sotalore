# frozen_string_literal: true

class Views::Adm::RecipeImports::Index < Views::Adm::RecipeImports::Base

  def initialize(imports:)
    @imports = imports
  end

  def view_template
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      h1(class: 'text-2xl font-bold') { 'Recipe Imports' }
      p(class: 'my-2 max-w-prose') do
        plain 'Import JSON from the game recipe export plugin: paste a recipe copied from the game, '
        plain 'or upload an export file (the full list, sl-recipes-export.json, or a single recipe). '
        plain 'Nothing changes on the site until you apply entries from the import.'
      end

      div(class: 'my-4 grid grid-cols-1 lg:grid-cols-2 gap-6') do
        div do
          h2(class: 'font-bold mb-2') { 'Paste a recipe' }
          form_with(url: adm_recipe_imports_path, class: 'flex flex-col gap-2') do |f|
            f.text_area :json, rows: 6, required: true, spellcheck: false,
                        placeholder: '{"id":-1599494009,"name":"Bark Bread","categoryKey":"Crafting_Cooking",...}',
                        class: 'w-full font-mono text-xs border border-grey-400 rounded p-2 dark:bg-grey-700'
            div { f.submit 'Import pasted JSON', class: 'Button Button--primary' }
          end
        end
        div do
          h2(class: 'font-bold mb-2') { 'Upload an export file' }
          form_with(url: adm_recipe_imports_path, multipart: true, class: 'flex flex-row flex-wrap items-center gap-4') do |f|
            f.file_field :file, accept: 'application/json,.json', required: true
            f.submit 'Upload export', class: 'Button Button--primary'
          end
        end
      end

      paginate @imports
      table(class: 'table-auto w-full') do
        thead do
          tr(class: 'border-b-2 border-grey-400') do
            th(class: 'text-right') { 'ID' }
            th(class: 'text-left') { 'File' }
            th { 'Kind' }
            th(class: 'text-right') { 'Recipes' }
            th(class: 'text-left') { 'Status' }
            th { 'Uploaded' }
            th { 'By' }
            th { whitespace }
          end
        end
        tbody do
          @imports.each do |import|
            tr(class: 'border-b border-grey-200 dark:border-grey-700 hover:bg-grey-100 dark:hover:bg-grey-700') do
              td(class: 'text-right') { import.id }
              td { a(href: adm_recipe_import_path(import), class: 'Link Link--primary') { import.filename || import.to_s } }
              td(class: 'text-center text-sm') { import.full_export? ? 'full' : 'partial' }
              td(class: 'text-right') { import.entries_count }
              td(class: 'text-sm') do
                import.status_counts.select { |_, n| n.positive? }.each do |status, n|
                  span(class: 'mr-2') { "#{STATUS_LABELS[status]}: #{n}" }
                end
              end
              td(class: 'text-center text-sm') { time_ago_tag import.created_at }
              td(class: 'text-center text-sm') { import.uploaded_by&.name }
              td(class: 'text-right') { destroy_icon_to(adm_recipe_import_path(import)) }
            end
          end
        end
      end
      paginate @imports
    end
  end
end
