require "rails_helper"

# Production eager-loads at boot; dev and test don't, so a class that fails to
# load (in the app or in a gem) passes every other spec and still takes the site
# down. eager_load_all covers gems' Zeitwerk loaders too, not just the app's.
RSpec.describe "Eager loading" do
  it "loads every constant without errors" do
    expect { Zeitwerk::Loader.eager_load_all }.not_to raise_error
  end
end
