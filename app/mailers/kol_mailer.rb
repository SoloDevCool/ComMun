class KolMailer < ApplicationMailer
  def self.send_invitation(kol, subject, html_body)
    personalized_subject = subject.gsub("{name}", kol.name)
    personalized_body = html_body.gsub("{name}", kol.name)

    result = EmailService.send_email(
      to: kol.email,
      subject: personalized_subject,
      body: personalized_body
    )

    { kol: kol, **result }
  end
end
