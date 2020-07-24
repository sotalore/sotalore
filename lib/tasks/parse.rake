namespace :parse do

  task setup: :environment do
    file = ENV['FILE'] or raise "Must provide FILE=<file_to_parse>"
    @parser = Info::Parser.for_file(file)
  end

  desc "Load tools from data input file"
  task load_tools: :setup do
    @parser.load_tools
    puts
  end

  desc "Load gatherables from data input file"
  task load_gatherables: :setup do
    @parser.load_gatherables
    puts
  end

  desc "Load recipe output from data input file"
  task load_recipe_output: :setup do
    @parser.load_recipe_output
    puts
  end

  desc "Load ingredients from data input file"
  task load_ingredients: :setup do
    @parser.load_ingredients
    puts
  end

  desc "Load recipes from data input file"
  task load_recipes: :setup do
    @parser.load_recipes
    puts
  end

  task load_all: [ :load_tools, :load_gatherables, :load_recipe_output, :load_ingredients, :load_recipes ]

end

task parse: "parse:load_all"
