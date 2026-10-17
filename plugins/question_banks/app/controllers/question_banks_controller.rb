class QuestionBanksController < ApplicationController
  before_action :check_feature_enabled!
  before_action :set_qb_exam, only: [:show, :practice, :submit, :wrong]
  helper_method :format_time_spent

  def index
    # Group exams by level, using exam's own color for each level group
    grouped = QbExam.ordered.group_by(&:level)
    @exam_types = grouped.map do |level, exams|
      representative = exams.first
      {
        id: level,
        name: level,
        icon: "bi-bookmark",
        color: representative.color,
        description: representative.type_name,
        question_count: exams.sum(&:question_count),
        exams: exams.map { |e|
          {
            name: e.name,
            code: e.code,
            question_count: e.question_count,
            description: e.description,
            categories: e.categories || []
          }
        }
      }
    end
  end

  def show
    @daily_done = daily_done_today?
    @recent_practices = recent_practices
    @chapter_list = @qb_exam.qb_questions.approved.ordered.pluck(:category).uniq.compact
    @chapter_counts = @qb_exam.qb_questions.approved.unscope(:order).group(:category).count
    @wrong_count = wrong_question_ids_for(current_user).length if current_user
  end

  def practice
    @mode = params[:mode] || 'chapter'
    if @mode == 'wrong'
      redirect_to wrong_question_bank_path(id: @qb_exam.code)
      return
    end
    unless %w[daily chapter exam].include?(@mode)
      redirect_to question_bank_path(id: @qb_exam.code), alert: t("flash.question_banks.invalid_mode")
      return
    end

    if @mode == 'daily' && daily_done_today?
      redirect_to question_bank_path(id: @qb_exam.code), alert: t("flash.question_banks.daily_limit")
      return
    end

    questions = @qb_exam.qb_questions.approved.ordered

    case @mode
    when 'daily'
      @mode_name = "每日一练"
      @mode_desc = "每天精选 5 道题，碎片时间高效刷题"
      @mode_icon = "bi-calendar-check"
      count = [5, questions.count].min
      seed_val = Digest::MD5.hexdigest(Date.current.to_s + @qb_exam.code).to_i(16)
      rng = Random.new(seed_val)
      questions = questions.sample(count, random: rng).sort_by(&:sort_order)
    when 'chapter'
      @category = params[:category].presence
      if @category
        questions = questions.where(category: @category)
        if questions.empty?
          redirect_to question_bank_path(id: @qb_exam.code), alert: t("flash.question_banks.chapter_empty")
          return
        end
        @mode_name = "章节练习"
        @mode_desc = "章节：#{@category}"
        @mode_icon = "bi-book"
      else
        @mode_name = "章节练习"
        @mode_desc = "选择章节，针对性练习薄弱知识点"
        @mode_icon = "bi-book"
      end
    when 'exam'
      @mode_name = "试卷模式"
      @mode_desc = "模拟真实考试环境，限时答题"
      @mode_icon = "bi-file-earmark-text"
    end

    @questions = questions.map(&:as_json_for_practice)
  end

  def submit
    unless request.format.json?
      redirect_to question_banks_path
      return
    end

    unless current_user
      render json: { success: false, message: "请先登录" }, status: :unauthorized
      return
    end

    mode = params[:mode] || 'chapter'
    answers_data = params[:answers] || []
    time_spent = params[:time_spent].to_i

    correct_count = 0
    wrong_count = 0
    unanswered_count = 0

    practice = QbPractice.create!(
      user: current_user,
      qb_exam: @qb_exam,
      mode: mode,
      total_count: answers_data.size,
      correct_count: 0,
      wrong_count: 0,
      unanswered_count: 0,
      time_spent: time_spent,
      completed: true
    )

    answers_data.each do |answer_data|
      question = @qb_exam.qb_questions.find_by(id: answer_data[:question_id])
      next unless question

      selected = answer_data[:selected_option]

      if selected.nil?
        unanswered_count += 1
        is_correct = false
      elsif selected == question.answer
        correct_count += 1
        is_correct = true
      else
        wrong_count += 1
        is_correct = false
      end

      practice.qb_answers.create!(
        qb_question: question,
        selected_option: selected,
        is_correct: is_correct
      )
    end

    practice.update!(
      correct_count: correct_count,
      wrong_count: wrong_count,
      unanswered_count: unanswered_count
    )

    render json: {
      success: true,
      practice_id: practice.id,
      correct_count: correct_count,
      wrong_count: wrong_count,
      unanswered_count: unanswered_count,
      total_count: answers_data.size,
      accuracy: practice.accuracy,
      time_spent: time_spent
    }
  end

  def wrong
    unless current_user
      redirect_to question_bank_path(id: @qb_exam.code), alert: t("flash.question_banks.login_required")
      return
    end

    ids = wrong_question_ids_for(current_user)
    if ids.empty?
      redirect_to question_bank_path(id: @qb_exam.code), notice: t("flash.question_banks.no_wrong_questions")
      return
    end

    @questions = @qb_exam.qb_questions.where(id: ids).ordered.map(&:as_json_for_practice)
    @mode = 'wrong'
    @mode_name = "错题本"
    @mode_desc = "回顾做错的题目，查漏补缺"
    @mode_icon = "bi-x-circle"

    render :practice
  end

  private

  def check_feature_enabled!
    unless Plugin.enabled?("question_banks")
      redirect_to root_path, alert: t("flash.question_banks.disabled")
    end
  end

  def set_qb_exam
    @qb_exam = QbExam.find_by(code: params[:id])
    unless @qb_exam
      redirect_to question_banks_path, alert: t("flash.question_banks.subject_not_found")
      return
    end
  end

  def daily_done_today?
    return false unless current_user
    QbPractice.where(
      user: current_user,
      qb_exam: @qb_exam,
      mode: 'daily'
    ).where('created_at >= ?', Time.current.beginning_of_day).exists?
  end

  def recent_practices
    return [] unless current_user
    QbPractice.where(user: current_user, qb_exam: @qb_exam)
      .completed.recent.limit(10)
  end

  def format_time_spent(seconds)
    return '--' if seconds.nil? || seconds.zero?
    m = seconds / 60
    s = seconds % 60
    if m > 0
      "#{m}分#{s > 0 ? s.to_s + '秒' : ''}"
    else
      "#{s}秒"
    end
  end

  def wrong_question_ids_for(user)
    return [] unless user
    all_answers = QbAnswer.joins(:qb_practice)
      .where(qb_practices: { user_id: user.id, qb_exam_id: @qb_exam.id })
      .order(created_at: :asc)

    latest_status = {}
    all_answers.each { |a| latest_status[a.qb_question_id] = a.is_correct }
    latest_status.select { |_, v| v == false }.keys
  end
end
