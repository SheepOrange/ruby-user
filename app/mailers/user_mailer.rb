class UserMailer < ApplicationMailer
  default :from => "auth@bangbang.com.au"

  def send_verification_email(email, code)
    @code = code
    mail(to: email, subject: "Email verification")
  end

end
