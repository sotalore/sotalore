FactoryBot.define do
  factory :scene do
    sequence(:name) { |i| "Scene #{i}" }
    level_id { 3 }
    scene_type_id { 1 }
    region_id {  1 }
  end
end
