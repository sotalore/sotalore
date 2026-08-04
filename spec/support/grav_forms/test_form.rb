# frozen_string_literal: true

# A minimal host Phlex view used only to exercise Grav::Views::Forms::Base
# (and everything it includes) in isolation, the same way any real
# Views::*::Form class in the app consumes the library. It includes
# Phlex::Rails::Helpers::Routes itself because, in the app, that comes from
# Components::Base rather than from the library -- Base#form_action and
# #cancel_button rely on `polymorphic_path` being available on the host.
class GravFormsTestForm < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Grav::Views::Forms::Base
end
