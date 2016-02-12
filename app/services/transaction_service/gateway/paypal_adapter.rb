module TransactionService::Gateway
  class PaypalAdapter < GatewayAdapter

    PaymentModel = ::Payment

    def implements_process(process)
      [:none, :preauthorize, :postpay].include?(process)
    end

    def create_payment(tx:, gateway_fields:, prefer_async: nil)
      SyncCompletion.new(Result::Success.new({result: true}))
    end

    def reject_payment(tx:, reason: nil)
      SyncCompletion.new(Result::Success.new({result: true}))
    end

    def complete_preauthorization(tx:)
      result = BraintreeService::Payments::Command.submit_to_settlement(tx[:id], tx[:community_id])

      if !result.success?
        SyncCompletion.new(Result::Error.new(result.message))
      end

      SyncCompletion.new(Result::Success.new({result: true}))
    end

    def get_payment_details(tx:)
      payment_total = Maybe(PaymentModel.where(transaction_id: tx[:id]).first).total_sum.or_else(nil)
      total_price = tx[:unit_price] * tx[:listing_quantity]
      { payment_total: payment_total,
        total_price: total_price,
        charged_commission: nil,
        payment_gateway_fee: nil }
    end

  end
end