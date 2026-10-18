# frozen_string_literal: true

# The skill code the sl-skills plugin shows for a player to paste in (see
# sl-lua/EXPORT-FORMAT.md): one or more pages, in any order, each
#
#   SLS1|<page>/<pages>|<id digits>|<o or ->|<character>|<entries>|<check>
#
# where the entries are the trained skills' game ids and levels in base 36,
# and the check catches a page cut short. Anything around the pages (the
# player's own text, line breaks) is ignored.
#
#   code = SkillCode.parse(text)
#   code.complete?  # => all pages there and readable
#   code.levels     # => { 131 => 100, ... } game id => trained level
class SkillCode

  TAG = 'SLS1'
  OFFSET = 2_147_483_648 # added to every id when the "o" flag is set
  LEVEL_DIGITS = 2
  PAGE = /#{TAG}\|(\d+)\/(\d+)\|(\d+)\|([o-])\|([^|]*)\|([0-9a-z]*)\|([0-9a-z]{2})/

  Page = Data.define(:number, :pages, :id_digits, :offset, :character, :entries)

  attr_reader :errors

  def self.parse(text)
    new(text.to_s)
  end

  # The check the plugin puts on each page.
  def self.check(entries)
    entries.each_byte.reduce(0) { |sum, b| (sum * 31 + b) % 1296 }.to_s(36).rjust(2, '0')
  end

  def initialize(text)
    @errors = []
    @pages = {}
    text.scan(PAGE) { add_page(*Regexp.last_match.captures) }
    @errors << 'There\'s no skill code there: it starts with SLS1.' if @pages.empty? && @errors.empty?
    check_pages_agree
  end

  def complete?
    errors.empty? && missing_pages.empty?
  end

  def page_count
    @pages.values.first&.pages || 0
  end

  def missing_pages
    (1..page_count).to_a - @pages.keys
  end

  def character
    @pages.values.first&.character
  end

  # Game id => trained level, for every skill on the pages read.
  def levels
    @levels ||= @pages.values.sort_by(&:number).each_with_object({}) do |page, levels|
      width = page.id_digits + LEVEL_DIGITS
      page.entries.scan(/.{#{width}}/).each do |entry|
        id = entry[0, page.id_digits].to_i(36) - page.offset
        levels[id] = entry[page.id_digits, LEVEL_DIGITS].to_i(36)
      end
    end
  end

  private

  def add_page(number, pages, id_digits, offset, character, entries, check)
    number, pages, id_digits = number.to_i, pages.to_i, id_digits.to_i
    if self.class.check(entries) != check
      @errors << "Page #{number} didn't copy completely: copy it again."
    elsif id_digits < 1 || (entries.length % (id_digits + LEVEL_DIGITS)).nonzero?
      @errors << "Page #{number} isn't a skill code this site can read."
    elsif number < 1 || number > pages
      @errors << "There's no page #{number} of #{pages}."
    else
      @pages[number] = Page.new(number, pages, id_digits, offset == 'o' ? OFFSET : 0, character, entries)
    end
  end

  # Pages from two different codes (another character, or after a level went
  # up and the pages were made again) can't be put together.
  def check_pages_agree
    shapes = @pages.values.map { [ _1.pages, _1.id_digits, _1.offset, _1.character ] }.uniq
    @errors << 'Those pages are from different codes: copy them all again from the game.' if shapes.size > 1
  end

end
