# frozen_string_literal: true

# Where a player pastes the skill code from the game (see SkillCode), or,
# without an avatar to put it on, what importing does and how to start.
class Views::SkillImports::New < Views::SkillImports::Page
  include Phlex::Rails::Helpers::LinkTo

  def initialize(code: nil, code_text: nil, **)
    super(**)
    @code = code
    @code_text = code_text
  end

  def view_template
    import_page do
      if @avatar
        paste_form
      else
        explanation
      end
    end
  end

  private

  def explanation
    div(class: 'max-w-prose space-y-3') do
      div(class: 'text-xl font-bold', role: 'heading', aria: { level: 2 }) { 'Bring your skill levels in from the game' }
      p do
        plain 'Instead of typing in every skill\'s current level, copy them straight from the game. With the '
        strong { 'SotaLore Skills' }
        plain ' add-on installed, the game gives you a short code with all your avatar\'s trained skills. Paste '
        plain 'it here, check what would change, and the skill planner has your current levels, ready for '
        plain 'setting targets. Your targets are never changed unless you ask.'
      end
      p { 'Import again whenever you\'ve trained, to bring the planner up to date.' }
      next_step
    end
  end

  def next_step
    notice_info do
      if !signed_in?
        link_to('Sign in', new_user_session_path, class: 'Link')
        plain ' to keep avatars and their skills, then come back to this tab.'
      elsif @avatars.nil?
        link_to('Create an avatar', avatars_path, class: 'Link')
        plain ' for your character, then come back to this tab.'
      else
        plain 'Choose the avatar to import into from the Avatar menu above.'
      end
    end
  end

  def paste_form
    instructions
    errors
    # Skips Turbo, which ignores a page rendered in answer to a form.
    form(action: preview_avatar_skill_import_path(@avatar), method: 'post', class: 'max-w-screen-md',
         data: { turbo: 'false', controller: 'skill-code' }) do
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      textarea(name: 'code', rows: 8, required: true, spellcheck: 'false', autocomplete: 'off',
               placeholder: 'SLS1|1/2|…',
               class: 'w-full font-mono text-xs border border-grey-400 rounded p-2 dark:bg-grey-700 break-all',
               data: { skill_code_target: 'input', action: 'input->skill-code#read' }) { @code_text }
      p(class: 'my-2 text-sm min-h-5', data: { skill_code_target: 'status' })
      button(type: 'submit', class: 'Button Button--primary', data: { skill_code_target: 'submit' }) { 'Check the changes' }
    end
  end

  def instructions
    div(class: 'mb-4 text-sm max-w-prose space-y-2') do
      p do
        plain 'In the game, with the SotaLore Skills add-on (sl-skills), type '
        code(class: 'font-mono') { '/slskills' }
        plain ' to open its window. Click the code, press Ctrl+A then Ctrl+C, and paste it below.'
      end
      p do
        plain 'If the window says there\'s more than one page, press Next and copy each page in turn, pasting '
        plain 'them all here one after another (in any order). You\'ll see the changes before anything is saved.'
      end
    end
  end

  def errors
    return unless @code
    messages = @code.errors.dup
    messages << "Still missing #{'page'.pluralize(@code.missing_pages.size)} #{@code.missing_pages.to_sentence} of #{@code.page_count}." if @code.errors.empty?
    notice_warning do
      ul { messages.each { |message| li { message } } }
    end
  end

end
