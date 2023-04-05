# frozen_string_literal: true

class TimeController < ApplicationController
  skip_after_action :verify_authorized

  def show
    @nb_time = Clock.time_to_bst(Time.zone.now)
  end
end
