# frozen-string-literal: true

class Planting < ApplicationRecord

  enum :location_type, [ :outdoor, :greenhouse, :indoor ], scopes: false

  LOCATION_TYPE_FACTORS = {
    outdoor: 1.0,
    greenhouse: 2.0,
    indoor: 0.1,
  }.with_indifferent_access

  belongs_to :user, inverse_of: :plantings
  belongs_to :seed, class_name: 'Item'

  validates :seed, :planted_at, presence: :true
  validate :seed_is_a_seed

  def self.with_defaults
    new(planted_at: I18n.l(Time.zone.now, format: :watering_step))
  end

  WATERING_STEPS = 3
  def plan_steps
    WATERING_STEPS.times.map do |idx|
      begins = (idx) * total_growing_time
      ends   = (idx + 1) * total_growing_time
      [ planted_at + begins.hours, planted_at + ends.hours]
    end
  end

  def location_type_factor
    LOCATION_TYPE_FACTORS.fetch(location_type, 1.0)
  end

  def single_step_time
    total_growing_time / WATERING_STEPS
  end

  def total_growing_time
    case seed.price
    when 16..29
      48 / location_type_factor
    when 30..1000
      72 / location_type_factor
    else
      24 / location_type_factor
    end
  end

  def step_end_times
    WATERING_STEPS.times.map { |i| planted_at + ((i+1) * single_step_time.hours) }
  end

  def days_of_growing
    start = planted_at.to_date
    total_calendar_days.times.map do
      start.tap { |d| start = d.next }
    end
  end

  def buffer_width
    total = total_calendar_days.days.to_i
    buffer_time = (planted_at - planted_at.beginning_of_day).to_i
    ((buffer_time * 100) / total)
  end

  def step_width
    ((single_step_time / (total_calendar_days * 24).to_f) * 100).to_i
  end

  def total_calendar_days
    finished = planted_at + total_growing_time.hours
    (finished.to_date - planted_at.to_date).to_i + 1
  end

  private
  def seed_is_a_seed
    return unless seed
    unless seed.use_is_seed?
      errors.add(:seed, 'must be a seed')
    end
  end
end
