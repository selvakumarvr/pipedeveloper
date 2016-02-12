require 'paypal-sdk-adaptivepayments'
require 'paypal-sdk-rest'

class PaypalGateway

  def initialize
    PayPal::SDK.configure(
      :mode      => "sandbox",  # Set "live" for production
      :app_id    => "APP-80W284485P519543T",
      :username  => "jb-us-seller_api1.paypal.com",
      :password  => "WX4WTU3S8MY44S7F",
      :signature => "AFcWxV21C7fd0v3bYYYRCpSSRl31A7yDhhsPUU2XhtMoZXsWHFxu-RWy" )
    @api = PayPal::SDK::AdaptivePayments.new
  end

  #send payment to the marketplace

  def pay(amount, return_url)

    p "**************** INSIDE METHOD PAY *****************"
    p "PAYPAL GATEWAY AMOUNT =============> #{amount} ======================="

    PayPal::SDK.configure({
      :mode => "sandbox", 
      :username => "mark-facilitator_api1.transcendentconcepts.com",
      :password => "5ALXTL7EXBKXDM69", 
      :signature => "AO08arYqjuLT0wvVXvTwZYR.4PI-AELRlSLGXvSxIXACuiq3RPk2I.nV"
    })

    api = PayPal::SDK::Merchant::API.new
    set_express_checkout = api.build_set_express_checkout({
    :Version => "104.0",
    :SetExpressCheckoutRequestDetails => {
            :ReturnURL => return_url,
            :CancelURL => return_url,
            :PaymentDetails =>[{
              :OrderTotal =>{ :currencyID => "AUD", :value => amount }, :PaymentAction => "Sale"}
              ]
            }
          })

    set_express_checkout_response = api.set_express_checkout(set_express_checkout)

    p "======= CHECKOUT RESPONSE ======= #{set_express_checkout_response}"
    set_express_checkout_response.token

  end


  #send payment to the seller get the key with the parameter
  def execute_payment(payKey)
    p "******************** EXECUTE PAYMENT ****************"
    # THIS METHOD WILL TRANSFER THE MONEY FROM THE MARKETPLACE ACCOUNT TO THE SELLER ACCOUNT
    PayPal::SDK::REST.set_config(
      :mode => "sandbox", # "sandbox" or "live"
      :client_id => "Af0EUFLYeORF4IQUN80nmTsxLgpYrHTTGfR8q7rqmVxG89muFsQMYd40dTzEL3_8-uY4TjEIrBUjmu9e",
      :client_secret => "EJ-U97HKBhSVonBEutXxkNjDNfZ7HygUSG4am7f2RjpxJPaDpXsz82YLYB4TY0Vh2W3R55G_ExxwiocU")

    transaction = Transaction.where("paypal_paykey = ?", payKey).last
    
    unless transaction.deposit_cents.nil?
      amount = transaction.amount - transaction.deposit_cents
    else
      amount = transaction.amount
    end

    @payout = PayPal::SDK::REST::Payout.new(
      {
        :sender_batch_header => {
          :sender_batch_id => SecureRandom.hex(8),
          :email_subject => 'You have a Payout!',
        },
        :items => [
          {
            :recipient_type => 'EMAIL',
            :amount => {
              :value => (amount).to_i - ((amount) * 0.1).to_i,
              :currency => 'AUD'
            },
            :note => 'Thanks!',
            :receiver => transaction.seller.paypal_account
          }
        ]
      }
    )

    p "*************** PAYOUT ************* #{@payout} *****************"
    begin
      @payout_batch = @payout.create
      Rails.logger.info "Created Payout with [#{@payout_batch.batch_header.payout_batch_id}]"
    rescue ResourceNotFound => err
      Rails.logger.error @payout.error.inspect
    end

  end


  def refund_deposit(transaction)
    p "******************** REFUND DEPOSIT ****************"
    # THIS METHOD WILL TRANSFER THE MONEY FROM THE MARKETPLACE ACCOUNT TO THE BUYER ACCOUNT - REFUNDING THE DEPOSIT
    
    PayPal::SDK::REST.set_config(
      :mode => "sandbox", # "sandbox" or "live"
      :client_id => "Af0EUFLYeORF4IQUN80nmTsxLgpYrHTTGfR8q7rqmVxG89muFsQMYd40dTzEL3_8-uY4TjEIrBUjmu9e",
      :client_secret => "EJ-U97HKBhSVonBEutXxkNjDNfZ7HygUSG4am7f2RjpxJPaDpXsz82YLYB4TY0Vh2W3R55G_ExxwiocU")

    amount = transaction.deposit_cents / 100

    p "********* AMOUNT ************ #{amount}"
    @payout = PayPal::SDK::REST::Payout.new(
      {
        :sender_batch_header => {
          :sender_batch_id => SecureRandom.hex(8),
          :email_subject => 'You have a Payout! Refunding your deposit made in Gearaway',
        },
        :items => [
          {
            :recipient_type => 'EMAIL',
            :amount => {
              :value => amount,
              :currency => 'AUD'
            },
            :note => 'Thanks!',
            :receiver => transaction.paypal_payer_email
          }
        ]
      }
    )

    p "*************** PAYOUT ************* #{@payout} *****************"

    begin
      @payout_batch = @payout.create
      Rails.logger.info "Created Payout with [#{@payout_batch.batch_header.payout_batch_id}]"
    rescue ResourceNotFound => err
      Rails.logger.error @payout.error.inspect
    end

  end


  def get_payment_details(txn_id)
    p "******************** get payment details method *******************"
    # Build request object
    @payment_details = @api.build_payment_details({
      :transactionId => txn_id 
    })

    # Make API call & get response
    @payment_details_response = @api.payment_details(@payment_details)

    # Access Response
    if @payment_details_response.success?
      return @payment_details_response
    else
      @payment_details_response.error
    end 
  end

end