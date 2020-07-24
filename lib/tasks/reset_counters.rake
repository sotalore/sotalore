desc "Update all counter caches"
task update_counters: :environment do
  Item.find_each do |item|
    Item.reset_counters(item.id, :ingredients, :results)
  end
  Recipe.find_each do |recipe|
    Recipe.reset_counters(recipe.id, :ingredients, :results)
  end
end
