# frozen_string_literal: true

require 'set'

# Matches every pending entry of a RecipeImport to a site Recipe and works out
# what applying it would do, storing the result on the entry (recipe,
# match_method, status, diff, problems).
#
# Matching, in order of confidence. A site recipe can only be claimed by one
# entry, and a recipe that already has a game_id only matches by that id.
#
#   manual      - an admin linked the entry to a recipe by hand
#   game_id     - the recipe was previously synced from this game recipe
#   name        - same name (same craft skill preferred)
#   ingredients - same craft skill and identical ingredients (recipe_key);
#                 catches recipes that were renamed
#   result      - the only recipe of the same craft skill making the same item
#
# Template recipes make a group. Some are game recipes ("Dagger" takes any
# "Dagger Blade" and makes the matching dagger), others are curated on the site
# only ("Dagger Blade", standing for "Iron Dagger Blade", ...). So a template
# only matches a game recipe that also makes a group, and vice versa.
#
# Entries that are already applied or skipped are left alone, but still claim
# the recipe they were matched to.
class RecipeImportAnalyzer

  MATCH_PASSES = %i[ game_id name ingredients result ].freeze

  def initialize(import, lookup: ItemLookup.new)
    @import = import
    @lookup = lookup
  end

  def call
    load_recipes
    entries = @import.entries.to_a
    @claimed = Set.new
    @matches = {}

    entries.each do |entry|
      if entry.final? || (entry.manual_match? && @recipes_by_id[entry.recipe_id])
        claim(entry, @recipes_by_id[entry.recipe_id], entry.final? ? entry.match_method : 'manual')
      end
    end

    pending = entries.reject { |e| e.final? || @matches.key?(e.id) }
    MATCH_PASSES.each do |pass|
      pending.each do |entry|
        next if @matches.key?(entry.id)
        if recipe = send("match_by_#{pass}", entry.game_recipe)
          claim(entry, recipe, pass.to_s)
        end
      end
    end

    RecipeImportEntry.transaction do
      entries.reject(&:final?).each { |entry| analyze_entry(entry) }
      @import.update_columns(analyzed_at: Time.current)
    end
    @import
  end

  # [ingredients], where each is [item_id or nil, GameRecipe::Line]
  def resolve_lines(lines)
    lines.map { |line| [ @lookup.id_for(line.name), line ] }
  end

  private

  def load_recipes
    recipes = Recipe.preload(:ingredients, :results).to_a
    @recipes_by_id      = recipes.index_by(&:id)
    @recipes_by_game_id = recipes.select(&:game_id).index_by(&:game_id)
    @recipes_by_name    = recipes.group_by { |r| r.name.downcase }
    @recipes_by_key     = recipes.index_by(&:recipe_key)
    @template_ids       = recipes.select(&:template?).to_set(&:id)
    @recipes_by_result  = Hash.new { |h, k| h[k] = [] }
    recipes.each do |r|
      r.results.each { |res| @recipes_by_result[res.item_id] << r }
    end
  end

  def claim(entry, recipe, method)
    @claimed << recipe.id if recipe
    @matches[entry.id] = [ recipe, method ]
  end

  def claimable?(recipe, gr)
    recipe && recipe.game_id.nil? && !@claimed.include?(recipe.id) &&
      @template_ids.include?(recipe.id) == makes_group?(gr)
  end

  def makes_group?(gr)
    gr.results.any? { @lookup.abstract?(_1.name) }
  end

  def match_by_game_id(gr)
    recipe = @recipes_by_game_id[gr.game_id]
    recipe unless @claimed.include?(recipe&.id)
  end

  def match_by_name(gr)
    candidates = Array(@recipes_by_name[gr.name.downcase]).select { claimable?(_1, gr) }
    same_skill = candidates.select { |r| r.craft_skill == gr.craft_skill }
    (same_skill.presence || candidates).min_by(&:id)
  end

  def match_by_ingredients(gr)
    key = recipe_key_for(gr)
    recipe = key && @recipes_by_key[key]
    recipe if claimable?(recipe, gr)
  end

  def match_by_result(gr)
    return nil unless gr.craft_skill && gr.results.size == 1
    item_id = @lookup.id_for(gr.results.first.name) or return nil
    candidates = @recipes_by_result[item_id].select do |r|
      r.craft_skill == gr.craft_skill && claimable?(r, gr)
    end
    candidates.first if candidates.one?
  end

  # Mirrors RecipeKey#generate_recipe_key
  def recipe_key_for(gr)
    return nil unless gr.craft_skill && gr.ingredients.any?
    pairs = resolve_lines(gr.ingredients)
    return nil if pairs.any? { |id, _| id.nil? }
    [ gr.craft_skill.to_param ]
      .concat(pairs.sort_by(&:first).map { |id, line| "#{id}:#{line.count}" })
      .join('-')
  end

  def analyze_entry(entry)
    gr = entry.game_recipe
    recipe, method = @matches[entry.id]
    problems = problems_for(gr, recipe)

    entry.recipe       = recipe
    entry.match_method = method
    entry.problems     = problems
    entry.diff         = recipe ? diff_for(gr, recipe) : {}
    entry.status =
      if problems.any?
        'blocked'
      elsif recipe.nil?
        'addition'
      elsif entry.diff.empty?
        'unchanged'
      else
        'outdated'
      end
    entry.save! if entry.changed?
  end

  def problems_for(gr, recipe)
    problems = []
    unless gr.craft_skill
      problems << "Game category #{gr.category_key.inspect} isn't a site craft skill"
    end
    problems << 'Has no results' if gr.results.empty?
    problems << 'Has no ingredients' if gr.ingredients.empty?

    unknown = gr.item_names.reject { @lookup.known?(_1) }
    problems << "Unknown items: #{unknown.join(', ')}" if unknown.any?

    if unknown.empty?
      %i[ingredients results].each do |kind|
        ids = resolve_lines(gr.public_send(kind)).map(&:first)
        if ids.uniq.size != ids.size
          problems << "Two #{kind} resolve to the same site item"
        end
      end
    end

    key = recipe_key_for(gr)
    if key && (other = @recipes_by_key[key]) && other != recipe
      problems << "Same skill and ingredients as site recipe ##{other.id} (#{other.name}); " \
                  'apply or retire that one first'
    end
    problems
  end

  def diff_for(gr, recipe)
    diff = {}
    diff['name'] = [ recipe.name, gr.name ] if recipe.name != gr.name
    if recipe.craft_skill != gr.craft_skill
      diff['craft_skill'] = [ recipe.craft_skill&.key, gr.craft_skill&.key ]
    end
    if recipe.proficiency != gr.proficiency
      diff['proficiency'] = [ recipe.proficiency, gr.proficiency ]
    end
    diff['retired'] = [ true, false ] if recipe.retired?

    ingredients = line_diff(recipe.ingredients, gr.ingredients)
    diff['ingredients'] = ingredients if ingredients.any?
    results = line_diff(recipe.results, gr.results)
    diff['results'] = results if results.any?
    diff
  end

  # Compares site Ingredients/Results against game lines by item, giving
  # { 'added' => [[name, count]], 'removed' => [[name, count]],
  #   'changed' => [[name, from, to]] }, with empty keys left out.
  def line_diff(site_lines, game_lines)
    site = site_lines.to_h { |l| [ l.item_id, l ] }
    game = resolve_lines(game_lines).to_h { |id, line| [ id, line ] }

    added   = (game.keys - site.keys).map { |id| [ game[id].name, game[id].count ] }
    removed = (site.keys - game.keys).map { |id| [ site[id].item.name, site[id].count ] }
    changed = (site.keys & game.keys).filter_map do |id|
      [ game[id].name, site[id].count, game[id].count ] if site[id].count != game[id].count
    end
    { 'added' => added, 'removed' => removed, 'changed' => changed }.reject { |_, v| v.empty? }
  end

end
