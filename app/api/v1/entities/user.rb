module V1
  module Entities
    class User < Base
      expose :uid, :email, :mobile, :username, :first_name, :last_name
      expose :encrypted_session_key do |u, opt|
        u.encrypted_session_key if opt[:key]
      end
      expose :created_at, :updated_at, :deleted_at, format_with: :utc_datetime
    end
  end
end
