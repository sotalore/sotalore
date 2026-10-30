# frozen_string_literal: true

# Brings the site's skill lists (skills-adventuring.json and
# skills-crafting.json, as parsed JSON) in step with the plugin's list of every
# skill in the game (see sl-lua/EXPORT-FORMAT.md), matching on the game's id.
# New skills are added at the end of their school; names, internal names and
# XP factors are updated. A skill's site key and id never change, because
# players' levels and hidden skills are stored by them, so a skill that moved
# school or left the game is only reported.
class GameSkillSync

  FILES = { 'adventuring' => %w[ combat magic strategy ], 'crafting' => %w[ gathering refining production ] }.freeze
  SCHOOLS = { 'polearms' => 'polearm', 'moon' => 'lunar' }.freeze # the game's name => the site's

  Result = Data.define(:added, :updated, :moved, :gone) do
    def changed? = added.any? || updated.any?
  end

  # +lists+ is { 'adventuring' => data, 'crafting' => data }, changed in place.
  def initialize(game_skills, lists)
    @game_skills = game_skills
    @lists = lists
  end

  def call
    added, updated, moved = [], [], []
    site = site_skills
    @game_skills.each do |game|
      category, school = place(game)
      if (found = site[game['id']])
        changes = update(found[:skill], game)
        updated << "#{found[:skill]['name']}: #{changes.join(', ')}" if changes.any?
        moved << "#{game['name']}: #{found[:school]} to #{school}" if found[:school] != school
      else
        added << add(game, category, school)
      end
    end
    game_ids = @game_skills.map { _1['id'] }
    gone = site.reject { |id, _| game_ids.include?(id) }.values.map { _1[:skill]['name'] }
    Result.new(added, updated, moved, gone)
  end

  private

  def site_skills
    @lists.values.flat_map do |list|
      list.values.flat_map do |schools|
        schools.flat_map { |school, skills| skills.map { { skill: _1, school: school } } }
      end
    end.index_by { _1[:skill]['game_id'] }
  end

  # The site's category and school for a game skill.
  def place(game)
    school = game['school'].downcase
    [ game['subcategory'].downcase, SCHOOLS.fetch(school, school) ]
  end

  def update(skill, game)
    { 'name' => game['name'], 'game_key' => game['key'], 'xp_factor' => game['xpMultiplier'].to_f }.filter_map do |field, value|
      next if skill[field] == value
      change = "#{field} #{skill[field].inspect} to #{value.inspect}"
      skill[field] = value
      change
    end
  end

  def add(game, category, school)
    list_name, = FILES.find { |_, categories| categories.include?(category) }
    raise ArgumentError, "#{game['name']} is in an unknown category: #{game['subcategory']}" unless list_name
    list = @lists.fetch(list_name)
    ((list[category] ||= {})[school] ||= []) << {
      'name' => game['name'], 'xp_factor' => game['xpMultiplier'].to_f,
      'key' => "#{category}~#{school.parameterize}~#{game['name'].parameterize}", 'id' => next_id(list),
      'game_id' => game['id'], 'game_key' => game['key']
    }
    "#{game['name']} (#{school})"
  end

  def next_id(list)
    list.values.flat_map(&:values).flatten.map { _1['id'] }.max + 1
  end

end
