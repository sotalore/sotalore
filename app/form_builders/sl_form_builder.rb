# frozen-string-literal: true

class SLFormBuilder < BasicFormBuilder
  include ActionView::RecordIdentifier

  %w[ text email phone password number file date color].each do |input|
    original = "basic_#{input}_field".to_sym
    target   = "#{input}_field".to_sym
    define_method(original, instance_method(target))

    define_method(target) do |method,options={}|
      form_group_with_label(method, options) do
        input_with_hint_and_errors(method, options) { send(original, method, options) }
      end
    end
  end

  alias :basic_text_area :text_area
  def text_area(method, options={})
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) do
        basic_text_area(method, options)
      end
    end
  end

  def select(method, choices=nil, options={}, html_options={})
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) do
        basic_select(method, choices, options, html_options)
      end
    end
  end

  alias :basic_date_select :date_select
  def date_select(method, options={}, html_options={})
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) {
        basic_date_select(method, options, html_options)
      }
    end
  end

  def date_picker(method, options = {})
    current_value = object.send(method)

    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) do
        basic_text_field(method, {
          value: current_value && current_value.to_date.iso8601,
          data: date_picker_data(current_value, options),
          placeholder: "YYYY-MM-DD"
        }.merge(options))
      end
    end
  end

  def date_picker_data(current_value, options = {})
    data = {
      date_format: "yyyy-mm-dd",
      date_autoclose: true,
      date_today_highlight: true,
      date_max_view_mode: "years",
      date_start_view: options[:start_view],
      provide: "datepicker"
    }

    if options[:only_future]
      data[:date_start_date] = [current_value, Time.zone.now].compact.min.to_date.iso8601
    end

    if options[:only_past]
      data[:date_end_date] = Time.zone.now.to_date.iso8601
    end

    if options[:only_weekdays]
      data[:date_days_of_week_disabled] = "0,6"
    end

    data
  end

  def static_field(method, options={}, &block)
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) do
        if block
          content_tag(:p, class: 'form-control-static', &block)
        else
          content_tag(:p, object.send(method), class: 'form-control-static')
        end
      end
    end
  end

  def labelled_group(method, options={}, &block)
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options, &block)
    end
  end

  def inline_errors_for(method)
    if has_errors_on?(method)
      content_tag(:div, error_messages_for(method), class: 'Field-error')
    end
  end

  def check_box(method, options={}, checked_value="1", unchecked_value="0")
    content_tag(:div, class: 'Field') do
      input_with_hint_and_errors(method, options) do
        if block_given?
          label = capture { yield }
        else
          label = options.delete(:label) { translate_label(method) }
        end
        content_tag(:label, class: 'Field-checkbox Field-checkboxPadding') do
          base_check_box(method, options, checked_value, unchecked_value) + label
        end
      end
    end
  end

  def multiple_check_box(method, options={}, checked_value="1", unchecked_value="0")
    options[:multiple] = true
    if block_given?
      label = capture { yield }
    else
      label = options.delete(:label) { translate_label(method) }
    end
    content_tag(:label, class: 'Field-checkbox') do
      base_check_box(method, options, checked_value, unchecked_value) + label
    end
  end

  def multiple_check_boxes(method, options={}, &block)
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) do
        content_tag(:div, class: 'Field-checkboxPadding', &block)
      end
    end
  end
  alias multiple_radio_buttons multiple_check_boxes

  alias :basic_collection_check_boxes :collection_check_boxes
  def collection_check_boxes(method, collection, value, label, options={})
    if !block_given?
      block = ->(b) do
        b.label(class: "Field-checkbox") { b.check_box + b.text }
      end
    end

    multiple_check_boxes(method, options) do
      basic_collection_check_boxes(method, collection, value, label, &block)
    end
  end

  alias base_radio_button radio_button
  def radio_button(method, value, options={})
    if block_given?
      label = capture { yield }
    else
      label = options.delete(:label) { translate_label(method) }
    end
    content_tag(:label, class: 'Field-checkbox') do
      base_radio_button(method, value, options) + label
    end
  end

  def toggle(method, options={}, html_options={})
    form_group_with_label(method, html_options) do
      content_tag(:div, class: 'Field-toggle') do
        html = ''.html_safe

        if html_options.include?(:include_blank)
          include_blank = html_options.delete(:include_blank)
          include_blank = 'Unknown' if include_blank == true
          html << toggle_option(method, [include_blank, nil], html_options)
        end

        options.each { |option| html << toggle_option(method, option, html_options) }

        html
      end
    end
  end

  def error_messages(options={})
    model_name = options.fetch(:model_name) { object.class.model_name.human }
    heading    = options.fetch(:heading) { "Your #{model_name} could not be saved" }
    if object.errors.any?
      content_tag(:div, class: 'Form-errors') do
        html = ''.html_safe
        html += content_tag(:h4, heading, class: 'Form-errorsHeading') if heading
        html += content_tag(:ul) do
          object.errors.full_messages.map { |msg| content_tag(:li, msg) }.join.html_safe
        end
      end
    end
  end

  def fieldset(legend="", options={}, &block)
    options[:class] = "#{options[:class]} Form-fieldset"
    content_tag(:fieldset, options) do
      if legend.present?
        content_tag(:legend, legend, class: "Form-legend") << capture(&block)
      else
        capture(&block)
      end
    end
  end

  def actions
    content_tag(:div, class: 'row') do
      content_tag(:div, class: 'col-xs u-textRight text-right') do
        yield
      end
    end
  end

  private

  def input_with_hint_and_errors(method, options={}, &block)
    hint_and_errors = "".html_safe
    hint = options.delete(:hint)
    hint ||= translate_hint(method, options.delete(:hint_options) || {})
    if hint.present?
      hint_and_errors << hint_tag(hint, options.delete(:hint_on_focus) { false })
    end
    hint_and_errors << inline_errors_for(method).to_s
    capture(&block) << hint_and_errors
  end

  def form_group(method=nil, _options={}, &block)
    css_class  = 'Field'
    css_class += ' Field--error' if has_errors_on?(method)
    content_tag(:div, class: css_class, &block)
  end

  def form_group_with_label(method=nil, options={}, &block)
    skip_label = method.nil? || options.fetch(:skip_label, false)
    label = skip_label ? "".html_safe : label(*[method, options[:label]].compact)

    if options[:soft_required] || (object.respond_to?(:soft_required?) && object.soft_required?(method))
      tag = content_tag(:span, "*", class: "Field-softRequired")
      label = label.sub("</label>", "&nbsp;#{tag}</label>").html_safe
    end

    if options[:required]
      tag = content_tag(:span, "*", class: "Field-required")
      label = label.sub("</label>", "&nbsp;#{tag}</label>").html_safe
    end

    form_group(method) { label << capture(&block) }
  end

  def label_css_class(*)
    'Field-label'
  end

  def add_form_control_options(options)
    options[:class] = "Field-input #{options[:class]}".strip
    options
  end

  def toggle_option(method, option, html_options)
    label, value = option_text_and_value(option)
    value = "" if value.nil?
    content_tag(:label, class: "Field-toggleOption") do
      base_radio_button(method, value, html_options) +
        content_tag(:span, label, class: "Field-toggleText")
    end
  end

  def option_text_and_value(option)
    # Options are [text, value] pairs or strings used for both.
    if !option.is_a?(String) && option.respond_to?(:first) && option.respond_to?(:last)
      [option.first, option.last]
    else
      [option, option]
    end
  end

  def hint_tag(hint, hint_on_focus=false)
    content_tag(:small, hint, class: hint_on_focus ? "Field-hintOnFocus" : "Field-hint")
  end

  def translate_hint(method, options = {})
    kwargs = { scope: 'helpers.hint', default: '' }.merge(options)
    I18n.translate("#{object_name}.#{method}", **kwargs)
  end

end
