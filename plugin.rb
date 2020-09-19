# name: discourse-stripe
# about: Adds the ability to sell memberships to groups via Stripe Checkout and Customer Portal.
# version: 0.1
# author: Joe Buhlig joebuhlig.com
# url: https://www.github.com/joebuhlig/discourse-stripe

enabled_site_setting :discourse_stripe_enabled

gem 'stripe', '5.25.0'

load File.expand_path('../lib/discourse_stripe/engine.rb', __FILE__)

after_initialize do

end
