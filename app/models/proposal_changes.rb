# frozen_string_literal: true

# The kinds of change a Proposal can suggest. Each knows its parameters,
# checks them, snapshots and describes what it would change, and makes the
# change through the same operations as the site's own pages, recording
# revisions as the reviewer.
#
# Every change is a subclass of ProposalChanges::Base, registered by key.
module ProposalChanges

  # A change that can't be proposed or made, with why.
  class Invalid < StandardError; end

  REGISTRY = {}

  # What a change can be about, by name.
  SUBJECTS = { 'Item' => 'Item', 'Recipe' => 'Recipe' }.freeze

  def self.register(change)
    REGISTRY[change.key] = change
  end

  def self.find(key)
    load_all
    REGISTRY[key.to_s]
  end

  def self.keys
    load_all
    REGISTRY.keys
  end

  def self.all
    load_all
    REGISTRY.values
  end

  def self.load_all
    [ ItemCreate, ItemKind, ItemRename, ItemAliasAdd, ItemAttributes, MembershipAdd, MembershipRemove,
      RecipeRetire, RecipeUnretire ]
  end

  class Base
    class << self
      attr_reader :key, :description, :subject_type, :parameters

      # Declares the change: its key, what it's about (an Item, or nil when
      # it makes something new), what it does and its parameters, as
      # { name => description }.
      def change(key, subject:, description:, parameters:)
        @key = key
        @subject_type = subject
        @description = description
        @parameters = parameters
        ProposalChanges.register(self)
      end

      # The class of what it's about, or nil when it makes something new.
      def subject_class
        subject_type && SUBJECTS.fetch(subject_type).constantize
      end

      # Whether the proposal is about the right kind of thing.
      def suits_subject?(proposal)
        subject_type.nil? || proposal.subject.is_a?(subject_class)
      end

      # Adds errors to the proposal for anything wrong with it.
      def validate(proposal)
        unless suits_subject?(proposal)
          proposal.errors.add(:subject, "must be an #{subject_type.underscore.humanize(capitalize: false)}")
          return
        end
        unknown = proposal.params.keys - parameters.keys.map(&:to_s)
        proposal.errors.add(:params, "has unknown #{unknown.to_sentence}") if unknown.any?
        check(proposal)
      rescue Invalid => e
        proposal.errors.add(:base, e.message)
      end

      # The current values of what it would change.
      def before(_proposal) = {}

      def differences(_proposal) = []

      def summary(_proposal) = description

      def apply!(_proposal, _reviewer)
        raise NotImplementedError
      end

      # As a Hash, for the API.
      def to_h
        { key: key, subject: subject_type, description: description, parameters: parameters }
      end

      protected

      # Raises Invalid when the proposal can't be made.
      def check(_proposal) = nil

      def param(proposal, name)
        proposal.params[name.to_s]
      end

      def required(proposal, name)
        value = param(proposal, name)
        raise Invalid, "#{name} is required" if value.blank?
        value
      end

      def item(id, what)
        Item.find_by(id: id) or raise Invalid, "#{what} #{id.inspect} isn't an item"
      end

      def kind_param(proposal)
        kind = required(proposal, :kind).to_s
        raise Invalid, "kind must be one of #{Item.kinds.keys.to_sentence}" unless Item.kinds.key?(kind)
        kind
      end

      def name_free!(name, except: nil)
        taken = Item.find_by_name(name).where.not(id: except&.id).first
        raise Invalid, "#{taken.name} is already an item" if taken
        aliased = ::ItemAlias.where('lower(name) = ?', name.downcase).where.not(item_id: except&.id).first
        raise Invalid, "#{name} is already an alias of #{aliased.item.name}" if aliased
      end
    end
  end

  # Makes a new item, say for one an export uses that the site lacks.
  class ItemCreate < Base
    change 'item.create', subject: nil,
           description: 'Make a new item',
           parameters: { 'name' => 'the item name, as the game has it',
                         'kind' => "one of #{Item.kinds.keys.join(', ')}; concrete if left out",
                         'use' => "optional: one of #{Item.uses.keys.join(', ')}",
                         'weight' => 'optional: the weight, as the game gives it' }

    class << self
      def summary(proposal)
        "Make #{param(proposal, :kind).presence || 'concrete'} item #{param(proposal, :name)}"
      end

      def differences(proposal)
        proposal.params.map { |name, value| [ name, nil, value ] }
      end

      def apply!(proposal, reviewer)
        check(proposal)
        item = Item.create!(name: param(proposal, :name).strip, kind: param(proposal, :kind).presence || 'concrete',
                            use: param(proposal, :use).presence || 'unknown', weight: param(proposal, :weight))
        RevisionRecorder.call(item, reviewer)
        proposal.subject = item
      end

      protected

      def check(proposal)
        name_free!(required(proposal, :name).to_s.strip)
        kind_param(proposal) if param(proposal, :kind).present?
        use = param(proposal, :use)
        raise Invalid, "use must be one of #{Item.uses.keys.to_sentence}" if use.present? && !Item.uses.key?(use)
      end
    end
  end

  # Changes what an item stands for (see Item::ITEM_KINDS).
  class ItemKind < Base
    change 'item.kind', subject: 'Item',
           description: "Change an item's kind",
           parameters: { 'kind' => "one of #{Item.kinds.keys.join(', ')}" }

    class << self
      def before(proposal) = { 'kind' => proposal.subject&.kind }

      def summary(proposal)
        "Make #{proposal.subject&.name} #{Item.new(kind: param(proposal, :kind)).kind_label}"
      rescue ArgumentError
        description
      end

      def differences(proposal)
        [ [ 'kind', proposal.before['kind'], param(proposal, :kind) ] ]
      end

      def apply!(proposal, reviewer)
        item = proposal.subject
        item.kind = kind_param(proposal)
        item.merchant_price = nil if item.abstract?
        raise Invalid, item.errors.full_messages.to_sentence unless item.save
        RevisionRecorder.call(item, reviewer)
      end

      protected

      def check(proposal)
        kind = kind_param(proposal)
        raise Invalid, "#{proposal.subject.name} is already #{proposal.subject.kind_label}" if proposal.subject.kind == kind
      end
    end
  end

  # Gives an item the game's name, keeping the old one as an alias.
  class ItemRename < Base
    change 'item.rename', subject: 'Item',
           description: 'Rename an item, keeping its old name as an alias',
           parameters: { 'name' => 'the new name' }

    class << self
      def before(proposal) = { 'name' => proposal.subject&.name }

      def summary(proposal) = "Rename #{proposal.before['name'] || proposal.subject&.name} to #{param(proposal, :name)}"

      def differences(proposal) = [ [ 'name', proposal.before['name'], param(proposal, :name) ] ]

      def apply!(proposal, reviewer)
        check(proposal)
        item = proposal.subject
        old_name = item.name
        item.update!(name: param(proposal, :name).strip)
        RevisionRecorder.call(item, reviewer)
        ::ItemAlias.create!(name: old_name, item: item)
      end

      protected

      def check(proposal)
        name = required(proposal, :name).to_s.strip
        raise Invalid, "#{proposal.subject.name} already has that name" if proposal.subject.name == name
        name_free!(name, except: proposal.subject)
      end
    end
  end

  # Lets a name resolve to an item without renaming it.
  class ItemAliasAdd < Base
    change 'item.alias', subject: 'Item',
           description: 'Add another name for an item',
           parameters: { 'name' => 'the other name' }

    class << self
      def before(proposal) = { 'aliases' => proposal.subject&.aliases&.pluck(:name)&.sort }

      def summary(proposal) = "Add #{param(proposal, :name)} as another name for #{proposal.subject&.name}"

      def differences(proposal) = [ [ 'alias', nil, param(proposal, :name) ] ]

      def apply!(proposal, _reviewer)
        check(proposal)
        ::ItemAlias.create!(name: param(proposal, :name).strip, item: proposal.subject)
      end

      protected

      def check(proposal)
        name_free!(required(proposal, :name).to_s.strip)
      end
    end
  end

  # Sets plain facts about an item.
  class ItemAttributes < Base
    ATTRIBUTES = %w[ weight use source merchant_price notes effects ].freeze

    change 'item.attributes', subject: 'Item',
           description: "Change an item's details",
           parameters: { 'weight' => 'the weight, as the game gives it',
                         'use' => "one of #{Item.uses.keys.join(', ')}",
                         'source' => "one of #{Item.sources.keys.join(', ')}",
                         'merchant_price' => 'what a merchant sells it for, for concrete items',
                         'notes' => 'notes shown on the item page',
                         'effects' => 'effects shown on the item page' }

    class << self
      def before(proposal)
        item = proposal.subject or return {}
        proposal.params.keys.intersection(ATTRIBUTES).to_h { [ _1, comparable(item.public_send(_1)) ] }
      end

      def summary(proposal) = "Change #{proposal.params.keys.to_sentence} of #{proposal.subject&.name}"

      def differences(proposal)
        proposal.params.map { |name, value| [ name, proposal.before[name], value ] }
      end

      def apply!(proposal, reviewer)
        item = proposal.subject
        item.assign_attributes(proposal.params.slice(*ATTRIBUTES))
        raise Invalid, item.errors.full_messages.to_sentence unless item.save
        RevisionRecorder.call(item, reviewer)
      end

      protected

      # Checked on a fresh copy, leaving the proposal's subject untouched.
      def check(proposal)
        raise Invalid, "Give at least one of #{ATTRIBUTES.to_sentence}" if proposal.params.empty?
        fresh = Item.find(proposal.subject.id)
        fresh.assign_attributes(proposal.params.slice(*ATTRIBUTES))
        raise Invalid, fresh.errors.full_messages.to_sentence unless fresh.valid?
        { 'use' => Item.uses, 'source' => Item.sources }.each do |name, values|
          value = proposal.params[name]
          raise Invalid, "#{name} must be one of #{values.keys.to_sentence}" if value && !values.key?(value)
        end
        if before(proposal) == proposal.params.transform_values { comparable(_1) }
          raise Invalid, "#{proposal.subject.name} already has those details"
        end
      end

      private

      def comparable(value)
        value.is_a?(BigDecimal) ? value.to_s('F').sub(/\.0\z/, '') : value&.to_s
      end
    end
  end

  # Puts an item in a group (a material choice) or category (an example).
  class MembershipAdd < Base
    change 'membership.add', subject: 'Item',
           description: 'Add a member to a group, or an example to a category',
           parameters: { 'member_id' => 'the id of the item to add' }

    class << self
      def before(proposal) = { 'members' => proposal.subject&.member_memberships&.pluck(:member_id)&.sort }

      def summary(proposal)
        "Add #{Item.find_by(id: param(proposal, :member_id))&.name} to #{proposal.subject&.name}"
      end

      def differences(proposal)
        [ [ 'member', nil, Item.find_by(id: param(proposal, :member_id))&.name ] ]
      end

      def apply!(proposal, reviewer)
        check(proposal)
        membership = ItemMembership.create!(group: proposal.subject, member: item(param(proposal, :member_id), 'member_id'))
        RevisionRecorder.membership(membership, reviewer, :added)
      end

      protected

      # Built by id, so it isn't attached to the subject's associations.
      def check(proposal)
        member = item(required(proposal, :member_id), 'member_id')
        membership = ItemMembership.new(group_id: proposal.subject.id, member_id: member.id)
        raise Invalid, membership.errors.full_messages.to_sentence unless membership.valid?
      end
    end
  end

  # Takes an item out of a group or category.
  class MembershipRemove < Base
    change 'membership.remove', subject: 'Item',
           description: 'Remove a member from a group, or an example from a category',
           parameters: { 'member_id' => 'the id of the item to remove' }

    class << self
      def before(proposal) = MembershipAdd.before(proposal)

      def summary(proposal)
        "Remove #{Item.find_by(id: param(proposal, :member_id))&.name} from #{proposal.subject&.name}"
      end

      def differences(proposal)
        [ [ 'member', Item.find_by(id: param(proposal, :member_id))&.name, nil ] ]
      end

      def apply!(proposal, reviewer)
        membership = check(proposal)
        membership.destroy!
        RevisionRecorder.membership(membership, reviewer, :removed)
      end

      protected

      def check(proposal)
        member = item(required(proposal, :member_id), 'member_id')
        ItemMembership.find_by(group: proposal.subject, member: member) or
          raise Invalid, "#{member.name} isn't in #{proposal.subject.name}"
      end
    end
  end

  # Marks a recipe as no longer in the game: hidden from listings and
  # flagged on its page, but kept, along with anything saved or said about it.
  class RecipeRetire < Base
    change 'recipe.retire', subject: 'Recipe',
           description: 'Retire a recipe that is no longer in the game (it is kept, but hidden)',
           parameters: {}

    class << self
      def before(proposal) = { 'retired' => proposal.subject&.retired? }

      def summary(proposal) = "Retire #{proposal.subject&.name}"

      def differences(proposal) = [ [ 'retired', proposal.before['retired'], true ] ]

      def apply!(proposal, reviewer)
        check(proposal)
        RecipeUnretire.set_retired(proposal.subject, true, reviewer)
      end

      protected

      def check(proposal)
        raise Invalid, "#{proposal.subject.name} is already retired" if proposal.subject.retired?
      end
    end
  end

  # Brings a retired recipe back.
  class RecipeUnretire < Base
    change 'recipe.unretire', subject: 'Recipe',
           description: 'Bring back a retired recipe that is in the game after all',
           parameters: {}

    class << self
      def before(proposal) = RecipeRetire.before(proposal)

      def summary(proposal) = "Bring back #{proposal.subject&.name}"

      def differences(proposal) = [ [ 'retired', proposal.before['retired'], false ] ]

      def apply!(proposal, reviewer)
        check(proposal)
        set_retired(proposal.subject, false, reviewer)
      end

      # Retiring skips validations (old recipes may not pass today's), so the
      # revision is recorded here.
      def set_retired(recipe, retired, reviewer)
        retired ? recipe.retire! : recipe.unretire!
        recipe.comments.create!(author: reviewer, comment_type: 'revision',
                                body: { changes: { retired: retired ? %w[ no yes ] : %w[ yes no ] } }.to_json)
      end

      protected

      def check(proposal)
        raise Invalid, "#{proposal.subject.name} isn't retired" unless proposal.subject.retired?
      end
    end
  end

end
