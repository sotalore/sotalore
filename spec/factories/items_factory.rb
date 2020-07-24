FactoryBot.define do
  factory(:item) do
    sequence(:name) { |i| "Item #{i}" }

    trait :abstract do
      name     { "Abstract Item #{rand(1000000)}" }
      abstract { true }
    end
  end

  factory :seed, class: 'Seed' do
    sequence(:name) { |i| "Seed #{i}" }
  end
end
