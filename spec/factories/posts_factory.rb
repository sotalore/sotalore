FactoryBot.define do
  factory :post do
    title { "Title of Test Post" }
    association :author, factory: :user
    content { "This is some content" }
  end
end
