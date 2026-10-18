# frozen_string_literal: true

class Views::Adm::ItemCatalogImports::Index < Views::Base

  def initialize(imports:)
    @imports = imports
  end

  def view_template
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      h1(class: 'text-2xl font-bold') { 'Item Catalog Imports' }
      p(class: 'my-2 max-w-prose') do
        plain 'Upload the plugin\'s item catalog (sotalore-items.json): items seen in a character\'s bags, '
        plain 'with what their tooltips say when hovered with capture on (hover everything first: only the '
        plain 'tooltip tells crafted items apart). It brings in salvage lists (with quantities and chances), '
        plain 'fills missing weights and records the game\'s keys. Files need plugin 0.8.1 or later. Nothing '
        plain 'changes until you apply an import.'
      end
      form_with(url: adm_item_catalog_imports_path, multipart: true, class: 'my-4 flex flex-row flex-wrap items-center gap-4') do |f|
        f.file_field :file, accept: 'application/json,.json', required: true
        f.submit 'Upload catalog', class: 'Button Button--primary'
      end

      paginate @imports
      table(class: 'table-auto w-full') do
        thead do
          tr(class: 'border-b-2 border-grey-400 text-left') do
            %w[ ID File Items Uploaded Applied ].each { |h| th { h } }
            th
          end
        end
        tbody do
          @imports.each do |import|
            tr(class: 'border-b border-grey-200 dark:border-grey-700') do
              td { import.id.to_s }
              td { a(href: adm_item_catalog_import_path(import), class: 'Link Link--primary') { import.filename || import.to_s } }
              td do
                plain import.catalog.entries.size.to_s
                span(class: 'text-xs text-red-700 dark:text-red-300') { ' · too old to apply' } unless import.supported?
              end
              td(class: 'text-sm') do
                time_ago_tag import.created_at
                plain " by #{import.uploaded_by.name}" if import.uploaded_by
              end
              td(class: 'text-sm') { import.applied_at ? time_ago_tag(import.applied_at) : plain('not yet') }
              td(class: 'text-right') { destroy_icon_to(adm_item_catalog_import_path(import)) }
            end
          end
        end
      end
      paginate @imports
    end
  end
end
