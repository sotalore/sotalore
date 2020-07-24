require 'csv'
class Info::Parser

  Ingredient = Struct.new(:name, :count) do
    PRIMARY_TOOL_NAMES = CraftSkill::PRIMARY_TOOLS.values.map(&:downcase)
    def to_s
      "%5s %s" % [ count || '1', name]
    end

    def primary_tool?
      PRIMARY_TOOL_NAMES.include?(name.downcase)
    end
  end

  Record = Struct.new(:name, :ingredients, :cost_to_make, :npc_value, :profit, :type, :skill) do
    def tool?
      skill == 'tool' ||
        (skill != 'Gathering' && ingredients.blank?)
    end

    def gatherable?
      skill == 'Gathering'
    end

    def created?
      ingredients.present?
    end
    alias_method :recipe?, :created?

    def craft_skill
      CraftSkill.find(skill.downcase)
    end

    def notes
      if CraftSkill::PRIMARY_TOOLS.values.any? { |t| t.downcase == name.downcase }
        "-- Primary Tool"
      end
    end

    INGREDIENT_RE = %r{^(\((\d+)\))?(.*)$}
    def ingredient_list
      @ingredient_lists = String(ingredients)
                     .split(",")
                     .map(&:strip)
                     .map { |i| INGREDIENT_RE.match(i) }
                     .map { |md| Ingredient.new(md[3], md[2]) }
    end
  end

  def initialize(txt)
    @records = CSV.parse(txt)
    puts "Dropping headings: #{@records.first.inspect}"
    @records.shift # drop the "headings"
    @records = @records.map { |r| Record.new(*r) }
    puts "Have #{@records.count} records remaining"
    puts
  end

  def self.for_file(file)
    new(File.open(file).read)
  end

  def list_gathered
    list @records.select(&:gatherable?)
  end

  def list_tools
    list @records.select(&:tool?)
  end

  def load_tools
    records = @records.select(&:tool?)
    puts "Loading #{records.size} tools"
    records.each do |r|
      item = get_item_by_name(r.name) or next
      item.use = 'tool'
      save_object(item)
    end
    puts
  end

  def load_gatherables
    records = @records.select(&:gatherable?)
    puts "Loading #{records.size} gatherables"
    records.each do |r|
      item = get_item_by_name(r.name) or next
      item.source = 'gathering'
      item.crafting_input = true
      save_object(item)
    end
  end

  def load_recipe_output
    records = @records.select(&:recipe?)
    puts "Loading recipe output from #{records.size} records"
    records.each do |r|
      item = get_item_by_name(r.name) or next
      item.source = 'recipe'
      save_object(item)
    end
    puts
  end

  def load_ingredients
    puts "Loading #{ingredients.size} ingredients"
    ingredients.each do |name|
      item = get_item_by_name(name) or next
      item.crafting_input = true
      save_object(item)
    end
    puts
  end

  def load_recipes
    ::Ingredient.delete_all
    ::Recipe.delete_all

    duplicated_keys = []

    records = @records.select(&:recipe?)
    puts "Loading #{records.size} recipes"
    records.each do |r|
      recipe = Recipe.new(name: r.name)
      recipe.craft_skill = r.craft_skill
      puts "#{recipe.persisted? ? 'updating' : 'creating'} -- #{r.craft_skill}: #{recipe.name}"
      ingredients = r.ingredient_list.map do |i|
        next if i.primary_tool?
        item = Item.find_by_name(i.name).to_a
        if item.size > 1
          puts "  ERROR: ingredient: #{i.name} has multiple matching Items"
          exit
        elsif item.size == 0
          puts "  ERROR: ingredient: #{i.name} has no matching Items"
          exit
        end
        item = item.first
        ingredient = recipe.ingredients.build(recipe: recipe, item: item)
        ingredient.count = i.count || 1
        puts "    #{ingredient}"
        ingredient
      end
      recipe.results.build(item: Item.where(name: recipe.name).first, count: 1)
      unless recipe.valid?
        if errors = recipe.errors[:recipe_key]
          duplicated_keys << recipe
        end
      end
      save_object(recipe, quiet: true)
      puts
    end
    puts "\nThe following #{duplicated_keys.size} recipes failed on duplicate keys"
    duplicated_keys.each do |recipe|
      puts recipe.name
      puts recipe.recipe_key
      puts
    end
  end

  def save_object(obj, options={})
    return unless obj.changed?
    putc(obj.new_record? ? 'o' : '.') unless options[:quiet]
    if obj.valid?
      obj.save!
    else
      puts obj.errors.full_messages
      if Recipe === obj
        puts obj.ingredients.map { |ri| ri.errors.full_messages }.compact
      end
    end
  end

  def get_item_by_name(name)
    item = Item.find_by_name(name).all.to_a
    if item.size > 1
      puts "  *** Cannot update more than one item by name #{name}"
      nil
    elsif item.size == 1
      item.first
    else
      Item.new(name: name)
    end
  end

  def list_fuel
    list @records.select(&:fuel?)
  end

  def list_created
    list_long @records.select(&:created?)
  end

  def list_problems
    list @records.select { |r| !r.craft_skill }
  end

  def list_all
    list @records
  end

  def list_all_ingredients
    puts ingredients
  end

  def list_ingredients_that_are_not_items
    puts ingredients - @records.map(&:name)
  end

  def list_recipes
    @records.select(&:recipe?).each do |r|
      puts r.name
      puts "  Skill: #{r.craft_skill}"
      r.ingredient_list.each do |i|
        puts "   #{i}"
      end
    end
  end

  private
  def list(records)
    name_width = records.map(&:name).map(&:length).max
    records.each { |r| puts "%-#{name_width}s %-20s %4s %s" % [
                              r.name, r.skill, r.npc_value, r.notes ] }
  end

  def list_long(records)
    name_width = records.map(&:name).map(&:length).max
    records.each do |r|
      puts "%-#{name_width}s %s" % [ r.name, r.skill  ]
      puts "  --> %s" % [ r.ingredients ]
      puts
    end
  end

  def ingredients
    @ingredients ||= @records.inject([]) do |ingredients,record|
      new_ingredients = String(record.ingredients)
        .split(",")
        .map(&:strip)
        .map { |i| i.gsub(/\(\d+\)/, "") }
      ingredients.concat(new_ingredients)
    end.uniq.sort!
  end
end
