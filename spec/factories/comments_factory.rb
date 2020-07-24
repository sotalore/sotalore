FactoryBot.define do
  factory :comment do
    association(:subject, factory: :item)
    association(:actual_author, factory: :user)
    body { "This is a wonderful comment" }
  end
end
