class StylesController < ApplicationController

  def show
    flash.now[:success] = "This is a success."
    flash.now.notice = "This is a notice."
    flash.now.alert = "This is an alert."
    flash.now[:error] = "This is an error."
    authorize :default_admin
  end
end
