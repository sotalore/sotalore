# frozen-string-literal: true

class RevisionRecorder

  class << self
    def call(model, current_user)
      if model.previous_changes.any?
        what_changed = model.previous_changes.except(
          :id, :updated_at, :created_at)

        handle_instance_of_change(model, what_changed)
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
    def handle_instance_of_change(model, what_changed)
      if what_changed.key?(:instance_id)
        old_instance_id, new_instance_id = what_changed.delete(:instance_id)
        what_changed[:instance] = [
          Item.find_by(id: old_instance_id)&.to_s,
          model.instance_of&.to_s
        ]
      end
    end

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
