# frozen_string_literal: true

# The skills pages' Import tab: the tabs and avatar menu, and the avatar the
# levels go to, called out at the top.
class Views::SkillImports::Page < Views::Skills::Base

  def initialize(avatar:, avatars: nil)
    @avatar = avatar
    @avatars = avatars
  end

  private

  def import_page
    page_title(@avatar ? "Import skills for #{@avatar.name}" : 'Import skills')
    div(class: 'mb-12 mx-2 mt-2') do
      render Views::Skills::PageHeading.new(activity: 'import', with_avatar_controls: signed_in?,
                                            avatars: @avatars, avatar: @avatar)
      div(class: 'bg-white dark:bg-grey-800 p-4') do
        avatar_callout if @avatar
        yield
      end
    end
  end

  def avatar_callout
    div(class: 'mb-4 pb-3 border-b border-grey-300 dark:border-grey-600') do
      div(class: 'text-sm text-grey-600 dark:text-grey-300') { 'Importing skill levels into' }
      div(class: 'text-2xl font-bold', role: 'heading', aria: { level: 2 }) { @avatar.name }
      if @avatar.skills_synced_at
        div(class: 'text-sm text-grey-600 dark:text-grey-300') do
          plain 'Last imported '
          time_ago_tag @avatar.skills_synced_at
        end
      end
    end
  end

  def signed_in?
    Current.user.not_null?
  end

end
