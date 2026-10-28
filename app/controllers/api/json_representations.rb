# frozen_string_literal: true

# How the API shows items, recipes and collections, so every endpoint
# describes them the same way. A "ref" is just enough to identify one and
# follow it up; a summary is what a list shows; detail is everything for one.
module Api::JsonRepresentations

  MAX_PER_PAGE = 100

  private

  def item_ref(item)
    { id: item.id, name: item.name, kind: item.kind }
  end

  def item_summary(item)
    item_ref(item).merge(
      use: item.use, source: item.source, weight: item.weight&.to_s('F'),
      ingredient_of: item.ingredients_count, made_by: item.results_count, url: item_url(item)
    )
  end

  # +tooltip_types+ are the type lines of the game's tooltips for it ("Leather
  # Light Armor (Head)", "Longsword - Bladed"), from item catalog imports;
  # +game_effects+ and +crafting_bonus+ come from the same tooltips (see
  # Item#game_effects). +sources+ and +roles+ are how it's obtained and what
  # it's used for, read from the site's records (see ItemSources, ItemRoles);
  # trust them over +use+ and +source+, which are old and set by hand.
  def item_detail(item)
    recipes = ->(scope) { scope.map { recipe_ref(_1) } }
    makers, modifiers = item.recipes.to_a.partition { !_1.modification? }
    item_summary(item).merge(
      value: item.value, merchant_price: item.merchant_price,
      effects: item.effects, notes: item.notes,
      game_effects: item.game_effects, crafting_bonus: item.crafting_bonus,
      aliases: item.aliases.map(&:name).sort,
      game_keys: item.game_keys.map { { key: _1.key, name: _1.name } },
      tooltip_types: item.game_keys.flat_map { Array(_1.catalog&.dig('details', 'types')) }.uniq,
      members: item.members.map { item_ref(_1) },
      member_of: item.groups.map { item_ref(_1) },
      collections: item.collections.map { collection_ref(_1) },
      made_by_recipes: recipes.(makers),
      modified_by_recipes: recipes.(modifiers),
      ingredient_of_recipes: recipes.(item.recipe_uses.distinct),
      sources: item_sources(ItemSources.new(item)),
      roles: item_roles(ItemRoles.new(item))
    )
  end

  # Not where it's found: finds are shown only to admins (see FindsPolicy).
  def item_sources(sources)
    {
      kinds: sources.kinds - [ :found ],
      crafting_skills: sources.crafting_skills.map(&:key),
      gathering_skills: sources.gathering_skills.map(&:key),
      salvaged_from: sources.salvaged_from.map { item_ref(_1) }
    }
  end

  def item_roles(roles)
    {
      kinds: roles.kinds,
      refining: roles.refining_counts.transform_keys(&:key),
      production: roles.production_counts.transform_keys(&:key),
      through: roles.through.map { item_ref(_1.group).merge(recipes: _1.count) }
    }
  end

  def collection_ref(collection)
    { id: collection.id, name: collection.name }
  end

  # The whole tree comes from +parents+ and +children+; +items+ counts only
  # those listed directly.
  def collection_summary(collection)
    collection_ref(collection).merge(
      description: collection.description,
      parents: collection.parents.map { collection_ref(_1) },
      children: collection.children.map { collection_ref(_1) },
      items: collection.collection_items.size, url: collection_url(collection)
    )
  end

  # +items+ are listed directly; +all_items+ adds those of everything
  # inside it, each with the collections it's listed in.
  def collection_detail(collection)
    collection_summary(collection).merge(
      items: collection.items.map { item_ref(_1).merge(use: _1.use) },
      all_items: collection.all_items.map do |item, listed_in|
        item_ref(item).merge(use: item.use, listed_in: listed_in.map { collection_ref(_1) })
      end
    )
  end

  def recipe_ref(recipe)
    { id: recipe.id, name: recipe.name, craft_skill: recipe.craft_skill&.key,
      retired: recipe.retired? }
  end

  def recipe_summary(recipe)
    recipe_ref(recipe).merge(
      kind: recipe.kind, proficiency: recipe.proficiency,
      game_id: recipe.game_id, game_synced_at: recipe.game_synced_at&.iso8601,
      retired_at: recipe.retired_at&.iso8601, last_verified_at: recipe.last_verified_at&.iso8601,
      ingredients: recipe.ingredients.map { line(_1) }, results: recipe.results.map { line(_1) },
      url: recipe_url(recipe)
    )
  end

  # Everything that helps decide whether a recipe belongs on the site.
  def recipe_detail(recipe, import: RecipeImport.latest_full)
    entry = import&.entries&.find_by(recipe_id: recipe.id)
    recipe_summary(recipe).merge(
      teachable: recipe.teachable,
      created_at: recipe.created_at.iso8601, updated_at: recipe.updated_at.iso8601,
      saved_by_users: recipe.user_recipes.count,
      comments: recipe.comments.message.count, revisions: recipe.comments.revision.count,
      same_name_recipes: Recipe.where('lower(name) = ?', recipe.name.downcase).where.not(id: recipe.id)
                               .map { recipe_ref(_1) },
      latest_full_import: import && {
        id: import.id, created_at: import.created_at.iso8601,
        entry: entry && { id: entry.id, name: entry.name, status: entry.status, match_method: entry.match_method },
      }
    )
  end

  def line(line)
    { item: item_ref(line.item), count: line.count }
  end

  def page_params
    page = [ params[:page].to_i, 1 ].max
    per = params[:per].to_i.clamp(1, MAX_PER_PAGE)
    per = 25 if params[:per].blank?
    [ page, per ]
  end

  # A page of +scope+ as { key => [...], page: {...} }, each mapped by +block+.
  def paged(key, scope, &block)
    page, per = page_params
    records = scope.page(page).per(per)
    { key => records.map(&block),
      page: { number: page, per: per, total_count: records.total_count, total_pages: records.total_pages } }
  end

  # Like #paged, for an Array.
  def paged_array(key, array, &block)
    page, per = page_params
    records = Kaminari.paginate_array(array).page(page).per(per)
    { key => records.map(&block),
      page: { number: page, per: per, total_count: records.total_count, total_pages: records.total_pages } }
  end

end
