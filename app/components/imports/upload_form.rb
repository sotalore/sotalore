# frozen_string_literal: true

# Uploading a plugin file to an admin import page: a file field made to look
# like a drop target (files are usually dragged onto it), and the submit
# button, labelled +label+. Posts the file as +file+ to +url+.
class Components::Imports::UploadForm < Components::Base

  FILE_CSS = 'w-full max-w-md cursor-pointer rounded border-2 border-dashed border-grey-400 bg-grey-100 p-3 ' \
             'text-sm hover:border-slorange-500 dark:border-grey-500 dark:bg-grey-700'

  def initialize(url:, label:)
    @url = url
    @label = label
  end

  def view_template
    form(action: @url, method: 'post', enctype: 'multipart/form-data', class: 'my-4 flex flex-wrap items-center gap-4') do
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      input(type: 'file', name: 'file', accept: 'application/json,.json', required: true, class: FILE_CSS)
      button(type: 'submit', class: 'Button Button--primary') { @label }
    end
  end

end
