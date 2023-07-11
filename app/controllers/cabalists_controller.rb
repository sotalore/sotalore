# frozen_string_literal: true

class CabalistsController < ApplicationController
  skip_after_action :verify_authorized

  def show
  end
end
