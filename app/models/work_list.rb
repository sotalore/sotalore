# frozen-string-literal: true

class WorkList

  attr_reader :recipe, :recursive
  attr_reader :fuels, :tools, :gathered, :components, :recipes

  def initialize(recipe, count=1)
    @recipe = recipe

    @recursive  = []
    @fuels      = []
    @tools      = []
    @gathered   = []
    @components = []
    @recipes    = []

    gather_items(recipe, count)
  end

  private
  def gather_items(recipe, mult=1, seen=Set.new)
    seen << recipe
    add_recipe(recipe, mult)
    recipe.ingredients.each do |ingredient|
      item  = ingredient.item
      count = ingredient.count * mult

      if item.use_is_tool?
        add_tool(item)
      elsif item.use_is_fuel?
        add_fuel(item, count)
      elsif item.gatherable?
        add_gathered_item(item, count)
      elsif item.craftable?
        add_crafted_component(item, count, seen)
      else
        add_component(item, count)
      end
    end
  end

  def add_crafted_component(item, count, seen)
    if nested = cheapest_result_to_build(item)
      need_nested = (count / nested.count.to_f).ceil
      if seen.include?(nested.recipe)
        @recursive << item
      else
        gather_items(nested.recipe, need_nested, seen.dup)
      end
    end
  end

  def cheapest_result_to_build(item)
    item.results.sort_by(&:fuel_cost).first
  end

  def add_tool(item)
    @tools << item unless @tools.include?(item)
  end

  def add_fuel(item, count)
    add_to_growing_list(item, count, @fuels)
  end

  def add_gathered_item(item, count)
    add_to_growing_list(item, count, @gathered)
  end

  def add_component(item, count)
    add_to_growing_list(item, count, @components)
  end

  def add_recipe(recipe, count)
    add_to_growing_list(recipe, count, @recipes)
  end

  def add_to_growing_list(thing, count, list)
    if current = list.find { |t,_| t == thing }
      current[1] = current[1] + count
    else
      list << [ thing, count ]
    end
  end
end
