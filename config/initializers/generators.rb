Rails.application.config.generators do |g|
  g.template_engine  :haml
  g.helper           false
  g.javascripts      false
  g.stylesheets      false
  g.decorator        false

  g.helper_specs     false
  g.view_specs       false
  g.factory_bot      dir: 'spec/factories', suffix: 'factory'
end
