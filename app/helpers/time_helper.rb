# frozen-string-literal: true

module TimeHelper

  def time_ago_tag(time, options={})
    if time
      local_time_ago(time)
    end
  end

end
