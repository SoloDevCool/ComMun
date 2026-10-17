class Admin::TopicOperationsController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @scope = params[:scope].presence || "all"
    @q = params[:q].to_s.strip
    @node_id = params[:node_id].to_s.strip
    collection = Topic.where(published_by_operational: true).includes(:user, :node)
    if @scope == "pinned"
      collection = collection.where(pinned: true)
    elsif @scope == "repost"
      collection = collection.where(is_repost: true)
    end
    if @q.present?
      collection = collection.where("topics.title ILIKE ? OR topics.content ILIKE ?",
        "%#{Topic.sanitize_sql_like(@q)}%", "%#{Topic.sanitize_sql_like(@q)}%")
    end
    if @node_id.present?
      collection = collection.where(node_id: @node_id)
    end
    @pagy, @topics = pagy(:offset, collection.order(created_at: :desc), limit: 15)
    @nodes = Node.system_ordered + Node.interest_ordered
    @operational_count = User.operational.count

    @drafts = TopicDraft.includes(:node, :user).recent.limit(10)
  end

  def new
    @nodes = Node.system_ordered + Node.interest_ordered
    @topic = Topic.new
    @draft_id = params[:draft_id]
    @draft = @draft_id ? TopicDraft.find_by(id: @draft_id) : nil
    if @draft
      @topic = Topic.new(
        title: @draft.title,
        content: @draft.content,
        node_id: @draft.node_id,
        is_repost: @draft.is_repost,
        source_url: @draft.source_url
      )
    end
  end

  def ai_generate
    task_id = SecureRandom.uuid

    AiGenerateJob.perform_later(
      task_id: task_id,
      type: "topic",
      node_id: params[:node_id],
      system_prompt: params[:system_prompt],
      web_search: params[:web_search] == "true"
    )

    render json: { success: true, task_id: task_id }
  end

  def ai_status
    task_id = params[:task_id]
    cached = Rails.cache.read("ai_generate:#{task_id}")

    if cached.nil?
      render json: { status: "pending" }
    elsif cached[:status] == "running"
      render json: { status: "running" }
    else
      result = cached[:result]
      if result[:success]
        render json: { status: "completed", success: true, title: result[:title], content: result[:content] }
      else
        render json: { status: "completed", success: false, error: result[:error] }
      end
    end
  end

  def create
    service = TopicOperationService.new(
      title: params[:topic][:title],
      content: params[:topic][:content],
      node_id: params[:topic][:node_id],
      is_repost: params[:topic][:is_repost] == "1",
      source_url: params[:topic][:source_url]
    )

    result = service.call

    if result[:success]
      if params[:draft_id].present?
        TopicDraft.where(id: params[:draft_id], user_id: current_user.id).destroy_all
      end
      redirect_to admin_topic_operations_path, notice: t("admin.flash.m124", topic_title: result[:topic].title, user_name: result[:user].display_name)
    else
      @nodes = Node.system_ordered + Node.interest_ordered
      @topic = Topic.new(title: params[:topic][:title], content: params[:topic][:content], node_id: params[:topic][:node_id])
      @draft_id = params[:draft_id]
      flash.now[:alert] = result[:message]
      render :new, status: :unprocessable_entity
    end
  end

  def save_draft
    @draft = TopicDraft.new(
      title: params[:topic][:title].to_s.strip,
      content: params[:topic][:content].to_s.strip,
      node_id: params[:topic][:node_id],
      is_repost: params[:topic][:is_repost] == "1",
      source_url: params[:topic][:source_url],
      user: current_user
    )

    if @draft.save
      if params[:draft_id].present?
        TopicDraft.where(id: params[:draft_id], user_id: current_user.id).where.not(id: @draft.id).destroy_all
      end
      render json: { success: true, draft_id: @draft.id, message: t("admin.flash.m112") }
    else
      render json: { success: false, message: "保存失败：#{@draft.errors.full_messages.join(', ')}" }
    end
  end

  def publish_draft
    draft = TopicDraft.find(params[:id])
    service = TopicOperationService.new(
      title: draft.title,
      content: draft.content,
      node_id: draft.node_id,
      is_repost: draft.is_repost,
      source_url: draft.source_url
    )

    result = service.call

    if result[:success]
      draft.destroy
      redirect_to admin_topic_operations_path, notice: t("admin.flash.m124", topic_title: result[:topic].title, user_name: result[:user].display_name)
    else
      redirect_to edit_admin_topic_draft_path(draft), alert: result[:message]
    end
  end

  def batch_destroy
    ids = params[:ids].to_s.split(",").map(&:to_i).reject(&:zero?)
    if ids.empty?
      redirect_to admin_topic_operations_path, alert: t("admin.flash.m128")
      return
    end

    topics = Topic.where(published_by_operational: true, id: ids)
    destroyed = topics.destroy_all.size

    redirect_to admin_topic_operations_path, notice: t("admin.flash.m050", count: destroyed)
  end

  def destroy
    @topic = Topic.where(published_by_operational: true).find(params[:id])
    if @topic.destroy
      redirect_to admin_topic_operations_path, notice: t("admin.flash.m123", title: @topic.title)
    else
      redirect_to admin_topic_operations_path, alert: t("admin.flash.m029")
    end
  end

  private

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
