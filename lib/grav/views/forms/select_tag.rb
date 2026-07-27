# frozen_string_literal: true

class Grav::Views::Forms::SelectTag < Phlex::HTML

  def initialize(id:, name:, selected: nil, **options)
    @id = id
    @name = name
    @selected = case selected
    when Array
      selected.map(&:to_s)
    else
      selected.to_s
    end
    @options = options
  end

  def options(collection, display:, value:, include_blank: false)
    self.collection(collection)
    self.display_method(display)
    self.value_method(value)
    self.include_blank(include_blank) if include_blank
  end

  def collection(collection)
    @collection = collection
  end

  def match_selected_with(selected)
    @match_selected_with = selected
  end

  def display_method(display_method=nil, &block)
    raise "Provide one of display_method or a block" if display_method && block

    @display_method = display_method || block
  end

  def value_method(value_method=nil, &block)
    raise "Provide one of value_method or a block" if value_method && block

    @value_method = value_method || block
  end

  def include_blank(strategy=:blank)
    case strategy
    when :blank
      @include_blank = ''
    when :select_one
      @include_blank = '-- Select One --'
    when :none
      @include_blank = '-- None --'
    when String
      @include_blank = strategy
    else
      raise "Invalid include_blank strategy: #{strategy}"
    end
  end

  def view_template
    yield self if block_given?
    css = [ 'form-input', @options.delete(:class) ]
    select(id: @id, name: @name, class: css, **@options) do
      option_tag('', @include_blank, selected?(value: '')) if @include_blank
      @collection.each { |item| option_tag_from_item(item) }
    end
  end

  private

  def selected?(value: nil, item: nil)
    return @match_selected_with == item if @match_selected_with.present?
    return true if value.blank? && @selected.blank?

    case @selected
    when Array
      @selected.include?(value)
    else
      @selected == value
    end
  end

  def option_tag_from_item(item)
    value = from_option_item(item, @value_method)
    display = from_option_item(item, @display_method)
    option_tag(value, display, selected?(value: value, item: item))
  end

  def option_tag(value, display, selected)
    if selected
      option(value: value, selected: '') { display }
    else
      option(value: value) { display }
    end
  end

  def from_option_item(item, method)
    if method.respond_to?(:call)
      method.call(item)
    else
      item.send(method)
    end
  end

end
