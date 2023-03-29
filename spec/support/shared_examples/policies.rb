RSpec.shared_examples "a standard root-only editable policy" do |model|
  let(:user) { build :user }
  let(:root) { build :user, :root }

  permissions :show? do
    it "allows access to all" do
      expect(subject).to permit(user, Recipe.new)
    end
  end

  permissions :create? do
    it "disallows access to non-root" do
      expect(subject).to_not permit(user, Recipe.new)
    end

    it "allows access to root" do
      expect(subject).to permit(root, Recipe.new)
    end
  end

  permissions :update? do
    it "disallows access to non-root" do
      expect(subject).to_not permit(user, Recipe.new)
    end

    it "allows access to root" do
      expect(subject).to permit(root, Recipe.new)
    end
  end

  permissions :destroy? do
    it "disallows access to non-root" do
      expect(subject).to_not permit(user, Recipe.new)
    end

    it "allows access to root" do
      expect(subject).to permit(root, Recipe.new)
    end
  end
end

