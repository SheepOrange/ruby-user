# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  avatar                 :string
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  deleted_at             :datetime
#  email                  :string
#  encrypted_password     :string           default(""), not null
#  first_name             :string
#  last_name              :string
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  mobile                 :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  role                   :integer
#  salt                   :string
#  sign_in_count          :integer          default(0), not null
#  uid                    :string
#  username               :string           default(""), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_username              (username) UNIQUE
#
require 'bcrypt'
class User < ApplicationRecord
  include BCrypt

  has_paper_trail skip: [:sign_in_count, :current_sign_in_at, :last_sign_in_at,
    :current_sign_in_ip, :last_sign_in_ip, :created_at, :updated_at]
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,:recoverable, :rememberable,
          :trackable

  before_validation :generate_attrs, on: :create

  validates :username, uniqueness: true, presence: true
  validates :email, uniqueness: true, allow_nil: true,allow_blank: true, format: { with: Devise::email_regexp}
  validates :mobile, uniqueness: true, allow_nil: true, allow_blank: true
  validates :password, presence: true, confirmation: true, on: :create
  # validate :check_password_format, on: [:create, :update]
  validate :check_password, on: [:create, :update]
  scope :available, -> { where(deleted_at: nil) }

  def session_key
    Rails.cache.read("#{id}_session_key")
  end

  def verify_password(password)
    password = Digest::MD5.hexdigest(password+salt)
    self.valid_password?(password)
  end

  def encrypted_session_key
    Digest::MD5.hexdigest generate_session_key rescue nil
  end

  class UserError < RuntimeError; end

  private
  def generate_attrs
    generate_random_column('uid', "UID#{SecureRandom.hex(5).upcase}")
  end

  def generate_session_key
    session_key = Rails.cache.read("#{id}_session_key") || SecureRandom.hex(10)
    Rails.cache.write("#{id}_session_key", session_key, expires_in: 1.month)
    session_key
  end

  def generate_random_column(column, value)
    begin
      send("#{column}=", value)
    end while User.exists?(["#{column} = ?", send(column)])
  end

  def check_password_format
    if password.present? && password !~ /^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?\d).{8,20}$/
      errors.add :base, I18n.t('activerecord.errors.messages.password_format')
    end
  end

  def check_password
    if password && password != password_confirmation
      errors.add :base, I18n.t('activerecord.errors.messages.attribute_confirmation', attr1: User.human_attribute_name('password_confirmation'), attr2: User.human_attribute_name('password'))
    end
  end
end
