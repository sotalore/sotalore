# frozen_string_literal: true

# The materials, with what the site records about each (see ItemSources,
# ItemRoles) next to what's stored on it by hand, and where the two
# disagree, for an editor to fix one item at a time.
#
# Covers anything a refining recipe that feeds production takes or makes
# (see Materials.refining_recipes), more than the materials themselves, so
# the raw goods and forms are checked too.
class MaterialTriage

  # A stored value that disagrees with the evidence. +fix+ is the value the
  # evidence suggests for +field+ (nil to clear it), when it suggests one. A
  # +note+ is a stored value nothing confirms, which may still be right:
  # finds don't cover every scene, or fishing.
  Issue = Data.define(:field, :message, :fix, :fix_label, :note) do
    def initialize(field:, message:, fix: nil, fix_label: nil, note: false) = super
    def fixable? = !fix_label.nil?
  end

  # An item: under the refining +skill+ that makes it, else the first that
  # takes it.
  Row = Data.define(:item, :skill, :sources, :roles, :issues) do
    def tool_or_fuel? = roles.tool? || item.use_is_tool? || item.use_is_fuel?
  end

  # The stored source each kind of evidence suggests, and the reverse.
  SOURCE_FOR = { crafted: 'recipe', gathered: 'gathering', salvaged: 'salvage', bought: 'merchant', found: 'drop' }.freeze
  # Stored sources the evidence can't speak to.
  UNCHECKED_SOURCES = %w[ agriculture quest ].freeze
  # Gathering skills finds imports don't record (no node is fished).
  UNRECORDED_SKILLS = %w[ fishing ].freeze

  def self.refining_skills
    CraftSkill::ALL.select { _1.category_key == 'refining' }
  end

  def rows
    @rows ||= Item.where(id: material_ids).includes(:game_keys).order(:name).map { row_for(_1) }
  end

  # Rows with something to fix, not just notes.
  def with_issues = rows.select { |row| row.issues.any? { !_1.note } }

  # { CraftSkill => rows }, in skill order, tools and fuel left out.
  def by_skill(rows = self.rows)
    grouped = rows.reject(&:tool_or_fuel?).group_by(&:skill)
    self.class.refining_skills.filter_map { |skill| [ skill, grouped[skill] ] if grouped[skill] }.to_h
  end

  # The tools and fuel among +rows+.
  def tools_and_fuel(rows = self.rows) = rows.select(&:tool_or_fuel?)

  private

  def row_for(item)
    sources = ItemSources.new(item)
    roles = ItemRoles.new(item)
    Row.new(item, skill_for(item), sources, roles, issues(item, sources, roles))
  end

  def skill_for(item)
    making = feeding_recipes.select { |r| r.results.any? { _1.item_id == item.id } }
    taking = feeding_recipes.select { |r| r.ingredients.any? { _1.item_id == item.id } }
    (making.first || taking.first).craft_skill
  end

  def issues(item, sources, roles)
    gathering_issues(item, sources) + source_issues(item, sources) + use_issues(item, roles)
  end

  def gathering_issues(item, sources)
    stored = item.gathering_skill
    found = sources.gathering_skills
    issues = sources.unskilled_nodes.map do |node|
      Issue.new(field: :node, message: "#{node.name} yields it, but has no gathering skill yet.")
    end
    if found.any? && !found.include?(stored)
      suggestion = found.one? ? found.first : nil
      said = stored ? "Stored as #{stored.name}" : 'No gathering skill stored'
      issues << Issue.new(field: :gathering_skill, message: "#{said}; finds say #{found.map(&:name).to_sentence}.",
                          fix: suggestion&.key, fix_label: suggestion && "Set #{suggestion.name}")
    elsif stored && found.empty? && sources.crafted?
      issues << Issue.new(field: :gathering_skill,
                          message: "Stored as #{stored.name}, but a recipe makes it and no finds say it's gathered.",
                          fix_label: 'Clear it')
    end
    issues
  end

  def source_issues(item, sources)
    stored = item.source
    return [] if UNCHECKED_SOURCES.include?(stored)
    return [] if stored == 'gathering' && UNRECORDED_SKILLS.include?(item.gathering_skill&.key)

    kinds = sources.kinds
    return [] if kinds.any? { SOURCE_FOR[_1] == stored }

    if kinds.empty?
      return [] if stored == 'unknown'
      return [ Issue.new(field: :source, message: "Source is #{stored}, which nothing records yet.", note: true) ]
    end

    suggestion = SOURCE_FOR[kinds.first]
    said = stored == 'unknown' ? 'Source is unknown' : "Source is #{stored}, which nothing records"
    [ Issue.new(field: :source, message: "#{said}; it's #{kinds.to_sentence}.", fix: suggestion, fix_label: "Set #{suggestion}") ]
  end

  def use_issues(item, roles)
    return [] unless roles.tool? && !item.use_is_tool?
    [ Issue.new(field: :use, message: "Use is #{item.use}, but its tooltip says it's a tool.", fix: 'tool', fix_label: 'Set tool') ]
  end

  def material_ids
    feeding_recipes.flat_map { |r| r.ingredients.map(&:item_id) + r.results.map(&:item_id) }.uniq
  end

  # The refining recipes that feed production (see Materials.refining_recipes).
  def feeding_recipes
    @feeding_recipes ||= Materials.refining_recipes
  end
end
