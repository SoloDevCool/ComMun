class TopicsController < ApplicationController
  include Pagy::Method

  before_action :authenticate_user!, except: [:index, :show, :search]
  before_action :set_topic, only: [:show, :edit, :update, :destroy, :pin, :unpin, :unlock_energy_block]
  before_action :set_nodes, only: [:new, :create, :edit, :update]

  def index
    @scope = params[:scope].presence || "hot"
    @scope = "recent" unless %w[recent hot followed trending].include?(@scope)
    @node = Node.find_by(slug: params[:node]) if params[:node]
    @kind = params[:kind].presence if params[:kind].in?(%w[system interest])
    @user_id = params[:user_id].presence

    # 学员权限控制
    if user_signed_in? && current_user.student?
      @all_nodes = Node.system_ordered + current_user.member_nodes
      @hot_nodes = (Node.system_ordered + current_user.member_nodes).sort_by(&:topics_count).reverse.first(10)
    else
      @all_nodes = Node.system_ordered + Node.interest_ordered
      @hot_nodes = Node.order(topics_count: :desc).limit(10)
    end

    @community_stats = community_stats

    if user_signed_in?
      @sidebar_followed_nodes = current_user.followed_nodes.left_joins(:node_follows)
        .select("nodes.*, COUNT(node_follows.id) AS followers_count")
        .group("nodes.id").order("followers_count DESC").limit(8)
      @followed_node_ids = current_user.followed_node_ids
    else
      @followed_node_ids = []
    end

    # 按类型查看版块列表
    if @kind && !@node
      @node_tab = params[:node_tab].presence || "all"
      if @kind == "system"
        @kind_nodes = Node.system_ordered
      else
        @kind_nodes = Node.interest_ordered
      end
      if user_signed_in?
        @followed_nodes = current_user.followed_nodes.where(kind: @kind).order(topics_count: :desc)
        @followed_node_ids = current_user.followed_node_ids
      else
        @followed_nodes = Node.none
        @followed_node_ids = []
      end
      return
    end

    collection = case @scope
    when "hot"
      base_topics.hot
    when "followed"
      if user_signed_in?
        base_topics.from_followed(current_user).recent
      else
        Topic.none
      end
    when "trending"
      base_topics.trending
    else
      base_topics.pinned_first
    end

    collection = collection.not_blocked_by(current_user) if user_signed_in?
    collection = collection.where.not(moderation_status: "review")

    # polls 插件禁用时无 poll 关联，避免 AssociationNotFoundError
    includes_scopes = Topic.polls_available? ? [:poll, :user, :node, :last_reply_user] : [:user, :node, :last_reply_user]
    @pagy, @topics = pagy(:offset, collection.includes(*includes_scopes), limit: 25)
  end

  def show
    @topic.increment!(:views_count)
    @all_nodes = Node.system_ordered + Node.interest_ordered
    @hot_nodes = Node.order(topics_count: :desc).limit(10)
    @community_stats = community_stats
    @comments = @topic.comments.includes(:user, :parent).order(:created_at).where.not(moderation_status: "review")
    @poll = Topic.polls_available? ? @topic.poll : nil
    @poll&.poll_options&.includes(:votes)&.load
    if user_signed_in?
      @sidebar_followed_nodes = current_user.followed_nodes.left_joins(:node_follows)
        .select("nodes.*, COUNT(node_follows.id) AS followers_count")
        .group("nodes.id").order("followers_count DESC").limit(8)
      @followed_node_ids = current_user.followed_node_ids
    else
      @followed_node_ids = []
    end
  end

  def new
    @topic = Topic.new
    # 检查发帖权限
    if current_user.student?
      accessible_node_ids = current_user.member_nodes.pluck(:id)
      @nodes = Node.where(id: accessible_node_ids)
      if @nodes.empty?
        redirect_to topics_path, alert: t("flash.topics.no_post_permission")
      end
    else
      @nodes = Node.system_ordered + Node.interest_ordered
    end
  end

  def create
    @topic = current_user.topics.build(topic_params)

    # 检查发帖权限
    if current_user.student? && !current_user.student_of?(@topic.node)
      @topic.errors.add(:node_id, "没有权限在该版块发帖")
      render :new, status: :forbidden
      return
    end

    if @topic.save
      @topic.generate_slug!
      notify_indexnow(@topic)
      redirect_to_topic @topic, notice: t("flash.topics.created")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize_topic!
  end

  def update
    authorize_topic!
    if @topic.update(topic_params)
      @topic.generate_slug! if @topic.saved_change_to_title?
      notify_indexnow(@topic)
      redirect_to_topic @topic, notice: t("flash.topics.updated")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize_topic!
    if @topic.destroy
      redirect_to topics_path, notice: t("flash.topics.deleted")
    else
      redirect_to_topic @topic, alert: t("flash.topics.delete_failed")
    end
  end

  def pin
    unless current_user.admin?
      redirect_to_topic @topic, alert: t("flash.forbidden")
      return
    end
    @topic.update!(pinned: true, pinned_at: Time.current)
    redirect_back fallback_location: topic_location(@topic), notice: t("flash.topics.pinned")
  end

  def unpin
    unless current_user.admin?
      redirect_to_topic @topic, alert: t("flash.forbidden")
      return
    end
    @topic.update!(pinned: false, pinned_at: nil)
    redirect_back fallback_location: { node: @topic.node.slug, action: 'show', slug: @topic.slug }, notice: t("flash.topics.unpinned")
  end

  def search
    @q = params[:q].to_s.strip
    if @q.blank?
      redirect_to topics_path, alert: t("flash.topics.keyword_required")
      return
    end
    # polls 插件禁用时无 poll 关联，避免 AssociationNotFoundError
    search_includes = Topic.polls_available? ? [:user, :node, :poll] : [:user, :node]
    search_results = Topic.search_by_keyword(@q).includes(*search_includes).recent
    search_results = search_results.not_blocked_by(current_user) if user_signed_in?
    search_results = search_results.where.not(moderation_status: "review")
    @pagy, @topics = pagy(:offset, search_results, limit: 25)
    @total_count = search_results.count
  end

  def unlock_energy_block
    block_index = params[:block_index].to_i
    cost = params[:cost].to_i

    respond_to do |format|
      if cost <= 0
        format.html { redirect_back fallback_location: topic_location(@topic), alert: t("flash.topics.invalid_points") }
        format.json { render json: { success: false, message: "请输入有效的酷能量数量" }, status: :unprocessable_entity }
        return
      end

      if @topic.user == current_user
        format.html { redirect_back fallback_location: topic_location(@topic), alert: t("flash.topics.cannot_unlock_own") }
        format.json { render json: { success: false, message: "不能解锁自己的内容" }, status: :unprocessable_entity }
        return
      end

      if @topic.unlock_energy_block!(current_user, block_index, cost)
        format.html { redirect_back fallback_location: topic_location(@topic), notice: t("flash.topics.unlocked") }
        format.json { render json: { success: true, message: "解锁成功", remaining_points: current_user.reload.points } }
      else
        alert_msg = @topic.errors.full_messages.first || "解锁失败"
        format.html { redirect_back fallback_location: topic_location(@topic), alert: alert_msg }
        format.json { render json: { success: false, message: alert_msg }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_topic
    if params[:slug].present?
      url_slug = params[:slug].to_s
      # 1. 自定义 slug
      @topic = Topic.find_by(slug: url_slug)
      # 2. "topic-<id>" 形式的回退 slug
      @topic ||= Topic.find_by(id: Regexp.last_match(1)) if url_slug.match?(/\Atopic-(\d+)\z/)
      # 3. 历史/未生成 slug 的主题：URL slug 由标题 parameterize 生成（与 Topic#url_slug 一致）
      if @topic.nil? && params[:node].present?
        node = Node.find_by(slug: params[:node])
        @topic = node.topics.find { |t| t.url_slug == url_slug } if node
      end
      # 4. 纯数字 slug 视为主题 ID
      @topic ||= Topic.find_by(id: url_slug) if url_slug.match?(/\A\d+\z/)
      raise ActiveRecord::RecordNotFound unless @topic
      if @topic.node&.slug != params[:node]
        redirect_to topic_path(@topic), status: :moved_permanently
      end
    else
      # 兼容 to_param 生成的 "219-30" 形式 ID，取前导数字
      @topic = Topic.find(params[:id].to_s[/\A\d+/])
    end
  end

  def set_nodes
    if current_user.student?
      @nodes = current_user.member_nodes
    else
      @nodes = Node.system_ordered + Node.interest_ordered
    end
  end

  def base_topics
    query = if params[:node]
      Topic.for_node(params[:node])
    elsif params[:kind].in?(%w[system interest])
      Topic.joins(:node).where(nodes: { kind: params[:kind] })
    else
      Topic.all
    end

    query
  end

  def topic_params
    permitted = [:title, :content, :node_id, :is_repost, :source_url, :vip_only]
    # 投票嵌套属性仅在有 polls 插件时允许（插件提供 Poll 模型与 Topic 扩展）
    if Topic.polls_available?
      permitted << {
        poll_attributes: [
          :id, :_destroy,
          poll_options_attributes: [:id, :title, :_destroy]
        ]
      }
    end
    params.require(:topic).permit(*permitted)
  end

  def authorize_topic!
    unless @topic.user == current_user || current_user.admin?
      redirect_to topics_path, alert: t("flash.forbidden")
    end
  end

  def community_stats
    fake_users = SiteSetting.get("fake_users_count", default: "0").to_i
    fake_topics = SiteSetting.get("fake_topics_count", default: "0").to_i
    fake_comments = SiteSetting.get("fake_comments_count", default: "0").to_i

    {
      users_count: User.count + fake_users,
      topics_count: Topic.count + fake_topics,
      comments_count: Comment.count + fake_comments
    }
  end

  def notify_indexnow(topic)
    return unless topic.node.present? && topic.slug.present?
    url = topic_url(topic, host: request.host_with_port)
    IndexnowService.notify(url)
  end
end
