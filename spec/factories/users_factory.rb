FactoryBot.define do
  factory(:user) do
    sequence(:email) { |i| "user-#{i}@test.host" }
    sequence(:name)  { |i| "Avatar #{i}" }
    password         { "password" }
    confirmed_at     { 1.week.ago }

    trait :editor do
      roles  { [ 'editor' ] }
    end
    trait :root do
      roles  { [ 'root' ] }
    end

    trait :unconfirmed do
      confirmed_at { nil }
    end
  end
end
