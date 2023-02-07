class StylesController < ApplicationController

  def show
    authorize :default_admin
  end
end
