# frozen_string_literal: true

class AuthenticationController < ApplicationController
  skip_after_action :verify_authorized
end
