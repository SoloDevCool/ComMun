class Admin::AutoCommentsController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @today = Date.current
    @today_tasks = AutoCommentTask.today.recent
    @today_stats = {
      pending: @today_tasks.pending.count,
      processing: @today_tasks.processing.count,
      completed: @today_tasks.completed.count,
      failed: @today_tasks.failed.count
    }

    # History (past 7 days)
    @date_range = (7.days.ago.to_date..Date.current).to_a.reverse
    @history_stats = @date_range.map do |date|
      tasks = AutoCommentTask.for_date(date)
      { date: date, total: tasks.count, completed: tasks.completed.count, failed: tasks.failed.count }
    end

    # Paginated history for all tasks
    all_tasks = AutoCommentTask.recent.includes(:topic, :comment)
    @pagy, @all_tasks = pagy(:offset, all_tasks, limit: 20)
  end

  def trigger_now
    unless AutoCommentSchedulerService.enabled?
      redirect_to admin_auto_comments_path, alert: t("admin.flash.m109")
      return
    end

    count = SiteSetting.get("auto_comment_daily_count", default: "0").to_i
    today = Date.current
    existing = AutoCommentTask.today.count

    if existing >= count
      redirect_to admin_auto_comments_path, alert: t("admin.flash.m020", count: existing)
      return
    end

    create_count = count - existing
    AutoCommentSchedulerService.create_tasks_for_date!(today, create_count)

    # 立即调度：将所有今天 pending 的任务全部投递到队列（不限 scheduled_at）
    dispatched_count = 0
    AutoCommentTask.today.pending.find_each do |task|
      AutoCommentGenerateJob.perform_later(task.id)
      dispatched_count += 1
    end

    message = "已调度 #{create_count} 条任务，#{dispatched_count} 条已加入执行队列"
    redirect_to admin_auto_comments_path, notice: message
  end

  def dispatch_pending
    pending_tasks = AutoCommentTask.pending
    count = pending_tasks.count

    if count == 0
      redirect_to admin_auto_comments_path, alert: t("admin.flash.m092")
      return
    end

    dispatched = 0
    pending_tasks.find_each do |task|
      AutoCommentGenerateJob.perform_later(task.id)
      dispatched += 1
    end

    redirect_to admin_auto_comments_path, notice: t("admin.flash.m056", count: dispatched)
  end

  def retry_task
    task = AutoCommentTask.find(params[:id])
    task.update!(status: :pending)
    AutoCommentGenerateJob.perform_later(task.id)
    redirect_to admin_auto_comments_path, notice: t("admin.flash.m021")
  end

  private

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
