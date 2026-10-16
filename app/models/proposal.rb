# frozen_string_literal: true

# A change suggested for a person to review and make. AI accounts propose
# rather than edit: the data comes from a game they can't play, so a person
# who can check it decides. Each kind of change (see ProposalChanges) knows
# its parameters, what it would change and how to make it.
#
# A proposal snapshots what it would change when it's made (+before+). If
# that has changed by review time, it's stale: still acceptable, but worth a
# second look. Accepting makes the change as the reviewer, through the same
# operations and revision history as editing on the site; if that fails,
# the proposal stays pending with the error.
class Proposal < ApplicationRecord
  enum :status, { pending: 0, accepted: 1, rejected: 2, withdrawn: 3 }

  belongs_to :author, class_name: 'User', optional: false
  belongs_to :api_token, optional: true
  belongs_to :subject, polymorphic: true, optional: true
  belongs_to :reviewed_by, class_name: 'User', optional: true

  scope :newest_first, -> { order(created_at: :desc, id: :desc) }
  scope :oldest_first, -> { order(created_at: :asc, id: :asc) }

  validates :reason, presence: true, length: { maximum: 5_000 }
  validates :evidence, length: { maximum: 5_000 }
  validate  :change_is_known
  validate  :change_is_valid, on: :create
  validate  :not_already_proposed, on: :create

  before_validation :snapshot_before, on: :create

  def change_type
    ProposalChanges.find(change)
  end

  # What it would do, in words: "Make Wax concrete".
  def summary
    change_type&.summary(self) || change.to_s
  end

  # [ [label, before, after] ] for the values it would change.
  def differences
    change_type&.differences(self) || []
  end

  # Whether what it would change has changed since it was proposed.
  def stale?
    pending? && change_type && change_type.before(self) != before
  end

  # Makes the change as +reviewer+. Returns true when accepted; otherwise
  # the proposal stays pending, with the reason in +error+.
  def accept!(reviewer, note: nil)
    raise ArgumentError, 'Only a pending proposal can be accepted' unless pending?
    transaction do
      change_type.apply!(self, reviewer)
      update!(status: :accepted, reviewed_by: reviewer, reviewed_at: Time.current,
              review_note: note.presence, error: nil)
    end
    true
  rescue ProposalChanges::Invalid, ActiveRecord::RecordInvalid => e
    update_columns(error: e.message, updated_at: Time.current)
    false
  end

  def reject!(reviewer, note: nil)
    raise ArgumentError, 'Only a pending proposal can be rejected' unless pending?
    update!(status: :rejected, reviewed_by: reviewer, reviewed_at: Time.current, review_note: note.presence)
  end

  def withdraw!
    raise ArgumentError, 'Only a pending proposal can be withdrawn' unless pending?
    update!(status: :withdrawn)
  end

  def to_s
    summary
  end

  private

  def change_is_known
    errors.add(:change, "isn't one of #{ProposalChanges.keys.to_sentence}") unless change_type
  end

  def change_is_valid
    return unless change_type
    self.params = (params || {}).to_h.stringify_keys
    change_type.validate(self)
  end

  def snapshot_before
    self.before = change_type.before(self) if change_type && errors.empty?
  rescue ProposalChanges::Invalid
    nil
  end

  def not_already_proposed
    same = Proposal.pending.where(change: change, subject_type: subject_type, subject_id: subject_id)
                   .where('params = ?::jsonb', params.to_json)
    errors.add(:base, 'The same change is already proposed') if same.exists?
  end
end
