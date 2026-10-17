class Admin::UsersController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!
  before_action :set_user, only: [:update, :ban, :unban]

  def index
    @collection = User.real_users.order(created_at: :desc)
    @q = params[:q].to_s.strip
    @status = params[:status].presence || "all"

    if @status == "banned"
      @collection = @collection.banned
    end

    if @q.present?
      @collection = @collection.where(
        "users.username ILIKE ? OR users.email ILIKE ?",
        "%#{User.sanitize_sql_like(@q)}%", "%#{User.sanitize_sql_like(@q)}%"
      )
    end

    @pagy, @users = pagy(:offset, @collection, limit: 15)
  end

  def update
    if params[:role].present? && Role.exists_with_key?(params[:role])
      @user.update!(role: params[:role])
      redirect_to admin_users_path, notice: t("admin.flash.m055", email: @user.email, role: @user.role_label)
    else
      redirect_to admin_users_path, alert: t("admin.flash.m084")
    end
  end

  def ban
    if @user == current_user
      redirect_to admin_users_path, alert: t("admin.flash.m010")
      return
    end

    duration_param = params[:duration]
    reason = params[:reason].to_s.strip

    duration = case duration_param
               when "1d"  then 1.day
               when "3d"  then 3.days
               when "7d"  then 7.days
               when "15d" then 15.days
               when "30d" then 30.days
               when "90d" then 90.days
               when "permanent" then :permanent
               else nil
               end

    if duration.nil?
      redirect_to admin_users_path, alert: t("admin.flash.m082")
      return
    end

    @user.ban!(duration: duration, reason: reason, banned_by: current_user)
    redirect_to admin_users_path(status: params[:status]), notice: t("admin.flash.m052", email: @user.email)
  end

  def unban
    if @user == current_user
      redirect_to admin_users_path, alert: t("admin.flash.m009")
      return
    end

    @user.unban!(unbanned_by: current_user)
    redirect_to admin_users_path(status: params[:status]), notice: t("admin.flash.m066", email: @user.email)
  end

  private

  def set_user
    @user = User.real_users.find(params[:id])
  end

  def require_admin!
    unless current_user&.admin?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
