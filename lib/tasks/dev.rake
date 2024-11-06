namespace :dev do

  task icons: :environment do
    HeroIconHelper::ICONS.each do |icon, svg|
      filename = Rails.root.join('app', 'components', 'icons', "#{icon}.rb")
      markup = [
        "MARKUP = <<~HTML",
        svg.split("\n").map { |line| "    #{line}" }.join("\n"),
        "  HTML"
      ]
      File.open(filename, 'w') do |file|
        file.puts <<~RUBY
          # frozen_string_literal: true

          class Components::Icons::#{icon.camelize} < Components::Icons::Base

            #{markup.join("\n")}

          end
        RUBY
      end
      print "."
    end
    puts
  end
end