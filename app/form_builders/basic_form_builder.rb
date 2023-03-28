class BasicFormBuilder < ActionView::Helpers::FormBuilder
  delegate :content_tag, to: :@template
  delegate :capture,     to: :@template

  def group(method=nil, options={}, &block)
    form_group(method, options, &block)
  end

  alias :base_submit :submit
  def submit(value  = nil, options={})
    get_button_css_class(options)
    super(value, options)
  end

  def button(label, options={})
    get_button_css_class(options)
    super(label, options)
  end

  def cancel(label, path, options={})
    @template.cancel_button_to(label, path, options)
  end

  alias :base_label :label
  def label(method, text=nil, options={}, &block)
    options[:class] = label_css_class(options[:class])
    super(method, text, options, &block)
  end

  %w[ text email phone password number file date ].each do |input|
    alias_method "base_#{input}_field".to_sym, "#{input}_field"
    define_method("#{input}_field") do |method, options={}|
      super(method, add_form_control_options(options))
    end
  end

  def text_area(method, options={})
    options[:rows] ||= scale_rows_to_value(object.send(method))

    super(method, add_form_control_options(options))
  end

  def select(method, choices=nil, options={}, html_options={})
    html_options = add_form_control_options(html_options)
    super(method, choices, options, html_options)
  end
  alias :basic_select :select

  def date_select(method, options={}, html_options={})
    html_options = add_form_control_options(html_options)
    content_tag(:div, class: 'input-group date-select') do
      super(method, options, html_options)
    end
  end

  def radio_buttons(method, options={}, html_options={})
    cur_val = object.send(method).to_s
    options.map do |label, value|
      content_tag(:div, class: 'Field-check') do
        current = cur_val == value.to_s
        content_tag(:label, class: "Field-checkbox #{current ? 'active' : ''}") do
          radio_button(method, value, checked: current).html_safe + label
        end
      end
    end.join.html_safe
  end

  alias :base_check_box :check_box
  def check_box(method, options={}, checked_value="1", unchecked_value="0")
    content_tag(:div, class: 'checkbox') do
      if block_given?
        label = capture { yield }
      else
        label = options.delete(:label) { translate_label(method) }
      end
      content_tag(:label) do
        base_check_box(method, options, checked_value, unchecked_value) <<
          label
      end
    end
  end

  def error_messages?
    object.errors.any?
  end

  def error_messages(options={})
    model_name = options.fetch(:model_name) { object.class.model_name.human }
    heading    = options.fetch(:heading, true)
    if object.errors.any?
      content_tag(:div, class: 'errors-panel') do
        if heading == true
          html = content_tag(:p, content_tag(:strong, "Your #{model_name} could not be saved"))
        elsif heading
          html = content_tag(:p, content_tag(:strong, heading))
        else
          html = ''.html_safe
        end
        html << content_tag(:ul) do
          object.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe
        end
      end
    end
  end

  def fieldset(legend="", options={}, &block)
    content_tag(:fieldset, options) do
      content_tag(:legend, legend) << capture(&block)
    end
  end

  def hint(hint=nil)
    hint ||= capture { yield }
    content_tag(:p, hint, class: 'help-block')
  end

  protected

  def label_css_class(*)
    'Field-label'
  end

  def form_group(method=nil, _options={}, &block)
    css_class  = 'Field'
    css_class += ' Field--error' if has_errors_on?(method)
    content_tag(:div, class: css_class, &block)
  end

  def has_errors_on?(method)
    return false unless method && object
    object.errors.include?(method)
  end

  def error_messages_for(method)
    return '' if method.nil?
    object.errors[method].join(', ')
  end

  def add_form_control_options(options)
    options
  end

  def get_button_css_class(options)
    @template.add_button_css_classes(options)
  end

  def scale_rows_to_value(value)
    lines = 0

    if value && value.is_a?(String)
      lines = value.scan("\n").count + 1
    end

    [3, lines].max
  end

  def translate_label(method)
    I18n.translate("#{object_name}.#{method}",
                   scope: 'helpers.label',
                   default: method.to_s.humanize)
  end


end
