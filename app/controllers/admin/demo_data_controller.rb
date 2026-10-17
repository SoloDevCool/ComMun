# frozen_string_literal: true

class Admin::DemoDataController < ApplicationController
  layout "admin"
  skip_before_action :check_license!
  before_action :authenticate_user!
  before_action :require_admin!

  # POST /admin/demo_data/import
  def import
    stats = Admin::DemoDataService.import!
    summary = stats.map { |k, v| "#{k} #{v}" }.join("、")
    redirect_to admin_root_path, notice: t("admin.flash.m095", summary: summary)
  rescue StandardError => e
    Rails.logger.error("Demo data import failed: #{e.class} #{e.message}")
    redirect_to admin_root_path, alert: t("admin.flash.m094", message: e.message)
  end

  # POST /admin/demo_data/clear
  def clear
    result = Admin::DemoDataService.clear!
    redirect_to admin_root_path, notice: "已清空测试数据（用户 #{result[:users]} 个、主题 #{result[:topics]} 篇）"
  rescue StandardError => e
    Rails.logger.error("Demo data clear failed: #{e.class} #{e.message}")
    redirect_to admin_root_path, alert: "清空测试数据失败：#{e.message}"
  end

  private

  def require_admin!
    return if current_user&.admin?

    redirect_to root_path, alert: t("admin.flash.m086")
  end
end
