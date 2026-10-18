# frozen_string_literal: true

# Builds skill codes the way the sl-skills plugin does (sl-lua/sl-skills/skills.lua).
module SkillCodeHelpers
  # +levels+ is { game id => level }; returns the pages, with +per_page+
  # skills on each.
  def skill_code_pages(levels, character: 'Gravidy', per_page: 200)
    offset = levels.keys.min.to_i.negative? ? SkillCode::OFFSET : 0
    id_digits = [ 3, (levels.keys.max + offset).to_s(36).length ].max
    chunks = levels.sort.each_slice(per_page).map do |slice|
      slice.map { |id, level| (id + offset).to_s(36).rjust(id_digits, '0') + level.to_s(36).rjust(2, '0') }.join
    end
    chunks = [ '' ] if chunks.empty?
    chunks.each_with_index.map do |entries, i|
      [ 'SLS1', "#{i + 1}/#{chunks.size}", id_digits, offset.zero? ? '-' : 'o', character, entries,
        SkillCode.check(entries) ].join('|')
    end
  end

  def skill_code(levels, **)
    skill_code_pages(levels, **).join("\n")
  end
end

RSpec.configure do |config|
  config.include SkillCodeHelpers
end
