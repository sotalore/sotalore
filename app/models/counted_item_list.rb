# frozen-string-literal: true

class CountedItemList

  attr_reader :added

  class CountedItem

    attr_reader :name, :count

    def initialize(name, count)
      @name, @count = name, count
    end

    def ==(other)
      other.class == self.class && other.name == name
    end
    alias_method :eql?, :==

    def hash
      name.hash
    end

    def as_json
      [ name, count ]
    end
  end

  def initialize(initial)
    @initial = build_counted_list(Array(initial))
  end

  def compare_to(others)
    @others = build_counted_list(Array(others))
  end

  def added
    @others - @initial
  end

  def removed
    @initial - @others
  end

  def changes
    @initial.map do |from|
      if to = @others.find { |i| from.name == i.name }
        if from.count != to.count
          [from, to]
        end
      end
    end.compact
  end

  def as_json
    {
      added: added.as_json,
      removed: removed.as_json,
      changes: changes.inject({}) { |m,(from,to)|
        m[from.name] = [from.count, to.count]
        m
      }
    }.reject { |k,v| v.blank? }
  end

  private
  def build_counted_list(items)
    items.map do |i|
      CountedItem.new(i.name, i.count)
    end
  end

end
