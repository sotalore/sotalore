require "rails_helper"

RSpec.describe RecipePolicy do
  subject { described_class }

  it_behaves_like "a standard root-only editable policy", Recipe
end
