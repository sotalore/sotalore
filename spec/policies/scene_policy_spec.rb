require 'rails_helper'

RSpec.describe ScenePolicy do
  subject { described_class }

  it_behaves_like "a standard root-only editable policy", Scene

end
