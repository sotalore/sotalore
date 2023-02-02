class StylesController < ApplicationController
  layout 'application_incoming'

  def show
    authorize :default_admin
  end
end
