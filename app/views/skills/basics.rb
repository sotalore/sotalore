# frozen_string_literal: true

class Views::Skills::Basics < Views::Skills::Base

  def view_template
    page_title("Skill Basics")

    div(class: "mb-12 mx-2 mt-2") do
      render Views::Skills::PageHeading.new(activity: nil, with_avatar_controls: false)

      div(class: "bg-white p-2 mb-8") do
        h3 { "What Skills Cost to Level" }

        div(class: "grid grid-cols-12 gap-4 md:gap-12") do
          div(class: "col-span-12 md:col-span-6") do
            p do
              plain "Raising skill levels costs "
              em { "Adventure" }
              plain " or "
              em { "Crafting" }
              plain " Experience (XP). The amount of XP required is exponential in nature, " \
                "causing higher-levels to cost considerably more than lower-levels."
            end

            p do
              plain "The chart below can help visualize the cost of raising skills. Change the "
              strong { "Max Skill Level" }
              plain " and "
              strong { "Factor Cost" }
              plain " to get an idea of the XP requirements to get a skill to a particular level."
            end
          end

          div(class: "col-span-12 md:col-span-6") do
            p do
              plain "Along with the base XP cost, each skill also has a "
              strong { "Factor Cost" }
              plain ". This is a simple multiplier to the calculated XP cost."
            end

            p do
              plain "Most skills have a "
              strong { "Factor Cost of 1" }
              plain ". This commonly applies to active skills (e.g., red, yellow, or blue glyphs)."
            end

            p do
              plain "Passive skills (i.e., grey glyphs) quite often have a "
              strong { "Factor Cost of 4" }
              plain "."
            end

            p do
              plain "Specializations and wardings (and a couple others) have a "
              strong { "Factor Cost of 20" }
              plain "."
            end

            p do
              plain "Check the "
              em { "Adventure" }
              plain " and "
              em { "Crafting" }
              plain " tabs above for the cost of each individual skill."
            end
          end
        end
      end

      div(id: "skillsBasics", class: "bg-white mb-8 p-2", data: { controller: "skills-basics" }) do
        div(class: "grid grid-cols-12 gap-4 md:gap-12") do
          div(class: "col-span-12 md:col-span-6") do
            strong { "Max Skill Level:" }
            whitespace
            input(type: "number", value: 200, data: { action: "skills-basics#setLevel", "skills-basics-target": "toLevel" })
          end
          div(class: "col-span-12 md:col-span-6") do
            strong { "Factor Cost:" }
            whitespace
            input(type: "number", value: 1, data: { action: "skills-basics#setLevel", "skills-basics-target": "xpFactor" })
          end
        end
        canvas(id: "skillBasicsChart")
      end

      div(class: "bg-white p-2 mb-8") do
        h3 { "Notes About Skill XP Math" }
        p do
          plain 'The calcuations used on this site differ from other tools I\'ve seen. A lot of ' \
            'other tools use a "lookup" table to calculate the total amount of XP for a particular ' \
            "skill level between 1 and 200. In my testing, some of these appeared to be inaccurate " \
            "(although, still very useful, as the inaccuracies are relatively small). So, instead, " \
            "I've chosen to use a function to calculate required XP. I'm convinced this function is " \
            "also slightly inaccurate, but close enough to be useful."
        end

        p do
          plain "That XP required function for a skill level is as follows (note that "
          em { "**" }
          plain " is the power operator)..."
        end

        pre(class: "pb-4 text-xs md:text-base") { "XP = (xpFactorValue * (Math.ceil(((1.099711**(level-1)) - 1) * 100)))" }
      end
    end
  end

end
