FactoryBot.define do
  factory(:avatar) do
    association(:user, factory: :user)
    sequence(:name)  { |i| "Avatar #{i}" }
  end
end
