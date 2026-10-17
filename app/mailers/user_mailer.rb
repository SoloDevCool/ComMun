class UserMailer < ApplicationMailer
  def self.send_notification(user, subject, html_body)
    personalized_subject = subject.gsub("{name}", user.display_name).gsub("{email}", user.email)
    personalized_body = html_body.gsub("{name}", user.display_name).gsub("{email}", user.email)

    result = EmailService.send_email(
      to: user.email,
      subject: personalized_subject,
      body: personalized_body
    )

    { user: user, **result }
  end
end
