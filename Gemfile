# Gemfile
source 'https://rubygems.org'

ruby '2.2.0'

gem 'sinatra-activerecord'
gem 'pg'
gem 'rake'
gem 'bcrypt', '3.1.7'
gem 'uuid'
gem 'aes'
gem 'sinatra-cross_origin', "~> 0.3.1"
gem 'sinatra-jsonp'
gem 'rack-ssl'
gem 'will_paginate', '~> 3.0.6'
gem 'aws-sdk'
gem 'stripe'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'pry'
  gem 'spring'
  gem "codeclimate-test-reporter"
end

group :test do
  gem 'minitest-reporters', '1.0.5'
  gem 'mini_backtrace', '0.1.3'
  gem 'guard-minitest', '2.3.1'
  gem 'minitest-ansi'
  gem 'minitest-emoji'
  gem 'minitest-osx'

end

group :production do
  gem 'puma', '2.11.1'
end