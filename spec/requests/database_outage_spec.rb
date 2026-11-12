# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "When the database refuses connections", type: :request do
  let(:refused) do
    ActiveRecord::ConnectionNotEstablished.new(
      "connection to server failed: Connection refused")
  end

  before do
    allow_any_instance_of(HomeController).to receive(:show).and_raise(refused)
  end

  it "answers with the 503 page" do
    # Show the public page, as production does, rather than the debug page.
    env_config = Rails.application.env_config
    detailed = env_config["action_dispatch.show_detailed_exceptions"]
    env_config["action_dispatch.show_detailed_exceptions"] = false
    begin
      get root_path
    ensure
      env_config["action_dispatch.show_detailed_exceptions"] = detailed
    end

    expect(response).to have_http_status(:service_unavailable)
    expect(response.body).to include("can't reach its database")
  end

  it "groups the error under one Honeybadger fingerprint" do
    notice = Honeybadger::Notice.new(Honeybadger.config, exception: refused)
    Honeybadger.config.before_notify_hooks.each { |hook| hook.call(notice) }

    expect(notice.fingerprint).to eq("database-connection-refused")
  end
end
