# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  reset_password_token   :string
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0), not null
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string
#  last_sign_in_ip        :string
#  username               :string
#  avatar                 :string
#  uid                    :string
#  mobile                 :string
#  role                   :integer
#  first_name             :string
#  last_name              :string
#  salt                   :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
require 'bcrypt'
class User < ApplicationRecord
  include BCrypt
  has_secure_password
  has_paper_trail skip: [:sign_in_count, :current_sign_in_at, :last_sign_in_at,
    :current_sign_in_ip, :last_sign_in_ip, :created_at, :updated_at]
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,:recoverable, :rememberable,
        :validatable, :trackable

  before_validation :generate_attrs, on: :create
  validates :mobile, uniqueness: true, allow_blank: true, allow_nil: true, phone: {country_specifier: -> user {
    Phonelib.parse(user.mobile_countrycode + user.mobile).country.try(:upcase)
  }}
  validate :check_password
  validates :username, uniqueness: true, presence: true
  validates :email, uniqueness: true, format: Devise::email_regexp
  validates :mobile, uniqueness: true

  def confirm_password
    @confirm_password ||= Password.new(confirm_password_hash)
  end

  def confirm_password=(new_confirm_password)
    @confirm_password = Password.create(new_confirm_password)
    self.confirm_password_hash = @confirm_password
  end

  def session_key
    Rails.cache.read("#{id}_session_key")
  end

  def encrypted_session_key
    Digest::MD5.hexdigest generate_session_key rescue nil
  end

  private
  def generate_attrs
    generate_random_column('uid', "UID#{SecureRandom.hex(5).upcase}")
    generate_random_column('salt', SecureRandom.hex(3))
    password += salt
    password_confirmation += salt
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

  def check_password
    if password.present? && password !~ /\A[a-zA-Z0-9\S]{8,16}\z/
      errors.add :base, I18n.t('activerecord.errors.messages.password_format')
    end
    if password && password != password_confirmation
      errors.add :base, I18n.t('activerecord.errors.messages.attribute_confirmation', attr1: User.human_attribute_name('password_confirmation'), attr2: User.human_attribute_name('password'))
    end
  end


end
