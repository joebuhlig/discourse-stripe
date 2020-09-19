module DiscourseStripe
  class WebhookController < ApplicationController
    layout false
    skip_before_action :check_xhr
    skip_before_action :verify_authenticity_token

    def stripe
      endpoint_secret = SiteSetting.discourse_stripe_webhook_secret

      payload = request.body.read
      sig_header = request.env['HTTP_STRIPE_SIGNATURE']
      event = nil

      # validate webook
      begin
        event = Stripe::Webhook.construct_event(
          payload, sig_header, endpoint_secret
        )
      rescue JSON::ParserError => e
        return 400
      rescue Stripe::SignatureVerificationError => e
        return 400
      end

      if event["type"] == "customer.created"
        print 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - CUSTOMER'
        email = 'hello@joebuhlig.com'
        user = User.find_by_email(email)
        if user
          print user
        else
          print 'no user found'
          user = User.create!(
              email: email,
              username: UserNameSuggester.suggest(email),
              name: User.suggest_name(email),
              staged: true
            )
        end
        print user
        print event['data']['object']['id']
        print event['data']['object']['email']
      elsif event["type"] == "customer.subscription.created"
        print 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - NEW'

      elsif event["type"] == "customer.subscrption.deleted"
        print 'XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX - DELETE'
      end

      return 200
    end
  end
end
