# frozen_string_literal: true

class Views::Adm::FindsImports::Index < Views::Base

  def initialize(imports:)
    @imports = imports
  end

  def view_template
    div(class: 'm-2 p-4 bg-white dark:bg-grey-800') do
      h1(class: 'text-2xl font-bold') { 'Finds Imports' }
      p(class: 'my-2 max-w-prose') do
        plain 'Upload the plugin\'s finds file (sotalore-finds.json): what was found in each scene, the '
        plain 'creatures fought there and the nodes gathered from. The site records only that something '
        plain 'can be found somewhere, so uploading the same finds again changes nothing. Nothing changes '
        plain 'until you apply an import.'
      end
      form_with(url: adm_finds_imports_path, multipart: true, class: 'my-4 flex flex-row flex-wrap items-center gap-4') do |f|
        f.file_field :file, accept: 'application/json,.json', required: true, class: 'max-w-full'
        f.submit 'Upload finds', class: 'Button Button--primary'
      end

      paginate @imports
      table(class: 'table-auto w-full') do
        thead do
          tr(class: 'border-b-2 border-grey-400 text-left') do
            th { 'ID' }
            th { 'File' }
            th { 'Scenes' }
            th { 'Uploaded' }
            th { 'Applied' }
            th
          end
        end
        tbody do
          @imports.each do |import|
            tr(class: 'border-b border-grey-200 dark:border-grey-700') do
              td { import.id.to_s }
              td { a(href: adm_finds_import_path(import), class: 'Link Link--primary') { import.filename || import.to_s } }
              td { import.finds.scenes.map(&:name).to_sentence }
              td(class: 'text-sm') do
                time_ago_tag import.created_at
                plain " by #{import.uploaded_by.name}" if import.uploaded_by
              end
              td(class: 'text-sm') { import.applied_at ? time_ago_tag(import.applied_at) : plain('not yet') }
              td(class: 'text-right') { destroy_icon_to(adm_finds_import_path(import)) }
            end
          end
        end
      end
      paginate @imports
    end
  end
end
