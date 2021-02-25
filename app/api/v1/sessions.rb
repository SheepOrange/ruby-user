module V1
  class Sessions < Grape::API
    resource :sessions do
      #generate verify code and verify the code
      desc "Generate email verify code", headers: Root.track_header
      params do
        requires :email, type: String
      end
      post "email" do
        code = Rails.cache.fetch "#{params[:email]}_verify_code", expires_in: 5.minute do
          SecureRandom.hex(3)
        end
        UserMailer.send_verification_email(params[:email], code).deliver_later
        response_format
        present :code, code unless Rails.env.production?
      end

      desc "Generate mobile verify code", headers: Root.track_header
      params do
        requires :mobile, type: String,desc: "country code and mobile number"
        optional :sign_up, type: Boolean
      end
      post "mobile" do
        mobile = Phonelib.parse(params[:mobile]).to_s
        if phone_valid?(mobile)
          if params[:sign_up] == true && User.exists?(mobile: mobile)
            error!(result: false,message: I18n.t("activerecord.errors.messages.mobile_taken"),status: 422)
          end
          if Rails.env.production?
            check_sms_limit(mobile)
            code = PhoneUtils.send_confirmation_sms(mobile)
          else
            code = Rails.cache.fetch "#{mobile}_verify_code", expires_in: 5.minute do
              rand.to_s[2..7]
            end
          end
          if code
            response_format
            present :code, code unless Rails.env.production?
          else
            error!(result: false,message: I18n.t("activerecord.errors.messages.sms_code_sent"),status: 422)
          end
        end
      end

      desc 'Verify confirmation code'
      params do
        optional :email, type: String
        optional :mobile, type: String, desc: "country code and mobile number"
        requires :code, type: String
        mutually_exclusive :email, :mobile
      end
      get :verify do
        if mobile = params[:mobile].presence
          error!(result: false,message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: User.human_attribute_name('verify_code')),status: 422) unless PhoneUtils.verify_code(Phonelib.parse(mobile).to_s, params[:code])
        elsif email = params[:email].presence
          error!(result: false,message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: User.human_attribute_name('verify_code')),status: 422) unless verify_email_verify_code(email, params[:code])
        end
        response_format
      end


      desc "Account log in by password or use email/mobile by verification code", headers: Root.track_header
      params do
        optional :username, type: String
        optional :email, type:String
        optional :mobile, type:String,desc: "format with country code and number, e.g. 61400111111"
        optional :code, type:String, desc: "mobile or email verification code"
        optional :password, type: String
        mutually_exclusive :password, :code
        exactly_one_of :username, :email, :mobile
      end
      post "sign_in" do
        # verify the user using mobile, username or email
        if mobile = params[:mobile].presence
          user = User.find_by(mobile: Phonelib.parse(mobile).to_s)
          error!(result: false, message: I18n.t("activerecord.errors.messages.login_fail", attr: User.human_attribute_name('mobile')), status: 422) unless user.present?
        elsif username = params[:username].presence
          user = User.find_by(username: username)
          error!(result: false, message: I18n.t("activerecord.errors.messages.login_fail", attr: User.human_attribute_name('username')), status: 422) unless user.present?
        elsif email = params[:email].presence
          user = User.find_by(email: email)
          error!(result: false, message: I18n.t("activerecord.errors.messages.login_fail", attr: User.human_attribute_name('email')), status: 422) unless user.present?
        end
        # verify the password or code
        if password = params[:password].presence
          user.verify_password(password) or raise error!(result: false, message: I18n.t("activerecord.errors.messages.password_invalid"), status: 422)
        elsif code = params[:code].presence
          if mobile.present?
            PhoneUtils.verify_code(user.mobile, code) or raise error!(result: false,message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: User.human_attribute_name('verify_code')),status: 422)
          else
            verify_email_verify_code(user.email, code) or raise error!(result: false,message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: User.human_attribute_name('verify_code')),status: 422)
          end
        end
        update_tracked_fields(user)
        user.paper_trail_event = 'sign_in'
        response_format
        present :data, user, with: V1::Entities::User, key: true
      end

      desc "sign_up using email or mobile"
      params do
        optional :email, type: String
        optional :mobile, type: String, desc: "country code and mobile number"
        requires :username, type: String
        requires :password, type: String
        requires :password_confirmation, type: String
        optional :code, type: String, desc: 'verify_code from email or mobile'
        mutually_exclusive :email, :mobile
      end
      post 'sign_up' do
        if mobile = params[:mobile].presence
          params[:mobile] = Phonelib.parse(mobile).to_s
          PhoneUtils.verify_code(params[:mobile], params[:code]) or raise error!(result: false,message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: User.human_attribute_name('verify_code')),status: 422)
        elsif email = params[:email].presence
          verify_email_verify_code(email, params[:code]) or raise error!(result: false,message: I18n.t("activerecord.errors.messages.attribute_invalid",attr: User.human_attribute_name('verify_code')),status: 422)
        end

        salt = SecureRandom.hex(3)
        params[:password] = Digest::MD5.hexdigest(params[:password] + salt) rescue nil
        params[:password_confirmation] = Digest::MD5.hexdigest(params[:password_confirmation] + salt) rescue nil

        user = User.new(params.except(:code).merge(salt: salt))
        if user.save!
          user.paper_trail_event = "sign_up"
          response_format
          present :data, user, with: V1::Entities::User
        else
          present_save_error(user)
        end
      end

      desc "Forget password"
      params do
        requires :email, type: String
        requires :new_password, type: String
        requires :new_password_confirmation, type: String
      end
      put 'forget_password' do
        user = User.staff.find_by(email: params[:email])
        error!(result: false, status: 422, message: "Can't find user with this email") if user.nil?
        user.update!(
          password: params[:new_password],
          password_confirmation: params[:new_password_confirmation]
        )
        response_format
        present :data, user, with: V1::Entities::User
      end

      group do
        before { authenticate! }
        desc 'Sign out', headers: Root.auth_headers
        delete 'sign_out' do
          user = current_user
          PaperTrail.request.whodunnit = user.username || 'unknown user'
          user.paper_trail_event = 'sign_out'
          if Rails.cache.delete("#{user.uid}_session_key")
            response_format
          else
            error!(result: false, message: I18n.t("activerecord.errors.messages.logout_fail"), status: 422)
          end
        end
      end

    end
  end
end
