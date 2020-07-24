#!/usr/bin/env ruby

require 'time'

epoch = Time.parse("January 1, 2013 00:00:00 -0000")

def minutes_and_seconds(i)
  s = i % 60
  m = (i - s) / 60
  "%02d:%02d" % [ m, s]
end

# 8:45 per lunar "cycle"
def single_duration
  (8 * 60) + 45
end

LOCATIONS = [
  'Blood River',
  'Solace Bridge',
  'Highvale',
  'Brookside',
  "Owl's Head",
  'Westend',
  'Brittany Graveyard',
  'Etceter'
]
name_width = LOCATIONS.map(&:length).max

def full_cycle
  single_duration * LOCATIONS.length
end


def where_is(idx, elapsed)
  end_time = (idx * single_duration)
  beg_time = (idx * single_duration) - single_duration
  if elapsed >= beg_time && elapsed < end_time
    # active
    -(end_time - elapsed)
  elsif elapsed < beg_time
    # in this cycle, but later
    beg_time - elapsed
  else
    # in next cycle
    full_cycle - elapsed + beg_time
  end
end

while true
  total_elapsed = Time.now.utc.to_i - epoch.to_i
  # the number of seconds "elapsed" in this cycle
  elapsed = total_elapsed % full_cycle

  LOCATIONS.each_with_index do |loc, i|
    w = where_is(i + 1, elapsed)
    if w < 0
      puts("%#{name_width}s: %s active" % [ loc, minutes_and_seconds(-w) ])
    else
      puts("%#{name_width}s: %s" % [ loc, minutes_and_seconds(w) ])
    end
  end
  sleep(1)
  puts
end
