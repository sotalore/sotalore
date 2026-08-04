# frozen_string_literal: true

# The recommended way to consume this library: render a FormBuilder with a
# block, yielding it the same way Rails' own form_with (or this app's
# SLFormBuilder) does -- instead of `include`ing Grav::Views::Forms::Base
# directly into your own view class.
#
#   class Views::Scenes::Form < Views::Scenes::Base
#     def view_template
#       render Grav::Views::Forms::FormBuilder.new(model: @scene) do |f|
#         f.text_field(:name, autofocus: true)
#         f.form_actions do
#           f.cancel_button
#           f.submit_button
#         end
#       end
#     end
#   end
#
# Base's ~40 field/label/error/action methods used to get `include`d
# directly into whatever view class called `include Grav::Views::Forms::Base`
# -- joining the very same method namespace as that view's own methods,
# whatever it inherits from the app's view hierarchy, and Phlex::HTML's own
# tag methods. A silent collision there (a view happening to define its own
# `model` or `params`, say) just loses, with no signal that it happened.
#
# FormBuilder is a small, closed Phlex::HTML component with nothing else
# mixed in, so that whole shared-namespace risk goes away: its ancestor
# chain is just this library's own modules, Phlex::Rails::Helpers::Routes
# (which Base's #form_action/#cancel_button need, for the polymorphic_path
# fallback when no explicit url: is given), and Phlex::HTML itself -- never
# whatever a particular consuming app's view hierarchy happens to define.
#
# Grav::Views::Forms::Base itself is unchanged and still works exactly as it
# always has, for forms already built directly on it -- there's no need to
# migrate everything at once just to start using this for new forms.
class Grav::Views::Forms::FormBuilder < Phlex::HTML
  include Phlex::Rails::Helpers::Routes
  include Grav::Views::Forms::Base
end
