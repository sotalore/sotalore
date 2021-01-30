module FormsHelper

  def sl_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    options[:builder] ||= SLFormBuilder
    form_with(model: model, scope: scope, url: url, format: format, **options, &block)
  end

  def sl_form_for(object, options={}, &block)
    options[:builder] ||= SLFormBuilder
    form_for(object, options, &block)
  end
  alias_method :full_form_for, :sl_form_for

  def sl_inline_form_for(object, options={}, &block)
    options[:builder] ||= SLFormBuilder
    html                = (options[:html] ||= {})
    html[:class]        = "#{html[:class]} Form--inline".strip
    form_for(object, options, &block)
  end

  def sl_inline_form_tag(object, options={}, &block)
    options[:class] = "#{options[:class]} Form--inline".strip
    form_tag(object, options, &block)
  end

  def basic_form_for(object, options={}, &block)
    options[:builder] ||= BasicFormBuilder
    form_for(object, options, &block)
  end

  def basic_inline_form_for(object, options={}, &block)
    options[:builder] ||= BasicFormBuilder
    html                = (options[:html] ||= {})
    html[:class]        = "#{html[:class]} Form--inline".strip
    form_for(object, options, &block)
  end

  def form_group(options={}, &block)
    form_group(method) { label << capture(&block) }
  end

  def no_yes_options
    [ [ 'No', 'false' ], [ 'Yes', 'true' ] ]
  end

  def yes_no_options
    no_yes_options.reverse
  end

  def boolean_options(*args)
    options = args.extract_options!

    truthy_label = args.first || "Yes"
    falsey_label = args.last || "No"

    include_blank = options.fetch(:include_blank) { true }

    if include_blank
      { "-" => "", truthy_label => true, falsey_label => false }
    else
      { truthy_label => true, falsey_label => false }
    end
  end

  def form_actions(&block)
    content_tag(:div, class: "form-actions Form-actions", &block)
  end

end
