# frozen_string_literal: true

class TimeController < ApplicationController
  skip_after_action :verify_authorized

  def show
    render Views::Time::Show.new
  end
end
