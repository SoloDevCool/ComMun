class Admin::QbReviewsController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :require_plugin_enabled!
  include Pagy::Method
  before_action :set_qb_question, only: [:show, :approve, :reject]

  def index
    @status = params[:status].presence || "pending"
    @pagy, @qb_questions = pagy(:offset, QbQuestion.includes(:qb_exam, :user)
      .where(status: @status)
      .order(created_at: :desc), limit: 20)
  end

  def show
  end

  def approve
    @qb_question.approve!(current_user.id)
    redirect_back fallback_location: admin_qb_reviews_path(status: "pending"), notice: t("admin.flash.m148", question: @qb_question.content.truncate(20))
  end

  def reject
    reason = params[:rejection_reason].presence
    @qb_question.reject!(reason, current_user.id)
    redirect_back fallback_location: admin_qb_reviews_path(status: "pending"), notice: t("admin.flash.m151")
  end

  def batch_approve
    question_ids = params[:question_ids]
    if question_ids.blank?
      redirect_back fallback_location: admin_qb_reviews_path(status: "pending"), alert: t("admin.flash.m136")
      return
    end
    QbQuestion.where(id: question_ids, status: "pending").find_each do |q|
      q.approve!(current_user.id)
    end
    redirect_back fallback_location: admin_qb_reviews_path(status: "pending"), notice: t("admin.flash.m061", count: question_ids.size)
  end

  def batch_reject
    question_ids = params[:question_ids]
    reason = params[:rejection_reason].presence
    if question_ids.blank?
      redirect_back fallback_location: admin_qb_reviews_path(status: "pending"), alert: t("admin.flash.m136")
      return
    end
    QbQuestion.where(id: question_ids, status: "pending").find_each do |q|
      q.reject!(reason, current_user.id)
    end
    redirect_back fallback_location: admin_qb_reviews_path(status: "pending"), notice: t("admin.flash.m059", count: question_ids.size)
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("question_banks")
      redirect_to admin_root_path, alert: "题库插件未启用，请先在「插件管理」中启用。"
    end
  end

  def set_qb_question
    @qb_question = QbQuestion.find(params[:id])
  end

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
