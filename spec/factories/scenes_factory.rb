FactoryBot.define do
  factory :scene do
    sequence(:name) { |i| "Scene #{i}" }
    level_id { 3 }
    scene_type_id { 1 }
    region_id { 1 }
    parent_id do
      if name == 'Overworld'
        nil
      else
        (Scene.find_by(name: 'Overworld') || create(:scene, :overworld)).id
      end
    end

    trait :overworld do
      name { "Overworld" }
      parent_id { nil }
    end
  end
end
