namespace :skills do
  # The game's list comes from the plugin's /sladmin gameskills. Copy a new
  # sotalore-game-skills.json over the example, or pass its path:
  #   rails 'skills:sync[path/to/sotalore-game-skills.json]'
  desc 'Bring the skills JSON in step with the plugin\'s list of every skill in the game'
  task :sync, [ :path ] => :environment do |_, args|
    source = args[:path] || Rails.root.join('data/plugin-examples/sotalore-game-skills.json')
    game_skills = JSON.parse(File.read(source, encoding: 'bom|utf-8')).fetch('skills')
    paths = GameSkillSync::FILES.keys.index_with { Rails.root.join("app/models/skills-#{_1}.json") }
    lists = paths.transform_values { JSON.parse(File.read(_1)) }

    result = GameSkillSync.new(game_skills, lists).call
    paths.each { |name, path| File.write(path, "#{JSON.pretty_generate(lists[name])}\n") } if result.changed?

    puts "Added: #{result.added.join('; ')}" if result.added.any?
    puts "Updated: #{result.updated.join('; ')}" if result.updated.any?
    puts "In another school, not changed: #{result.moved.join('; ')}" if result.moved.any?
    puts "Not in the game any more, not removed: #{result.gone.join('; ')}" if result.gone.any?
    puts 'Already in step.' unless result.changed? || result.moved.any? || result.gone.any?
  end
end
