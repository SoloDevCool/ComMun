class Admin::DashboardController < ApplicationController
  layout "admin"
  skip_before_action :check_license!
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    unless current_user&.admin?
      redirect_to admin_topic_operations_path
      return
    end
    @total_users = User.real_users.count
    @admin_count = User.real_users.admin.count
    @vip_count = User.real_users.vip.count
    @regular_count = User.real_users.user.count
    @recent_users = User.real_users.order(created_at: :desc).limit(5)
    @pending_topic_count = Topic.moderation_pending.count
    @pending_comment_count = Comment.moderation_pending.count

    # 在线人数统计
    @online_count = User.real_users.online.count

    # 用户访问统计
    @today_login_count = UserLoginLog.today.distinct.count(:user_id)
    @province_distribution = UserLoginLog
      .where.not(province: "")
      .group(:province)
      .select(:province, "COUNT(DISTINCT user_id) as user_count")
      .map { |r| [ r.province, r.user_count.to_i ] }
      .sort_by { |_, v| -v }
      .first(10)
    @country_distribution = UserLoginLog
      .where.not(country: "")
      .group(:country)
      .select(:country, "COUNT(DISTINCT user_id) as user_count")
      .map { |r| [ r.country, r.user_count.to_i ] }
      .sort_by { |_, v| -v }
  end

  private

  def require_admin!
    # 放行顺序：管理员级角色 -> 运营级角色 -> 被授予 admin.dashboard 权限点的自定义角色
    return if current_user&.admin?
    return if current_user&.operator?
    return if current_user&.can?("admin.dashboard")
    redirect_to root_path, alert: t("admin.flash.m086")
  end
end
