require 'csv'

namespace :skills do
  # The game's skill ids and internal names come from the development team's
  # data/skill-costs.csv ("Skill ID", "Internal Name"); they're the same ids and
  # keys the sl-skills plugin exports. This matches each CSV row to a site skill
  # by school and name, and writes game_id and game_key into the skills JSON.
  desc "Fill skills' game_id and game_key from data/skill-costs.csv"
  task game_ids: :environment do
    school_names = { 'polearms' => 'polearm', 'moon' => 'lunar' } # the CSV's name => the site's
    norm = ->(name) { name.to_s.downcase.gsub(/[^a-z0-9]/, '') }

    rows = CSV.read(Rails.root.join('data/skill-costs.csv'), headers: true).index_by do |row|
      school = norm[row['School']]
      [ school_names.fetch(school, school), norm[row['Skill Name']] ]
    end
    used = []
    missing = []

    %w[ adventuring crafting ].each do |file|
      path = Rails.root.join("app/models/skills-#{file}.json")
      data = JSON.parse(File.read(path))
      data.each_value do |schools|
        schools.each do |school, skills|
          skills.each do |skill|
            row = rows[[ norm[school], norm[skill['name']] ]]
            next missing << skill['key'] unless row
            skill['game_id'] = Integer(row['Skill ID'])
            skill['game_key'] = row['Internal Name']
            used << row
          end
        end
      end
      File.write(path, "#{JSON.pretty_generate(data)}\n")
    end

    puts "Matched #{used.size} skills."
    puts "Site skills not in the CSV: #{missing.join(', ')}" if missing.any?
    unused = rows.values - used
    puts "CSV skills not on the site: #{unused.map { "#{_1['School']}/#{_1['Skill Name']}" }.join(', ')}" if unused.any?
  end
end
