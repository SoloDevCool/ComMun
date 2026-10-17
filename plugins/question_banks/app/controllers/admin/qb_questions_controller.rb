class Admin::QbQuestionsController < ApplicationController
  layout "admin"
  before_action :authenticate_user!
  before_action :require_admin!
  before_action :require_plugin_enabled!
  before_action :set_qb_exam
  before_action :set_qb_question, only: [:edit, :update, :destroy]

  def index
    @qb_questions = @qb_exam.qb_questions.ordered
    @qb_question = QbQuestion.new
  end

  def new
    @qb_question = @qb_exam.qb_questions.new
    @qb_question.question_type = 0
  end

  def create
    @qb_question = @qb_exam.qb_questions.new(qb_question_params)
    if @qb_question.save
      redirect_to admin_qb_exam_qb_questions_path(@qb_exam), notice: t("admin.flash.m149")
    else
      @qb_questions = @qb_exam.qb_questions.ordered
      flash.now[:alert] = "创建失败：#{@qb_question.errors.full_messages.join('，')}"
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @qb_question.update(qb_question_params)
      redirect_to admin_qb_exam_qb_questions_path(@qb_exam), notice: t("admin.flash.m152")
    else
      flash.now[:alert] = "更新失败：#{@qb_question.errors.full_messages.join('，')}"
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @qb_question.destroy
    redirect_to admin_qb_exam_qb_questions_path(@qb_exam), notice: t("admin.flash.m150")
  end

  private

  def require_plugin_enabled!
    unless Plugin.enabled?("question_banks")
      redirect_to admin_root_path, alert: "题库插件未启用，请先在「插件管理」中启用。"
    end
  end

  def set_qb_exam
    @qb_exam = QbExam.find(params[:qb_exam_id])
  end

  def set_qb_question
    @qb_question = @qb_exam.qb_questions.find(params[:id])
  end

  def qb_question_params
    permitted = params.require(:qb_question).permit(:question_type, :category, :content, :answer, :explanation, :sort_order)
    raw_options = params[:qb_question][:options]
    if raw_options.present?
      permitted[:options] = raw_options.is_a?(String) ? JSON.parse(raw_options) : raw_options
    else
      permitted[:options] = []
    end
    permitted
  end

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
