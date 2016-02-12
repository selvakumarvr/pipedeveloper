module PaypalService
  module Payments
    CommunityModel = ::Community

    module Command
      module_function

      def submit_to_settlement(transaction_id, community_id)

        transaction = Transaction.find(transaction_id)
        seller = Person.find(transaction.listing.author_id)

        price = ( (transaction.listing.price_cents) / 100) * transaction.listing_quantity

        paypal_gateway = PaypalGateway.new

        charge = paypal_gateway.execute_payment(transaction.paypal_paykey)
      end


    end

    module Query

      module_function

      def braintree_settings(community_id)
        Maybe(CommunityModel.find_by_id(community_id))
          .map { |community|
            if community.payment_gateway.present? && community.payment_gateway.gateway_type == :braintree
              BraintreeService::Payments::Entity.braintree_settings(community.payment_gateway)
            else
              nil
            end
          }
          .or_else(nil)
      end
    end
  end
end 