# frozen_string_literal: true

class Views::Home::MasterTrainers < Views::Base

  TRAINERS = {
    'skill-icons/combat_shield.png' => [ 'bottom: 3%', 'right: 34%' ],
    'skill-icons/combat_polearm.png' => [ 'bottom: 27%', 'left: 26%' ],
    'skill-icons/combat_blades.png' => [ 'bottom: 5%', 'right: 32%' ],
    'skill-icons/combat_heavy_armor.png' => [ 'top: 4%', 'right: 20%' ],
    'skill-icons/combat_light_armor.png' => [ 'bottom: 14%', 'right: 36%' ],
    'skill-icons/combat_bludgeon.png' => [ 'bottom: 12%', 'left: 26%' ],
    'skill-icons/combat_ranged.png' => [ 'bottom: 10%', 'right: 22%' ],
    'skill-icons/magic_sun.png' => [ 'bottom: 30%', 'right: 28%' ],
    'skill-icons/magic_fire.png' => [ 'bottom: 29%', 'right: 26%' ],
    'skill-icons/magic_earth.png' => [ 'bottom: 29%', 'left: 28%' ],
    'skill-icons/magic_death.png' => [ 'bottom: 6%', 'left: 43%' ],
    'skill-icons/magic_chaos.png' => [ 'bottom: 13%', 'left: 29%' ],
    'skill-icons/magic_life.png' => [ 'bottom: 4%', 'right: 29%' ],
    'skill-icons/magic_air.png' => [ 'top: 15%', 'right: 10%' ],
    'skill-icons/magic_water.png' => [ 'bottom: 1%', 'right: 30%' ],
    'skill-icons/magic_lunar.png' => [ 'top: 12%', 'right: 14%' ],
    'skill-icons/strategy_tactics.png' => [ 'bottom: 27%', 'right: 27%' ],
    'skill-icons/strategy_subterfuge.png' => [ 'bottom: 1%', 'right: 33%' ],
    'skill-icons/strategy_bard.png' => [ 'top: 15%', 'left: 30%' ],
    'skill-icons/strategy_taming.png' => [ 'top: 24%', 'right: 17%' ],
    'skill-icons/strategy_focus.png' => [ 'top: 5%', 'right: 18%' ],
  }


  def view_template
    div(class: 'p-2') do
      more_info

      div(class: 'relative') do
        img(src: asset_path('sota-map-overland.png'), class: 'w-full rounded-xl')
        TRAINERS.each do |icon, position|
          div(class: "p-[5px] absolute", style: position) do
            img(src: asset_path(icon), class: 'w-10')
          end
        end
      end
    end
  end

  def more_info
    tile(:info) do
      tile_body do
        p do
          plain "For more details, see this "
          a(href: 'https://sotawiki.net/sota/Master_Trainer') {'SotA wiki article'}
          plain "."
        end
      end
    end
  end
end
