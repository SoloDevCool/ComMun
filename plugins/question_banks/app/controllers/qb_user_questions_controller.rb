class QbUserQuestionsController < ApplicationController
  before_action :check_feature_enabled!
  before_action :authenticate_user!
  before_action :set_qb_exam

  def new
    @qb_question = @qb_exam.qb_questions.new
    @qb_question.question_type = 0
  end

  def create
    @qb_question = @qb_exam.qb_questions.new(qb_question_params)
    @qb_question.user = current_user
    @qb_question.status = "pending"
    @qb_question.sort_order = @qb_exam.qb_questions.maximum(:sort_order).to_i + 1

    if @qb_question.save
      redirect_to profile_path(tab: "contributions"), notice: t("flash.qb_user_questions.submitted")
    else
      flash.now[:alert] = "提交失败：#{@qb_question.errors.full_messages.join('，')}"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def check_feature_enabled!
    unless Plugin.enabled?("question_banks")
      redirect_to root_path, alert: t("flash.question_banks.disabled")
    end
  end

  def set_qb_exam
    @qb_exam = QbExam.find(params[:question_bank_id])
    unless @qb_exam
      redirect_to question_banks_path, alert: t("flash.question_banks.subject_not_found")
      return
    end
  end

  def qb_question_params
    permitted = params.require(:qb_question).permit(:question_type, :category, :content, :answer, :explanation)
    raw_options = params[:qb_question][:options]
    if raw_options.present?
      permitted[:options] = raw_options.is_a?(String) ? JSON.parse(raw_options) : raw_options
    else
      permitted[:options] = []
    end
    permitted
  end
end
