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
      if event['type'] == 'customer.created'
        email = 'hello@joebuhlig.com'
        user = User.find_by_email(email)
        unless user
          user = User.create!(
            email: email,
            username: UserNameSuggester.suggest(email),
            name: User.suggest_name(email),
            staged: true
          )
        end
        user.custom_fields[:stripe_customer_id] = event['data']['object']['id']
        user.save
        return user
      elsif event['type'] == 'customer.subscription.created'
        customer_id = event['data']['object']['customer']
        user_cf = UserCustomField.find_by(value: customer_id)
        if user_cf
          user = User.find(user_cf.user.id)
          if user
            group_assignments = SiteSetting.discourse_stripe_group_assignment
            group_assignments.split('|').each do |group|
              product_id = group.split(':').last
              event['data']['object']['items']['data'].each do |item|
                if item['price']['product'] == product_id
                  dc_group = Group.find_by(name: group.split(':').first)
                  next unless dc_group

                  dc_group.add(user)
                  dc_group.save
                  return user
                end
              end
            end
          end
        end
      elsif event['type'] == 'customer.subscription.deleted'
        customer_id = event['data']['object']['customer']
        user_cf = UserCustomField.find_by(value: customer_id)
        if user_cf
          user = User.find(user_cf.user.id)
          if user
            group_assignments = SiteSetting.discourse_stripe_group_assignment
            group_assignments.split('|').each do |group|
              product_id = group.split(':').last
              event['data']['object']['items']['data'].each do |item|
                if item['price']['product'] == product_id
                  dc_group = Group.find_by(name: group.split(':').first)
                  next unless dc_group

                  dc_group.remove(user)
                  dc_group.save
                  return user
                end
              end
            end
          else
            return 400
          end
        else
          return 400
        end
      end

    end
  end
end
