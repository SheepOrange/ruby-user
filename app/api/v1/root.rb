require 'grape-swagger'

module V1
  class Root < Grape::API
    prefix 'api'
    format :json
    version 'v1', using: :path

    def self.auth_headers
      {
        "X-Auth-Token" => {
          description: "Validate access token",
          required: true
        },
        "X-Auth-Id" => {
          description: "User Uid",
          required: true
        },
        "X-Auth-Locale" => {
          description: "Locale Setting",
          required: false
        },
        "X-Forwarded-For" => {
          description: "Client IP Address",
          required: false
        }
      }
    end

    def self.auth_headers_optional
      {
          "X-Auth-Token" => {
              description: "Validate access token",
              required: false
          },
          "X-Auth-Id" => {
              description: "User Id",
              required: false
          },
          "X-Auth-Locale" => {
            description: "Locale Setting",
            required: false
          },
          "X-Forwarded-For" => {
            description: "Client IP Address",
            required: false
          }
      }
    end

    def self.track_header
      {
        "X-Auth-Locale" => {
          description: "Locale Setting",
          required: false
        },
        "X-Forwarded-For" => {
          description: "Client IP Address",
          required: false
        }
      }
    end

    before do
      header['Access-Control-Allow-Origin'] = '*'
      header['Access-Control-Request-Method'] = '*'
      set_locale
    end

    rescue_from ActiveRecord::RecordNotFound do |e|
      error!(result: false, message: I18n.t("activerecord.errors.messages.record_not_found", record: e.model.constantize.model_name.human), status: 404)
    end

    rescue_from :all do |e|
      error!(result: false, message: e.message, status: 422)
    end

    helpers V1::Helpers
    mount V1::Sessions

    add_swagger_documentation mount_path: '/swagger_doc',
                              api_version: 'v1',
                              info: {
                                title: 'BANGBANG API V1'
                              }
  end
end
