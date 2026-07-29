module FormsHelper

  def sl_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    options[:builder] ||= SLFormBuilder
    form_with(model: model, scope: scope, url: url, format: format, **options, &block)
  end

  def sl_form_for(object, options={}, &block)
    options[:builder] ||= SLFormBuilder
    form_for(object, options, &block)
  end

  def sl_inline_form_with(model: nil, scope: nil, url: nil, format: nil, **options, &block)
    options[:builder] ||= SLFormBuilder
    html                = (options[:html] ||= {})
    html[:class]        = "#{html[:class]} Form--inline".strip
    form_with(model: model, scope: scope, url: url, format: format, **options, &block)
  end

  def form_actions(&block)
    content_tag(:div, class: "form-actions Form-actions", &block)
  end

end
