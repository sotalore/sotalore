# frozen-string-literal: true

class RevisionRecorder

  class << self
    # Records an ItemMembership being added or removed (+action+ is :added or
    # :removed) as a revision on both the group and the member.
    def membership(membership, current_user, action)
      group, member = membership.group, membership.member
      from_to = ->(name) { action == :added ? [ nil, name ] : [ name, nil ] }
      group.comments.create!(author: current_user, comment_type: 'revision',
                             body: { changes: { member: from_to.(member.name) } }.to_json)
      member.comments.create!(author: current_user, comment_type: 'revision',
                              body: { changes: { group: from_to.(group.name) } }.to_json)
    end

    def call(model, current_user)
      if model.previous_changes.any?
        what_changed = model.previous_changes.except(
          :id, :updated_at, :created_at)

        handle_gathering_skill_change(model, what_changed)
        handle_type_data_changes(model, what_changed)

        model.comments.create!(
          author: current_user,
          comment_type: 'revision',
          body: {changes: what_changed}.to_json
        )
      end
    end

    private
    def handle_gathering_skill_change(model, what_changed)
      if what_changed.key?(:gathering_skill)
        c = what_changed[:gathering_skill]
        what_changed[:gathering_skill] = c.map { |v| v ? v.to_s : v }
      end
    end

    def handle_type_data_changes(model, what_changed)
      if what_changed.key?(:type_data)
        from_data, to_data = what_changed.delete(:type_data)
        all_keys = from_data.keys | to_data.keys
        all_keys.each do |key|
          unless what_changed.key?(key)
            what_changed[key] = [ from_data[key], to_data[key] ]
          end
        end
      end
    end

  end
end
