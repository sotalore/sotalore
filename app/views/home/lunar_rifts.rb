# frozen_string_literal: true

class Views::Home::LunarRifts < Views::Base

  RIFTS = [
    { name: 'Blood River', style: ['bottom: 28%', 'left: 10%'] },
    { name: 'Solace Bridge', style: ['bottom: 17%', 'right: 22%'] },
    { name: 'Highvale', style: ['bottom: 40%', 'left: 25%'] },
    { name: 'Brookside', style: ['top: 45%', 'right: 20%'] },
    { name: "Owl's Head", style: ['top: 5%', 'right: 15%'] },
    { name: 'Westend', style: ['bottom: 40%', 'left: 4%'] },
    { name: 'Brittany<br>Graveyard', style: ['bottom: 40%', 'right: 45%'] },
    { name: 'Etceter', style: ['bottom: 15%', 'left: 28%'] }
  ]

  def view_template
    div(class: 'text-xs p-4 relative text-center text-white', data: { controller: 'lunar-rift' }) do
      img(src: asset_path('sota-map-overland.png'), class: 'w-full rounded-xl')
      RIFTS.each_with_index do |rift, index|
        div(class: "p-1 absolute bg-black/50", style: rift[:style], data: { 'lunar-rift-target': 'rift', index: index + 1 }) do
          raw(safe(rift[:name]))
          div { 'XX:XX' }
        end
      end
    end
  end

end
