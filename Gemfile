source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.6.3'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '~> 6.1.3'
gem 'devise', '~> 4.7', '>= 4.7.3'
gem 'jquery-rails', '~> 4.4'
gem 'sass-rails', '~> 6.0'
gem 'turbolinks', '~> 5.2', '>= 5.2.1'
# Use postgresql as the database for Active RecordS
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma', '~> 5.0'
gem 'uglifier', '~> 4.2'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
# gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
gem 'redis', '~> 4.0'
gem 'redis-rails'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'
# A Ruby framework for rapid API development with great conventions.
gem 'grape'
gem 'grape-entity'
gem 'grape-swagger'
gem 'grape-swagger-entity'
gem 'grape-swagger-ui'
# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.4', require: false

gem 'bcrypt', '~> 3.1', '>= 3.1.16'
# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors'
gem 'twilio-ruby',  '~> 5.6.0'
gem "mailjet"
gem 'phonelib', '~> 0.6.48'
gem 'passgen', '~> 1.2'
gem 'carrierwave', '~> 2.1', '>= 2.1.1'
gem 'faraday'
gem 'paper_trail', '~> 11.1'
# Manipulate images with minimal use of memory via ImageMagick / GraphicsMagick
gem 'mini_magick', '~> 4.11'
gem 'sidekiq', '~> 5.2.3'
gem 'dotenv-rails'
gem 'aasm', '~> 5.1', '>= 5.1.1'
gem 'activeadmin', '~> 2.9'
gem 'activeadmin_addons', '~> 1.7', '>= 1.7.1'

gem 'airbrake'
gem 'airbrake-ruby'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'rspec-rails', '~> 3.5'
end

group :development do
  gem 'annotate'
  gem 'listen', '~> 3.3'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  gem 'factory_bot_rails', '~> 4.0'
  gem 'shoulda-matchers', '~> 3.1'
  gem 'faker'
  gem 'database_cleaner'
  gem 'simplecov', require: false, group: :test
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
