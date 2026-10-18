require 'rails_helper'

RSpec.describe SkillCode do
  it 'reads the game ids and levels from the pages, in any order' do
    pages = skill_code_pages({ 131 => 100, 13_310 => 5, 470 => 120 }, per_page: 2)
    code = SkillCode.parse("Here you go:\n#{pages.reverse.join("\n\n")}\n")
    expect(code).to be_complete
    expect(code.character).to eq 'Gravidy'
    expect(code.page_count).to eq 2
    expect(code.levels).to eq(131 => 100, 470 => 120, 13_310 => 5)
  end

  it 'reads a code the plugin made' do
    # sl-skills 0.1.0's pages for a character's 338 trained skills.
    code = SkillCode.parse(file_fixture('skill-code.txt').read)
    expect(code).to be_complete
    expect(code.page_count).to eq 2
    expect(code.levels.size).to eq 338
    expect(code.levels.keys.map { Skill.find_by_game_id(_1) }).to all(be_present)
    expect(code.levels[1]).to eq 100 # Gust
  end

  it 'takes the offset off when the plugin added it' do
    code = SkillCode.parse(skill_code({ -5 => 10, 7 => 20 }))
    expect(code.levels).to eq(-5 => 10, 7 => 20)
  end

  it 'says which pages are missing' do
    pages = skill_code_pages({ 1 => 1, 2 => 2, 3 => 3 }, per_page: 1)
    code = SkillCode.parse(pages[1])
    expect(code).not_to be_complete
    expect(code.errors).to be_empty
    expect(code.missing_pages).to eq [ 1, 3 ]
  end

  it 'notices a page cut short' do
    page = skill_code({ 131 => 100, 470 => 120 })
    code = SkillCode.parse(page.sub(/(\|[0-9a-z]+)(\|[0-9a-z]{2})\z/) { "#{$1.chop}#{$2}" })
    expect(code.errors).to eq [ 'Page 1 didn\'t copy completely: copy it again.' ]
  end

  it 'won\'t put together pages from two codes' do
    first = skill_code_pages({ 1 => 1, 2 => 2 }, per_page: 1).first
    second = skill_code_pages({ 1 => 1, 2 => 2 }, per_page: 1, character: 'Someone Else').second
    expect(SkillCode.parse("#{first}\n#{second}").errors).to include(/different codes/)
  end

  it 'says when there is no code' do
    expect(SkillCode.parse('hello').errors).to eq [ 'There\'s no skill code there: it starts with SLS1.' ]
  end
end
