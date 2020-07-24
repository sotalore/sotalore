namespace :heroku do

  task :heroku_command_line_client do
    unless `which heroku`
      abort "Please install the heroku toolbelt or command line client"
    end
  end

  task :heroku_application do
    ENV['HEROKU_APPLICATION'] ||= 'sota-stuff'
  end

  def heroku_app
    ENV['HEROKU_APPLICATION']
  end

  task heroku_remote: :heroku_application do
    git_remote = `git remote -v | grep -e 'git[.@]heroku.com.*[:/]#{heroku_app}.git (push)' | cut -f 1`.strip
    abort('Unable to determine heroku remote') if git_remote == ''
    ENV['HEROKU_REMOTE'] = git_remote
  end

  def heroku_remote
    ENV['HEROKU_REMOTE']
  end

  task setup: [ :heroku_command_line_client, :heroku_remote ]

  desc "Push current branch to heroku"
  task push: :setup do
    current_branch = `git branch | grep '*' | cut -d ' ' -f 2`.strip

    puts "** Fetching latest from #{heroku_remote}"
    `git fetch #{heroku_remote}`

    current_sha = `git rev-parse #{heroku_remote}/master`.strip
    next_sha    = `git rev-parse #{current_branch}`.strip

    puts "***** DEPLOYING #{current_branch} TO #{heroku_app} *****"

    migrate = false
    unless system("git diff --quiet #{current_sha} #{next_sha}  db/migrate")
      puts "  ===== THIS DEPLOYMENT INCLUDES THESE MIGRATIONS"
      system("git diff --stat #{current_sha} #{next_sha} db/migrate")
      puts
      migrate = true
    end

    querying = true
    while querying
      print "  Are you sure (ydlN)? "
      reply = STDIN.gets.strip

      puts ""

      case reply
      when 'y'
        querying = false
      when 'd'
        sh "git diff #{current_sha} #{next_sha}"
      when 'l'
        sh "git log --graph --pretty=oneline --abbrev-commit --date=relative #{current_sha}..#{next_sha}"
      else
        abort "Exiting..."
      end
    end

    url = "https://gitlab.com/sota-stuff/sota-stuff/compare?from=#{current_sha}&to=#{next_sha}"
    user = ENV['USER']

    git_command  = 'push'
    git_command << ' --force' if ENV['FORCE'].present?
    sh "git #{git_command} #{heroku_remote} #{current_branch}:master"

    msg = "*#{user} has deployed #{current_branch} to #{heroku_app}"
    if migrate
      msg << ", with migrations"
    end
    msg << ". See <#{url}|the deploy diff>.*"

    if migrate
      heroku "run rake db:migrate -r #{heroku_remote}"
      heroku "restart -r #{heroku_remote}"
    end

    puts msg
  end

  desc "Run migrations on Heroku"
  task migrate: :setup do
    heroku "run rake db:migrate -r #{heroku_remote}"
  end

  desc "Restart dynos on Heroku"
  task restart: :setup do
    heroku "restart --app #{heroku_app}"
  end

  namespace :maintenance do
    desc "Enable maintenance mode on Heroku"
    task on: :setup do
      heroku "maintenance:on --app #{heroku_app}"
    end

    desc "Put application on Heroku into maintenance mode"
    desc "Disable maintenance mode on Heroku"
    task off: :setup do
      heroku "maintenance:off --app #{heroku_app}"
    end
  end

  desc "Ping Heroku application"
  task ping: :setup do
    url = "https://#{heroku_app}.herokuapp.com/"
    puts "Pinging #{heroku_remote} at #{url}"
    sh "curl -I #{url}"
  end

  def heroku(cmd)
    Bundler.with_clean_env do
      sh "heroku #{cmd}"
    end
  end

end
