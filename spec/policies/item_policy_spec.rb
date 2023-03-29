require "rails_helper"

RSpec.describe ItemPolicy, type: :policy do
  subject { described_class }

  it_behaves_like "a standard root-only editable policy", Item

end
