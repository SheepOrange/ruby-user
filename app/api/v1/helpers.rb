module V1
  module Helpers
    def authenticate!
      current_user or raise error!(result: false, message: I18n.t("activerecord.errors.messages.authenticate_failed"), status: 401)
    end

    # return current user if no user return error
    def current_user
      user = User.available.find_by(uid: headers['X-Auth-Id'])
      error!(result: false, message: I18n.t("activerecord.errors.messages.authenticate_failed"), status: 422) if user == nil
      if user && verified_session_key(user)
        @current_user = user
        return user
      else
        return nil
      end
    end

    # return current user if no user return nil
    def current_user?
      user = User.available.find_by(uid: headers['X-Auth-Id'])
      return nil if user == nil
      if user && verified_session_key(user)
        user.update(lastoperationtime: Time.now)
        return user
      else
        return nil
      end
    end

    def update_tracked_fields(user)
      old_current, new_current = user.current_sign_in_at, Time.now
      user.last_sign_in_at     = old_current || new_current
      user.current_sign_in_at  = new_current

      old_current, new_current = user.current_sign_in_ip, headers['X-Forwarded-For']
      user.last_sign_in_ip     = old_current || new_current
      user.current_sign_in_ip  = new_current

      user.sign_in_count += 1
      user.save(validate: false)
    end

    def phone_valid?(phone)
      if PhoneUtils.valid?(phone)
        true
      else
        error!(result: false, message: I18n.t("activerecord.errors.messages.attribute_invalid", attr: I18n.t('activerecord.attributes.user.mobile')), status: 422)
      end
    end

    def email_valid?(email)
      error!(
        result: false,
        message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: I18n.t('activerecord.attributes.user.email')),
        status: 422
      ) unless email =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\z/i
    end

    #send sms code 1 times/minute or 5 times/hour
    def check_sms_limit(phone)
      phone_hour = Rails.cache.read("#{phone}_hour")
      limit = phone_hour.nil? ? 0 : phone_hour[0]
      expire_time = phone_hour.nil? ? Time.now + 1.hour : phone_hour[1]
      if Rails.cache.read("#{phone}_minute") or (limit > 5)
        raise error!(result: false, message: I18n.t("activerecord.errors.messages.sms_limit"), status: 422)
      else
        Rails.cache.write("#{phone}_minute", 1 , expires_in: 1.minute)
        Rails.cache.write("#{phone}_hour", [limit+1,expire_time], expires_in: (expire_time-Time.now).seconds)
      end
    end

    def verify_email_verify_code(email, code)
      return false unless Rails.cache.read("#{email}_verify_code")
      code == Rails.cache.read("#{email}_verify_code")
    end

    def verified_session_key(user)
      return false unless Rails.cache.read("#{user.uid}_session_key")
      user.encrypted_session_key == headers['X-Auth-Token']
    end


    def headers
      request.headers
    end

    def set_locale
      locale = headers['X-Auth-Locale'].to_s == 'zh-CN' ? 'zh-CN' : 'en'
      I18n.locale = locale
    end

    def response_format
      present :result, true
      present :status, 200
    end

    def request_format(req)
      req.headers['accept'] = '*/*'
      req.headers['Content-Type'] = "application/json"
    end

    def present_save_error(record)
      error!(
        result: false,
        message: record.errors.full_messages.join(','),
        status: 422
      )
    end
  end
end
