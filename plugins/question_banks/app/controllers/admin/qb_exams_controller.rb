class Admin::QbExamsController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :require_plugin_enabled!
  before_action :set_qb_exam, only: [:edit, :update, :destroy]

  def index
    @qb_exams = QbExam.ordered
  end

  def new
    @qb_exam = QbExam.new
  end

  def create
    @qb_exam = QbExam.new(qb_exam_params)
    if @qb_exam.save
      redirect_to admin_qb_exams_path, notice: t("admin.flash.m105", name: @qb_exam.name)
    else
      flash.now[:alert] = "创建失败：#{@qb_exam.errors.full_messages.join('，')}"
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @qb_exam.update(qb_exam_params)
      redirect_to admin_qb_exams_path, notice: t("admin.flash.m107", name: @qb_exam.name)
    else
      flash.now[:alert] = "更新失败：#{@qb_exam.errors.full_messages.join('，')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @qb_exam.destroy
      redirect_to admin_qb_exams_path, notice: t("admin.flash.m106", name: @qb_exam.name)
    else
      redirect_to admin_qb_exams_path, alert: t("admin.flash.m029")
    end
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("question_banks")
      redirect_to admin_root_path, alert: "题库插件未启用，请先在「插件管理」中启用。"
    end
  end

  def set_qb_exam
    @qb_exam = QbExam.find(params[:id])
  end

  def qb_exam_params
    params.require(:qb_exam).permit(:name, :code, :type_name, :level, :color, :description, :total_count, :duration, :sort_order, categories: [])
  end

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
