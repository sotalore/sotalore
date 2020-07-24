#   1 Recipe
#   2 Produced
#   7 Ingredients
#   8 Ing 1
#   9 Amt 1
#  11 Ing 2
#  12 Amt 2
#  14 Ing 3
#  15 Amt 3
#  17 Ing 4
#  18 Amt 4
#  20 Ing 5
#  21 Amt 5
#  23 Ing 6
#  24 Amt 6
#  26 Ing 7
#  27 Amt 7
#  29 Ing 8
#  30 Amt 8
#  32 Ing 9
#  33 Amt 9
#  35 Ing 10
#  36 Amt 10
#  38 Ing 11
#  39 Amt 11
#  42 Category
#  43 Skill
#  44 Skill Req
#  53 Icon
# 106 RecipeName
# 107 Tool List

namespace :data do

  task code: :environment do
    class RowData
      include ::RecipeKey

      Ingredient = Struct.new(:name, :count) do
        def item
          @item ||= Item.find_by(name: name)
        end

        def item_id
          item&.id
        end

        def to_s
          "#{count} #{name}"
        end
      end

      def initialize(data)
        @data = data
      end

      alias_method :recipe_key, :generate_recipe_key

      delegate :[], to: :@data

      def to_s
        @data.inspect
      end

      def craft_skill
        CraftSkill.find(@data[43].to_s.downcase)
      end

      def name
        @data[1]&.strip
      end

      def recipe_name
        @data[106]&.strip
      end

      def result_count
        @result_count ||= @data[2] ? Integer(@data[2]) : nil
      end

      def ingredients
        @ingredients ||= (0..10).map { |i| (i * 3) + 8 }.map do |idx|
          name = @data[idx]
          count = @data[idx+1]
          unless craft_skill&.primary_tool == name
            Ingredient.new(name, Integer(count)) if name.present?
          end
        end.compact
      end

      IGNORED = ["Fat", "Masterwork", "Mutton Meat", "Pork Meat",
                "Bovine Meat", "Venison Meat"]

      IGNORED_PATTERNS = [/bone/i, /fat/i, /meat/i, /sauteed bass/i]
      def recipe?
        return false if IGNORED_PATTERNS.any? { |p| p.match(name) }
        !IGNORED.include?(name) && ingredients.any?
      end

    end
  end

  task setup: :code do
    require 'csv'

    file = "data/crafting-info-66.csv"
    @records = CSV.parse(File.open(file).read)
    @records = @records.map { |r| RowData.new(r) }
    @headings = @records.shift
  end

  desc "Inspect data from spreadsheet data v66"
  task inspect: :setup do
    ins = 43
    puts "\nInspecting: #{@headings[ins]}\n"
    samp = @records.select { |r| r[ins].present? }.sample(40)
    width = samp.inject(10) { |w,r|
      r.recipe_name.to_s.length > w ? r.recipe_name.to_s.length : w }
    width = 40 if width > 40
    samp.each do |data|
      puts "  %#{width}s => %s" % [ data.recipe_name.to_s.truncate(width), data[ins] ]
    end
  end

  desc "Inspect recipe data from spreadsheet data v66"
  task inspect_recipes: :setup do
    recipes = @records.select(&:recipe?)
    grouped = recipes.group_by(&:recipe_key)
    grouped.each do |key, recipes|
      if recipes.size > 1
        puts recipes.map(&:name).join(", ")
        puts
      end
    end
  end

  def cleaned_recipes
    return @cleaned_recipes if defined?(@cleaned_recipes)
    recipes = @records.select(&:recipe?)
    grouped = recipes.group_by(&:recipe_key)
    @cleaned_recipes = grouped.map do |key, recipes|
      recipes.first if recipes.size == 1
    end
    @cleaned_recipes = @cleaned_recipes.flatten.compact
  end

  task ingredients: :setup do
    ingredients = @records
                  .map { |r| r.ingredients.map(&:name) }
                  .flatten
                  .compact
                  .uniq
    ingredients.each do |i|
      if Item.where(name: i).empty?
        item = Item.new(name: i, use: 'component')
        item.save!
        puts "Added Item from ingredient: #{i}"
      end
    end
  end

  task items: :setup do
    @records.each do |r|
      if Item.where(name: r.recipe_name).empty?
        Item.create!(name: r.recipe_name)
        puts "Added Item from recipe: #{r.recipe_name}"
      end
    end
  end

  def save_recipe(r, recipe=nil)
    log = []
    log << "#{recipe ? "Updating" : "Creating"} #{r.recipe_name}"
    recipe ||= Recipe.new(name: r.recipe_name, craft_skill: r.craft_skill)
    recipe_rename = false

    if recipe.name != r.name
      log << "  Renaming from #{recipe.name}"
      recipe.name = r.recipe_name
      recipe_rename = true
    end

    if recipe.persisted? && recipe.craft_skill != r.craft_skill
      log << "*** Probably shouldn't change craft skills on recipes"
      puts log
      return
    end

    if recipe.results.empty?
      recipe.results.new(item: Item.find_by(name: r.recipe_name), count: r.result_count)
    elsif recipe.results.size == 1
      result = recipe.results.first
      if result.name != r.recipe_name
        unless recipe_rename
          log << "*** Did something change result? #{result.name} => #{r.recipe_name}"
          puts log
          return
        end
        log << "  Updating result from #{result.name} to #{r.recipe_name}"
        result.item = Item.find_by!(name: r.recipe_name)
      else
        result.count = r.result_count
      end
    else
      log << "  Skipping multi-result recipe: #{r.recipe_name}"
      puts log
      return
    end

    # Go through the existing
    recipe.ingredients.each do |cur_ing|
      new_ing = r.ingredients.find { |i| i.name == cur_ing.name }
      if new_ing
        if cur_ing.count != new_ing.count
          log << "  Changing count for #{new_ing.name} from #{cur_ing.count} to #{new_ing.count}"
          cur_ing.count = new_ing.count
        end
      else
        log << "  Removing ingredient: #{cur_ing.name}"
        new_ing.mark_for_destruction
      end
    end

    # Go through any new
    r.ingredients.each do |new_ing|
      unless recipe.ingredients.any? { |i| i.name == new_ing.name }
        log << "  Adding #{new_ing.to_s}"
        recipe.ingredients.build(item: new_ing.item, count: new_ing.count)
      end
    end

    changes = recipe.changed?
    changes ||= recipe.results.any? { |r| r.changed? || r.marked_for_destruction? }
    changes ||= recipe.ingredients.any? { |i| i.changed? || i.marked_for_destruction? }
    if changes
      if recipe.valid?
        recipe.save!
      else
        puts log
        puts "*** Recipe invalid"
        puts recipe.attributes.inspect
        puts recipe.errors.full_messages
        raise "Cannot continue"
      end
    end
  end

  task recipes_by_name: :setup do
    cleaned_recipes.each do |r|
      actual = Recipe.find_by(name: r.recipe_name)
      unless actual
        actual = Recipe.find_by(recipe_key: r.recipe_key)
        save_recipe(r, actual)
      end
    end
  end

  task recipes_by_key: :setup do
    cleaned_recipes.each do |r|
      actual = Recipe.find_by(recipe_key: r.recipe_key)
      save_recipe(r, actual)
    end
  end

  desc "Update all the data"
  task all: [ :ingredients, :items, :recipes_by_name, :recipes_by_key ]
end
