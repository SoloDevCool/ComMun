class Admin::LoginLogsController < ApplicationController
  include Pagy::Method
  layout "admin"
  skip_before_action :check_license!
  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @pagy, @login_logs = pagy(:offset, UserLoginLog.includes(:user).recent, limit: 20)
    @today_count = UserLoginLog.where("created_at >= ?", Time.current.beginning_of_day).count
    @today_users = UserLoginLog.where("created_at >= ?", Time.current.beginning_of_day).distinct.count(:user_id)
  end

  private

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
