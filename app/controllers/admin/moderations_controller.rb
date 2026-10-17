class Admin::ModerationsController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @scope = params[:scope].presence || "pending"
    @type = params[:type].presence || "topic"

    case @type
    when "comment"
      collection = Comment.moderation_pending.includes(:user, :topic)
      @total_pending = Comment.moderation_pending.count
    else
      collection = Topic.moderation_pending.includes(:user, :node)
      @total_pending = Topic.moderation_pending.count
    end

    @topic_pending_count = Topic.moderation_pending.count
    @comment_pending_count = Comment.moderation_pending.count

    if @scope == "blocked"
      case @type
      when "comment"
        collection = Comment.moderation_blocked.includes(:user, :topic)
      else
        collection = Topic.moderation_blocked.includes(:user, :node)
      end
    end

    @pagy, @items = pagy(:offset, collection.order(created_at: :desc), limit: 20)
  end

  def approve
    find_item

    if @item.update(moderation_status: "pass")
      notice_text = @item.is_a?(Topic) ? "话题「#{@item.title.truncate(30)}」已审核通过" : "评论已审核通过"
      redirect_back fallback_location: admin_moderations_path, notice: notice_text
    else
      redirect_back fallback_location: admin_moderations_path, alert: t("admin.flash.m077")
    end
  end

  def reject
    find_item

    if @item.update(moderation_status: "block")
      notice_text = @item.is_a?(Topic) ? "话题「#{@item.title.truncate(30)}」已被拒绝" : "评论已被拒绝"
      redirect_back fallback_location: admin_moderations_path, notice: notice_text
    else
      redirect_back fallback_location: admin_moderations_path, alert: t("admin.flash.m077")
    end
  end

  def batch_approve
    ids = params[:ids].to_s.split(",").map(&:to_i).reject(&:zero?)
    type = params[:type].presence || "topic"

    if ids.empty?
      redirect_back fallback_location: admin_moderations_path, alert: t("admin.flash.m131")
      return
    end

    updated = case type
              when "comment"
                Comment.where(id: ids).update_all(moderation_status: "pass")
              else
                Topic.where(id: ids).update_all(moderation_status: "pass")
              end

    redirect_back fallback_location: admin_moderations_path, notice: t("admin.flash.m062", count: updated)
  end

  def batch_reject
    ids = params[:ids].to_s.split(",").map(&:to_i).reject(&:zero?)
    type = params[:type].presence || "topic"

    if ids.empty?
      redirect_back fallback_location: admin_moderations_path, alert: t("admin.flash.m131")
      return
    end

    updated = case type
              when "comment"
                Comment.where(id: ids).update_all(moderation_status: "block")
              else
                Topic.where(id: ids).update_all(moderation_status: "block")
              end

    redirect_back fallback_location: admin_moderations_path, notice: t("admin.flash.m060", count: updated)
  end

  private

  def find_item
    type = params[:type].presence || "topic"

    @item = case type
            when "comment" then Comment.find(params[:id])
            else Topic.find(params[:id])
            end
  end

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
