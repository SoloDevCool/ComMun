class CommentOperationService
  attr_reader :topic_id, :content, :parent_id, :result_comment

  def initialize(topic_id:, content:, parent_id: nil)
    @topic_id = topic_id
    @content = content.to_s.strip
    @parent_id = parent_id
  end

  def call
    validate!

    topic = Topic.find(topic_id)
    operational_user = random_operational_user_excluding(topic.user)

    @result_comment = Comment.new(
      topic: topic,
      user: operational_user,
      content: content,
      parent_id: parent_id,
      login_only: false,
      published_by_operational: true,
      ai_generated: true
    )

    if @result_comment.save
      { success: true, message: "评论发布成功", comment: @result_comment, user: operational_user, topic: topic }
    else
      { success: false, message: "发布失败：#{@result_comment.errors.full_messages.join(', ')}" }
    end
  rescue ActiveRecord::RecordNotFound => e
    { success: false, message: "话题不存在" }
  end

  private

  def validate!
    if content.blank?
      raise ArgumentError, "评论内容不能为空"
    end
    if content.length < 2
      raise ArgumentError, "评论内容至少 2 个字符"
    end
    if content.length > 2000
      raise ArgumentError, "评论内容最多 2000 个字符"
    end
  end

  def random_operational_user_excluding(excluded_user)
    accounts = User.operational.where.not(id: excluded_user.id).order("RANDOM()").limit(1)
    if accounts.empty?
      # 如果排除后没有可用运营账号，尝试不排除
      accounts = User.operational.order("RANDOM()").limit(1)
      if accounts.empty?
        raise ArgumentError, "暂无可用运营账号，请先创建运营账号"
      end
    end
    accounts.first
  end
end
