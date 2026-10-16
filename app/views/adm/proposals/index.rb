# frozen_string_literal: true

# Proposed changes waiting for review, and past ones (see Proposal).
class Views::Adm::Proposals::Index < Views::Base
  include Phlex::Rails::Helpers::ButtonTo

  STATUS_LABELS = { 'pending' => 'Waiting', 'accepted' => 'Accepted', 'rejected' => 'Rejected',
                    'withdrawn' => 'Withdrawn' }.freeze

  def initialize(proposals:, status:, counts:)
    @proposals = proposals
    @status = status
    @counts = counts
  end

  def view_template
    div(class: 'm-2 bg-white dark:bg-grey-800 p-4') do
      h1(class: 'text-2xl font-bold') { 'Proposals' }
      p(class: 'my-2 max-w-prose text-sm') do
        plain 'Changes suggested for someone to check and make, mostly by AI accounts, which can\'t '
        plain 'play the game. Accepting makes the change as you, recorded in the item\'s history. A '
        strong { 'stale' }
        plain ' proposal\'s subject has changed since it was made, so look again before accepting.'
      end
      status_tabs
      if @proposals.empty?
        notice_success('Nothing here.')
      else
        paginate @proposals
        @proposals.each { |proposal| proposal_card(proposal) }
        paginate @proposals
      end
    end
  end

  private

  def status_tabs
    div(class: 'flex flex-row flex-wrap gap-2 my-4') do
      STATUS_LABELS.each do |status, label|
        a(href: adm_proposals_path(status: status),
          class: "Button Button--sm Button--#{status == @status ? 'primary' : 'default'}") do
          "#{label} (#{@counts[status].to_i})"
        end
      end
    end
  end

  def proposal_card(proposal)
    div(class: 'mb-4 p-3 border border-grey-300 dark:border-grey-600 rounded') do
      div(class: 'flex flex-row flex-wrap items-baseline gap-x-3') do
        strong(class: 'text-lg') { proposal.summary }
        span(class: 'text-xs px-2 rounded bg-yellow-200 text-yellow-900') { 'stale' } if proposal.stale?
        span(class: 'text-sm text-grey-500') do
          plain "##{proposal.id} · #{proposal.change} · by #{proposal.author.name} "
          time_ago_tag proposal.created_at
        end
      end
      subject_link(proposal)
      differences(proposal)
      labelled('Why', proposal.reason)
      labelled('Evidence', proposal.evidence) if proposal.evidence.present?
      p(class: 'text-sm text-red-700 dark:text-red-300') { "Last attempt failed: #{proposal.error}" } if proposal.error.present?
      if proposal.pending?
        review_form(proposal)
      else
        reviewed(proposal)
      end
    end
  end

  def subject_link(proposal)
    subject = proposal.subject
    case subject
    when Item
      div(class: 'text-sm') do
        a(href: item_path(subject), class: 'Link Link--primary') { subject.name }
        plain " (#{subject.kind})"
      end
    when Recipe
      div(class: 'text-sm') do
        a(href: recipe_path(subject), class: 'Link Link--primary') { subject.name }
        plain " (#{[ subject.craft_skill&.name, subject.kind, ('retired' if subject.retired?) ].compact.join(', ')})"
      end
    end
  end

  def differences(proposal)
    rows = proposal.differences
    return if rows.empty?
    table(class: 'my-2 text-sm') do
      rows.each do |name, from, to|
        tr do
          td(class: 'pr-3 font-bold') { name.to_s }
          td(class: 'pr-2 text-grey-500') { from.nil? ? '-' : from.to_s }
          td(class: 'pr-2') { '→' }
          td { to.nil? ? '-' : to.to_s }
        end
      end
    end
  end

  def labelled(label, text)
    div(class: 'text-sm my-1 max-w-prose') do
      strong { "#{label}: " }
      plain text
    end
  end

  def review_form(proposal)
    return unless policy(proposal).review?
    form(method: 'post', class: 'mt-2 flex flex-row flex-wrap items-center gap-2') do
      input(type: 'hidden', name: 'authenticity_token', value: view_context.form_authenticity_token)
      input(type: 'text', name: 'note', placeholder: 'Note (optional)',
            class: 'border border-grey-400 rounded px-2 py-1 text-sm w-72 dark:bg-grey-700')
      button(type: 'submit', formaction: accept_adm_proposal_path(proposal),
             class: 'Button Button--sm Button--primary') { 'Accept' }
      button(type: 'submit', formaction: reject_adm_proposal_path(proposal),
             class: 'Button Button--sm Button--danger') { 'Reject' }
    end
  end

  def reviewed(proposal)
    p(class: 'text-sm text-grey-500 mt-1') do
      if proposal.reviewed_by
        plain "#{proposal.status.capitalize} by #{proposal.reviewed_by.name} "
        time_ago_tag proposal.reviewed_at
      else
        plain proposal.status.capitalize
      end
      plain " · #{proposal.review_note}" if proposal.review_note.present?
    end
  end

end
