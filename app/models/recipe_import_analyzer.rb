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
#   name        - same name; when several site recipes share it, one with
#                 identical ingredients is preferred, then the same craft
#                 skill, then the oldest
#   ingredients - same craft skill and identical ingredients (recipe_key);
#                 catches recipes that were renamed
#   result      - the only recipe of the same craft skill making the same item
#
# Only recipes of the same kind (see Recipe::KINDS) match: a modification
# matches a modification, an archetype recipe ("Dagger") an archetype recipe.
# Template recipes ("Dagger Blade") are curated on the site and the game has
# no recipes making groups, so they're never matched except by an explicit
# game_id or manual link. When a game recipe's results aren't all known yet,
# its kind can't be told, so any kind but template may match.
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
    recipes = Recipe.preload(ingredients: :item, results: :item).to_a
    @recipes_by_id      = recipes.index_by(&:id)
    @kinds              = recipes.to_h { |r| [ r.id, r.kind ] }
    @game_kinds         = {}
    @recipes_by_game_id = recipes.select(&:game_id).index_by(&:game_id)
    @recipes_by_name    = recipes.group_by { |r| r.name.downcase }
    @recipes_by_key     = recipes.index_by(&:recipe_key)
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
    recipe && recipe.game_id.nil? && !@claimed.include?(recipe.id) && same_kind?(recipe, gr)
  end

  def same_kind?(recipe, gr)
    site = @kinds[recipe.id]
    return false if site == 'template'
    game = game_kind(gr)
    game.nil? || game == site
  end

  # The game recipe's kind as the site would see it (see Recipe#kind), or nil
  # while any of its results is unknown.
  def game_kind(gr)
    @game_kinds.fetch(gr.game_id) do
      @game_kinds[gr.game_id] =
        if gr.modification?
          'modification'
        else
          kinds = gr.results.map { @lookup.kind_for(_1.name) }
          if kinds.include?(nil) then nil
          elsif kinds.include?('group') then 'template'
          elsif kinds.any? { _1 != 'concrete' } then 'archetype'
          else 'concrete'
          end
        end
    end
  end

  def match_by_game_id(gr)
    recipe = @recipes_by_game_id[gr.game_id]
    recipe unless @claimed.include?(recipe&.id)
  end

  def match_by_name(gr)
    candidates = Array(@recipes_by_name[gr.name.downcase]).select { claimable?(_1, gr) }
    key = recipe_key_for(gr)
    identical = candidates.find { |r| key && r.recipe_key == key }
    return identical if identical
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

    unless gr.modification?
      groups = gr.results.map(&:name).select { @lookup.group?(_1) }
      if groups.any?
        problems << "Makes #{groups.join(', ')}, which the site has as a group; the game doesn't make " \
                    'groups. If which one you get depends on the ingredients, make it an archetype'
      end
    end

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
