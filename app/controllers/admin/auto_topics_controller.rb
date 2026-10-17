class Admin::AutoTopicsController < ApplicationController
  layout "admin"
  include Pagy::Method

  before_action :authenticate_user!
  before_action :require_admin!

  def index
    @today = Date.current
    @today_tasks = AutoTopicTask.today.recent
    @today_stats = {
      pending: @today_tasks.pending.count,
      processing: @today_tasks.processing.count,
      completed: @today_tasks.completed.count,
      failed: @today_tasks.failed.count
    }

    # History (past 7 days)
    @date_range = (7.days.ago.to_date..Date.current).to_a.reverse
    @history_stats = @date_range.map do |date|
      tasks = AutoTopicTask.for_date(date)
      { date: date, total: tasks.count, completed: tasks.completed.count, failed: tasks.failed.count }
    end

    # Paginated history for all tasks
    all_tasks = AutoTopicTask.recent.includes(:topic, :draft)
    @pagy, @all_tasks = pagy(:offset, all_tasks, limit: 20)

    @nodes = Node.system_ordered + Node.interest_ordered
  end

  def trigger_now
    unless AutoTopicSchedulerService.enabled?
      redirect_to admin_auto_topics_path, alert: t("admin.flash.m108")
      return
    end

    count = SiteSetting.get("auto_topic_daily_count", default: "0").to_i
    today = Date.current
    existing = AutoTopicTask.today.count

    if existing >= count
      redirect_to admin_auto_topics_path, alert: t("admin.flash.m020", count: existing)
      return
    end

    create_count = count - existing
    AutoTopicSchedulerService.create_tasks_for_date!(today, create_count)

    # 立即调度：将所有今天 pending 的任务全部投递到队列（不限 scheduled_at）
    dispatched_count = 0
    AutoTopicTask.today.pending.find_each do |task|
      AutoTopicGenerateJob.perform_later(task.id)
      dispatched_count += 1
    end

    message = "已调度 #{create_count} 条任务，#{dispatched_count} 条已加入执行队列"
    redirect_to admin_auto_topics_path, notice: message
  end

  def dispatch_pending
    pending_tasks = AutoTopicTask.pending
    count = pending_tasks.count

    if count == 0
      redirect_to admin_auto_topics_path, alert: t("admin.flash.m092")
      return
    end

    dispatched = 0
    pending_tasks.find_each do |task|
      AutoTopicGenerateJob.perform_later(task.id)
      dispatched += 1
    end

    redirect_to admin_auto_topics_path, notice: t("admin.flash.m056", count: dispatched)
  end

  def retry_task
    task = AutoTopicTask.find(params[:id])
    task.update!(status: :pending)
    AutoTopicGenerateJob.perform_later(task.id)
    redirect_to admin_auto_topics_path, notice: t("admin.flash.m021")
  end

  private

  def require_admin!
    unless current_user&.admin? || current_user&.operator?
      redirect_to root_path, alert: t("admin.flash.m086")
    end
  end
end
