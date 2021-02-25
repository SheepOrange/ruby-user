module PhoneUtils
  class << self
    def sanitize(unsafe_phone)
      unsafe_phone.to_s.gsub(/\D/, '')
    end

    # Phone MUST contain international country code.
    def valid?(unsafe_phone)
      number = sanitize(unsafe_phone)
      phone  = Phonelib.parse(number)
      phone.valid?
    end

    def send_confirmation_sms(phone)
      code = Rails.cache.fetch "#{phone}_verify_code", expires_in: 5.minute do
        rand.to_s[2..7]
      end
      parsed_phone = Phonelib.parse(phone)
      app_name = ENV.fetch('APP_NAME', 'BangBang')
      Rails.logger.info("Sending SMS to #{phone} with code #{code}")
      res = case parsed_phone.country
            when 'CN'
              content = "您的手机验证码为: #{code}。请及时完成输入验证，否则验证码会失效。"
              send_sms_with_miaosai(parsed_phone.national(false), content)
            else
              content = "#{code} is your #{app_name} verification code. This code is valid for 5min."
              send_sms_with_twilio(phone, content)
            end

      return code if res
    end

    def send_sms(phone, content)
      parsed_phone = Phonelib.parse(phone)
      case parsed_phone.country
      when 'CN'
        send_sms_with_miaosai(parsed_phone.national(false), content)
      else
        send_sms_with_twilio(phone, content)
      end
    end

    def send_sms_with_miaosai(number, content)
      conn = faraday_conn(number,content)
      begin
        response = response_body(conn.post)
        raise Exception.new(response[:result_msg]) unless response[:result] == 0
        return response
      rescue Exception => e
        Rails.logger.error e
      end
    end

    def send_sms_with_twilio(number, content)
      sid = ENV['TWILIO_ACCOUNT_SID']
      token = ENV['TWILIO_AUTH_TOKEN']
      from_phone = ENV['TWILIO_PHONE_NUMBER']
      begin
        client = Twilio::REST::Client.new(sid, token)
        client.messages.create(
          from: from_phone,
          to:   '+' + number,
          body: content
        )
      rescue Twilio::REST::TwilioError => e
        puts e.message
      end
    end

    def verify_code(phone, user_code)
      return false if (phone.blank? or user_code.blank?)
      user_code == Rails.cache.read("#{phone}_verify_code")
    end

    private
    def faraday_conn(number, code)
      ts = Time.now.utc.strftime "%Y%m%d%H%M%S"
      conn = Faraday.new(URI.parse(ENV['MIAOSAI_URL']))
      conn.params = {
        account: ENV['MIAOSAI_ACCOUNT'],
        pswd: pswd(ENV['MIAOSAI_ACCOUNT'],ENV['MIAOSAI_PASSWORD'],ts),
        mobile: number,
        msg: code,
        ts: ts,
        sms_sign: 'BangBang'
      }
      conn
    end

    def pswd(account, pswd, ts)
      combo = account+pswd+ts
      Digest::MD5.hexdigest(combo)
    end

    def response_body(response)
      if response.success?
        if response.status == 204
          return nil
        else
          return JSON.parse response.body, :symbolize_names => true
        end
      else
        body = JSON.parse response.body, :symbolize_names => true
        return body[:error]
      end
    end
  end
end
