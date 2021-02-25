# Load the Rails application.
require_relative 'application'

ActionMailer::Base.delivery_method = :smtp

ActionMailer::Base.smtp_settings = {
  :user_name => Rails.application.credentials.dig(:sendgrid_username),
  :password => Rails.application.credentials.dig(:sendgrid_password),
  :domain => 'crm.aiforce.com.au',
  :address => 'smtp.sendgrid.net',
  :port => 587,
  :authentication => :plain,
  :enable_starttls_auto => true
}

# Initialize the Rails application.
Rails.application.initialize!
