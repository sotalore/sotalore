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

  alias :basic_rich_text_area :rich_text_area
  def rich_text_area(method, options={})
    form_group_with_label(method, options) do
      input_with_hint_and_errors(method, options) do
        basic_rich_text_area(method, options)
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

  alias :basic_radio_buttons :radio_buttons
  def radio_buttons(method, options={}, html_options={})
    form_group_with_label(method, html_options) do
      input_with_hint_and_errors(method, html_options) do
        basic_radio_buttons(method, options, html_options)
      end
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
    content_tag(:div, class: 'flex flex-row gap-2 place-content-end') do
      yield
    end
  end

  private

  def input_with_hint_and_errors(method, options={}, &block)
    hint_and_errors = "".html_safe
    hint = options.delete(:hint)
    hint ||= translate_hint(method, options.delete(:hint_options) || {})
    if hint.present?
      hint_and_errors << hint_tag(hint)
    end
    hint_and_errors << inline_errors_for(method).to_s
    capture(&block) << hint_and_errors
  end

  def add_form_control_options(options)
    options[:class] = "Field-input #{options[:class]}".strip
    options
  end

  def hint_tag(hint)
    content_tag(:small, hint, class: "Field-hint")
  end

  def translate_hint(method, options = {})
    kwargs = { scope: hint_scope, default: '' }.merge(options)
    I18n.translate("#{object_name}.#{method}", **kwargs)
  end

  def hint_scope
    'helpers.hint'
  end

  def form_group_with_label(method=nil, options={}, &block)
    skip_label = method.nil? || options.fetch(:skip_label, false)
    label = skip_label ? "".html_safe : label(*[method, options[:label]].compact)

    if options[:required]
      tag = content_tag(:span, "*", class: "Field-required")
      label = label.sub("</label>", "&nbsp;#{tag}</label>").html_safe
    end

    form_group(method) { label << capture(&block) }
  end


end
