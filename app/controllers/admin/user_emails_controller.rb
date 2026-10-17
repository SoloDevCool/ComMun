class Admin::UserEmailsController < Admin::DashboardController
  include Pagy::Method

  def index
    @users = User.real_users.order(created_at: :desc)
    @pagy, @users = pagy(:offset, @users, limit: 20)
  end

  def send_email
    user_ids = params[:user_ids].to_s.split(",").map(&:strip).reject(&:blank?)
    subject = params[:subject].to_s.strip
    html_body = params[:html_body].to_s.strip

    if user_ids.blank?
      redirect_back fallback_location: admin_user_emails_path, alert: t("admin.flash.m130")
      return
    end

    if subject.blank? || html_body.blank?
      redirect_back fallback_location: admin_user_emails_path, alert: t("admin.flash.m145")
      return
    end

    users = User.real_users.where(id: user_ids)
    success_count = 0
    error_details = []

    users.each do |user|
      result = UserMailer.send_notification(user, subject, html_body)
      if result[:success]
        success_count += 1
      else
        error_details << "#{user.display_name}（#{result[:message]}）"
      end
    end

    msg = "成功发送 #{success_count} 封邮件"
    msg += "，以下用户发送失败：#{error_details.join('、')}" if error_details.any?

    redirect_to admin_user_emails_path, notice: msg
  end
end
