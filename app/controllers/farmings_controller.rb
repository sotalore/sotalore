class FarmingsController < ApplicationController
  skip_after_action :verify_authorized
  def show
    render Views::Farmings::Show.new
  end
end
