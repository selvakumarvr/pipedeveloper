class PaypalController < ApplicationController
  def pay
    gateway = PaypalGateway.new
    #retorna url que vai dar o redirect para o paypal
    #INTEGRAR COM O FLUXO DO SHARETRIBE
    render text: gateway.pay
  end

  def execute_payment
    gateway = PaypalGateway.new
    render text: gateway.execute_payment
  end

  def ipn_test

  end

  def ipn_notify
    if PayPal::SDK::Core::API::IPN.valid?(request.raw_post)
      logger.info("IPN message: VERIFIED")
      notify_payment(params)
      render :text => "VERIFIED"
    else
      logger.info("IPN message: INVALID")
      render :text => "INVALID"
    end
  end

  def notify_payment(paypal_params)
    msg = PaypalIpnMessage.create(body: paypal_params)

    paypal_gateway = PaypalGateway.new
    payment_details = paypal_gateway.get_payment_details(paypal_params[:txn_id])

    logger.info("paypal_params.inspect ==== #{paypal_params.inspect}")
    logger.info("payment details ==== #{payment_details}")
    logger.info("paykey ==== #{payment_details.payKey}")
    logger.info("status ==== #{payment_details.status}")

    paykey = payment_details.payKey
    status = paypal_params[:payment_status].upcase
    
    transaction = Transaction.where(paypal_paykey: paykey).last

    transaction.update_attributes(paypal_status: status)
    msg.update_attributes(status: status)

    if status == "COMPLETED"
      MarketplaceService::Transaction::Command.transition_to(transaction.id, "preauthorized")
    end

  end

  def notify_payment_local
    msg = PaypalIpnMessage.create(body: params)

    paypal_gateway = PaypalGateway.new
    payment_details = paypal_gateway.get_payment_details(params[:txn_id])

    logger.info("params.inspect ==== #{params.inspect}")
    logger.info("payment details ==== #{payment_details}")
    logger.info("payment_details ==== #{payment_details.inspect}")
    
    logger.info("paykey ==== #{payment_details.payKey}")
    logger.info("status ==== #{payment_details.status}")

    paykey = payment_details.payKey
    status = "COMPLETED"

    transaction = Transaction.where(paypal_paykey: paykey).last

    transaction.update_attributes(paypal_status: status)
    msg.update_attributes(status: status)

    MarketplaceService::Transaction::Command.transition_to(transaction.id, "preauthorized")
    render text: "ok"
  end

  def connect
    p " paypal account ==== #{params[:paypal_account]}" 
    p " query ======> #{@current_user.update_attributes!(paypal_account: params[:paypal_account])}" 
    
    flash[:notice] = "PayPal account connected!"
    redirect_to :back
  end

end