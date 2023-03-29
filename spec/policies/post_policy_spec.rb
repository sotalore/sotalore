require "rails_helper"

RSpec.describe PostPolicy do
  subject { described_class }

  it_behaves_like "a standard root-only editable policy", Post
end
