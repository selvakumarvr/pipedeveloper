class Admin::CommunitiesController < ApplicationController
  include CommunitiesHelper

  before_filter :ensure_is_admin
  before_filter :ensure_is_superadmin, :only => [:payment_gateways, :update_payment_gateway, :create_payment_gateway]
  before_filter :ensure_white_label_plan, only: [:create_sender_address]

  def getting_started
    @selected_left_navi_link = "getting_started"
    @community = @current_community
    render locals: {paypal_enabled: PaypalHelper.paypal_active?(@current_community.id)}
  end

  def edit_look_and_feel
    @selected_left_navi_link = "tribe_look_and_feel"
    @community = @current_community
    flash.now[:notice] = t("layouts.notifications.stylesheet_needs_recompiling") if @community.stylesheet_needs_recompile?
  end

  def edit_text_instructions
    @selected_left_navi_link = "text_instructions"
    @community = @current_community
  end

  def edit_welcome_email
    @selected_left_navi_link = "welcome_email"
    @community = @current_community
    @recipient = @current_user
    @url_params = {
      :host => @current_community.full_domain,
      :ref => "welcome_email",
      :locale => @current_user.locale
    }

    sender_address = EmailService::API::Api.addresses.get_sender(community_id: @current_community.id).data
    user_defined_address = EmailService::API::Api.addresses.get_user_defined(community_id: @current_community.id).data

    enqueue_status_sync!(user_defined_address)

    render "edit_welcome_email", locals: {
             status_check_url: check_email_status_admin_community_path,
             resend_url: Maybe(user_defined_address).map { |address| resend_verification_email_admin_community_path(address_id: address[:id]) }.or_else(nil),
             support_email: APP_CONFIG.support_email,
             sender_address: sender_address,
             user_defined_address: user_defined_address,
             post_sender_address_url: create_sender_address_admin_community_path,
             can_set_sender_address: can_set_sender_address(@current_plan),
             knowledge_base_url: APP_CONFIG.knowledge_base_url,
           }
  end

  def create_sender_address
    res = EmailService::API::Api.addresses.create(
      community_id: @current_community.id,
      address: {
        name: params[:name],
        email: params[:email]
      })

    if res.success
      flash[:notice] =
        t("admin.communities.outgoing_email.successfully_saved")

      redirect_to action: :edit_welcome_email
    else
      error_message =
        case Maybe(res.data)[:error_code]
        when Some(:invalid_email)
          t("admin.communities.outgoing_email.invalid_email_error", email: res.data[:email])
        when Some(:invalid_domain)
          kb_link = view_context.link_to(t("admin.communities.outgoing_email.invalid_email_domain_read_more_link"), "#{APP_CONFIG.knowledge_base_url}/articles/686493", class: "flash-error-link")
          t("admin.communities.outgoing_email.invalid_email_domain", email: res.data[:email], domain: res.data[:domain], invalid_email_domain_read_more_link: kb_link).html_safe
        else
          t("admin.communities.outgoing_email.unknown_error")
        end

      flash[:error] = error_message
      redirect_to action: :edit_welcome_email
    end

  end

  def check_email_status
    res = EmailService::API::Api.addresses.get_user_defined(community_id: @current_community.id)

    if res.success
      address = res.data

      if params[:sync]
        enqueue_status_sync!(address)
      end

      render json: HashUtils.camelize_keys(address.merge(translated_verification_sent_time_ago: time_ago(address[:verification_requested_at])))
    else
      render json: {error: res.error_msg }, status: 500
    end

  end

  def resend_verification_email
    EmailService::API::Api.addresses.enqueue_verification_request(community_id: @current_community.id, id: params[:address_id])
    render json: {}, status: 200
  end

  def social_media
    @selected_left_navi_link = "social_media"
    @community = @current_community
    render "social_media", :locals => {
      display_knowledge_base_articles: APP_CONFIG.display_knowledge_base_articles,
      knowledge_base_url: APP_CONFIG.knowledge_base_url}
  end

  def analytics
    @selected_left_navi_link = "analytics"
    @community = @current_community
    render "analytics", :locals => {
      display_knowledge_base_articles: APP_CONFIG.display_knowledge_base_articles,
      knowledge_base_url: APP_CONFIG.knowledge_base_url}
  end

  def menu_links
    @selected_left_navi_link = "menu_links"
    @community = @current_community
  end

  def update_menu_links
    @community = @current_community

    update(@community,
            Maybe(params)[:menu_links].or_else({menu_link_attributes: {}}),
            menu_links_admin_community_path(@community),
            :menu_links)
  end

  # This is currently only for superadmins, quick and hack solution
  def payment_gateways
    # Redirect if payment gateway in use but it's not braintree
    redirect_to edit_details_admin_community_path(@current_community) if @current_community.payment_gateway && !@current_community.braintree_in_use?

    @selected_left_navi_link = "payment_gateways"
    @community = @current_community
    @payment_gateway = Maybe(@current_community).payment_gateway.or_else { BraintreePaymentGateway.new }

    render :braintree_payment_gateway
  end

  def update_payment_gateway
    # Redirect if payment gateway in use but it's not braintree
    redirect_to edit_details_admin_community_path(@current_community) if @current_community.payment_gateway && !@current_community.braintree_in_use?

    braintree_params = params[:payment_gateway]
    community_params = params[:community]

    unless @current_community.update_attributes(community_params)
      flash.now[:error] = t("layouts.notifications.community_update_failed")
      return render :payment_gateways
    end

    update(@current_community.payment_gateway,
      braintree_params,
      payment_gateways_admin_community_path(@current_community),
      :payment_gateways)
  end

  def create_payment_gateway
    @current_community.payment_gateway = BraintreePaymentGateway.create(params[:payment_gateway].merge(community: @current_community))
    update_payment_gateway
  end

  def test_welcome_email
    PersonMailer.welcome_email(@current_user, @current_community, true, true).deliver
    flash[:notice] = t("layouts.notifications.test_welcome_email_delivered_to", :email => @current_user.confirmed_notification_email_to)
    redirect_to edit_welcome_email_admin_community_path(@current_community)
  end

  def settings
    @selected_left_navi_link = "admin_settings"

    render :settings, locals: {
             supports_escrow: escrow_payments?(@current_community),
             delete_redirect_url: delete_redirect_url(APP_CONFIG),
             delete_confirmation: @current_community.ident,
             can_delete_marketplace: can_delete_marketplace?(@current_community.id)
           }
  end

  def update_look_and_feel
    @community = @current_community
    @selected_left_navi_link = "tribe_look_and_feel"

    params[:community][:custom_color1] = nil if params[:community][:custom_color1] == ""
    params[:community][:custom_color2] = nil if params[:community][:custom_color2] == ""

    permitted_params = [
      :wide_logo, :logo,:cover_photo, :small_cover_photo, :favicon, :custom_color1,
      :custom_color2, :default_browse_view, :name_display_type
    ]
    permitted_params << :custom_head_script
    params.require(:community).permit(*permitted_params)
    update(@current_community,
           params[:community].merge(stylesheet_needs_recompile: regenerate_css?(params, @current_community)),
           edit_look_and_feel_admin_community_path(@current_community),
           :edit_look_and_feel) {
      Delayed::Job.enqueue(CompileCustomStylesheetJob.new(@current_community.id), priority: 3)
    }
  end

  def update_social_media
    @community = @current_community
    @selected_left_navi_link = "social_media"

    [:twitter_handle,
     :facebook_connect_id,
     :facebook_connect_secret].each do |param|
      params[:community][param] = nil if params[:community][param] == ""
    end

    params.require(:community).permit(
      :twitter_handle, :facebook_connect_id, :facebook_connect_secret
    )

    update(@current_community,
            params[:community],
            social_media_admin_community_path(@current_community),
            :social_media)
  end

  def update_analytics
    @community = @current_community
    @selected_left_navi_link = "analytics"

    params[:community][:google_analytics_key] = nil if params[:community][:google_analytics_key] == ""
    params.require(:community).permit(:google_analytics_key)
    update(@current_community,
            params[:community],
            analytics_admin_community_path(@current_community),
            :analytics)
  end

  def update_settings
    @selected_left_navi_link = "settings"

    permitted_params = [
      :join_with_invite_only, :users_can_invite_new_users, :private,
      :require_verification_to_post_listings,
      :show_category_in_listing_list, :show_listing_publishing_date,
      :hide_expiration_date, :listing_comments_in_use,
      :automatic_confirmation_after_days, :automatic_newsletters,
      :default_min_days_between_community_updates,
      :email_admins_about_new_members
    ]
    permitted_params << :testimonials_in_use if @current_community.payment_gateway
    params.require(:community).permit(*permitted_params)

    maybe_update_payment_settings(@current_community.id, params[:community][:automatic_confirmation_after_days])

    update(@current_community,
            params[:community],
            settings_admin_community_path(@current_community),
            :settings)
  end

  def delete_marketplace
    if can_delete_marketplace?(@current_community.id) && params[:delete_confirmation] == @current_community.ident
      @current_community.update_attributes(deleted: true)

      redirect_to Maybe(delete_redirect_url(APP_CONFIG)).or_else(:community_not_found)
    else
      flash[:error] = "Could not delete marketplace."
      redirect_to action: :settings
    end

  end

  private

  def enqueue_status_sync!(address)
    Maybe(address)
      .reject { |addr| addr[:verification_status] == :verified }
      .each { |addr|
      EmailService::API::Api.addresses.enqueue_status_sync(
        community_id: addr[:community_id],
        id: addr[:id])
    }
  end

  def regenerate_css?(params, community)
    params[:community][:custom_color1] != community.custom_color1 ||
    params[:community][:custom_color2] != community.custom_color2 ||
    !params[:community][:cover_photo].nil? ||
    !params[:community][:small_cover_photo].nil? ||
    !params[:community][:wide_logo].nil? ||
    !params[:community][:logo].nil? ||
    !params[:community][:favicon].nil?
  end

  def update(model, params, path, action, &block)
    if model.update_attributes(params)
      flash[:notice] = t("layouts.notifications.community_updated")
      yield if block_given? #on success, call optional block
      redirect_to path
    else
      flash.now[:error] = t("layouts.notifications.community_update_failed")
      render action
    end
  end

  # TODO The home of this setting should be in payment settings but
  # those are only used with paypal for now. During the transition
  # period we simply mirror community setting to payment settings in
  # case of paypal.
  def maybe_update_payment_settings(community_id, automatic_confirmation_after_days)
    return unless automatic_confirmation_after_days

    p_set = Maybe(payment_settings_api.get(
                   community_id: community_id,
                   payment_gateway: :paypal,
                   payment_process: :preauthorize))
            .map {|res| res[:success] ? res[:data] : nil}
            .or_else(nil)

    payment_settings_api.update(p_set.merge({confirmation_after_days: automatic_confirmation_after_days.to_i})) if p_set
  end

  def payment_settings_api
    TransactionService::API::Api.settings
  end

  def escrow_payments?(community)
    MarketplaceService::Community::Query.payment_type(community.id) == :braintree
  end

  def delete_redirect_url(configs)
    Maybe(configs).community_not_found_redirect.or_else(nil)
  end

  def can_delete_marketplace?(community_id)
    PlanService::API::Api.plans.get_current(community_id: community_id).data[:plan_level] == PlanUtils::FREE
  end

  def can_set_sender_address(plan)
    PlanUtils.valid_plan_at_least?(plan, PlanUtils::PRO)
  end

  def ensure_white_label_plan
    unless can_set_sender_address(@current_plan)
      flash[:error] = "Not available for your plan" # User shouldn't
                                                    # normally come
                                                    # here because
                                                    # access is
                                                    # restricted in
                                                    # front-end. Thus,
                                                    # no need to
                                                    # translate.

      redirect_to action: :edit_welcome_email
    end
  end

end
