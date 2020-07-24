desc "Fix comments"
task fix_comments: :environment do
  Comment.revision.find_each do |comment|
    next unless comment.revision_changes['gathering_skill']
    json = comment.parsed_revision
    puts "=== Changing..."
    puts json
    json['changes']['gathering_skill'] = json['changes']['gathering_skill'].map do |val|
      case val
      when Hash
        val['name']
      else
        val
      end
    end
    puts "=== To..."
    puts json
    comment.body = json.to_json
    comment.save!
  end

end
