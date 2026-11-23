namespace :skills do
  # Where sl-admin writes sotalore-game-skills.json on peregrin (the Windows
  # machine the game runs on), relative to the ssh user's home: each game
  # client has its own Lua folder.
  FETCH_HOST = 'peregrin'
  FETCH_CLIENTS = {
    'regular' => 'AppData/Roaming/Catnip Games/Shroud of the Avatar/Lua',
    'qa' => 'AppData/Roaming/Catnip Games/Shroud of the Avatar(DEV)/Lua',
  }.freeze

  # Copies the game's list of every skill from peregrin over ssh (Host
  # peregrin in ~/.ssh/config) over the example skills:sync reads, after
  # checking it's a game-skills file. Development only:
  #   rails skills:fetch          # the regular client's
  #   rails 'skills:fetch[qa]'    # the QA client's
  desc 'Copy sotalore-game-skills.json from peregrin over the example, for skills:sync'
  task :fetch, [ :client ] => :environment do |_, args|
    abort 'skills:fetch is for development: it copies a file into the app over ssh.' unless Rails.env.development?
    client = args[:client].presence || 'regular'
    folder = FETCH_CLIENTS.fetch(client) { abort "Unknown client #{client}: use #{FETCH_CLIENTS.keys.join(' or ')}." }

    Dir.mktmpdir do |dir|
      copy = File.join(dir, 'sotalore-game-skills.json')
      unless system('scp', '-q', '-o', 'BatchMode=yes', "#{FETCH_HOST}:#{folder}/sotalore-game-skills.json", copy)
        abort "Couldn't copy it from #{FETCH_HOST} (#{folder}). Has /sladmin gameskills been run in that client?"
      end
      data = JSON.parse(File.read(copy, encoding: 'bom|utf-8'))
      abort %(That isn't a game-skills file (type #{data['type'].inspect}).) unless data['type'] == 'gameSkills'

      FileUtils.cp(copy, Rails.root.join('spec/fixtures/plugin-examples/sotalore-game-skills.json'))
      puts "Fetched #{data['skills'].size} skills from the #{client} client " \
           "(#{data['plugin']} #{data['pluginVersion']}, game API #{data['apiVersion']}). Now run rails skills:sync."
    end
  end

  # The game's list comes from the plugin's /sladmin gameskills
  # (rails skills:fetch copies it from peregrin). Copy a new
  # sotalore-game-skills.json over the example, or pass its path:
  #   rails 'skills:sync[path/to/sotalore-game-skills.json]'
  desc 'Bring the skills JSON in step with the plugin\'s list of every skill in the game'
  task :sync, [ :path ] => :environment do |_, args|
    source = args[:path] || Rails.root.join('spec/fixtures/plugin-examples/sotalore-game-skills.json')
    game_skills = JSON.parse(File.read(source, encoding: 'bom|utf-8')).fetch('skills')
    paths = GameSkillSync::FILES.keys.index_with { Rails.root.join("app/models/skills-#{_1}.json") }
    lists = paths.transform_values { JSON.parse(File.read(_1)) }

    result = GameSkillSync.new(game_skills, lists).call
    paths.each { |name, path| File.write(path, "#{JSON.pretty_generate(lists[name])}\n") } if result.changed?

    puts "Added: #{result.added.join('; ')}" if result.added.any?
    puts "Updated: #{result.updated.join('; ')}" if result.updated.any?
    puts "In another school, not changed: #{result.moved.join('; ')}" if result.moved.any?
    if result.removed.any?
      puts "Removed, not in the game any more: #{result.removed.join('; ')}"
      puts 'Copy db/migrate/20261107120000_clear_removed_skills.rb so the release clears their levels.'
    end
    puts 'Already in step.' unless result.changed? || result.moved.any?
  end
end
