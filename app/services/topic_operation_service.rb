class TopicOperationService
  attr_reader :title, :content, :node_id, :is_repost, :source_url, :result_topic

  def initialize(title:, content:, node_id:, is_repost: false, source_url: nil)
    @title = title.to_s.strip
    @content = content.to_s.strip
    @node_id = node_id
    @is_repost = is_repost
    @source_url = source_url
  end

  def call
    validate!

    operational_user = random_operational_user
    node = Node.find(node_id)

    @result_topic = Topic.new(
      title: title,
      content: content,
      node: node,
      user: operational_user,
      is_repost: is_repost,
      source_url: source_url,
      published_by_operational: true,
      ai_generated: true
    )

    if @result_topic.save
      @result_topic.generate_slug!
      { success: true, message: "话题创建成功", topic: @result_topic, user: operational_user }
    else
      { success: false, message: "创建失败：#{@result_topic.errors.full_messages.join(', ')}" }
    end
  rescue ActiveRecord::RecordNotFound => e
    { success: false, message: "版块不存在" }
  end

  private

  def validate!
    if title.blank?
      raise ArgumentError, "标题不能为空"
    end
    if content.blank?
      raise ArgumentError, "内容不能为空"
    end
    if title.length < 4
      raise ArgumentError, "标题至少 4 个字符"
    end
    if content.length < 10
      raise ArgumentError, "内容至少 10 个字符"
    end
  end

  def random_operational_user
    accounts = User.operational.order("RANDOM()").limit(1)
    if accounts.empty?
      raise ArgumentError, "暂无可用运营账号，请先创建运营账号"
    end
    accounts.first
  end
end
