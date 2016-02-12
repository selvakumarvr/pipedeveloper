class ErrorsController < ActionController::Base

  layout 'blank_layout'
  before_filter :current_community
  before_filter :set_locale

  def server_error
    error_id = airbrake_error_id
    # error_id = 12341234153 # uncomment this to test the last text paragraph
    render "status_500", status: 500, locals: { status: 500, title: title(500), error_id: error_id }
  end

  def not_found
    render "status_404", status: 404, locals: { status: 404, title: title(404) }
  end

  def gone
    render "status_410", status: 410, locals: { status: 410, title: title(410) }
  end

  def community_not_found
    render status: 404, locals: { status: 404, title: "Marketplace not found", host: request.host }
  end

  private

  def current_community
    @current_community ||= ApplicationController.find_community(community_identifiers)
  end

  def community_identifiers
    app_domain = URLUtils.strip_port_from_host(APP_CONFIG.domain)
    ApplicationController.parse_community_identifiers_from_host(request.host, app_domain)
  end

  def title(status)
    community_name = Maybe(@current_community).map { |c|
      c.name(community_locale)
    }.or_else(nil)

    [community_name, t("error_pages.error_#{status}_title")].compact.join(' - ')
  end

  def community_locale
    Maybe(@current_community).default_locale.or_else(nil)
  end

  def set_locale
    # TODO We should set also the community here and allow I18n
    # backend to work even if community is not set
    I18n.locale = community_locale || "en"
  end

  def exception
    env["action_dispatch.exception"]
  end

  def airbrake_error_id
    env['airbrake.error_id'] if error_id_present?(env['airbrake.error_id'])
  end

  def can_notify_airbrake
    Airbrake && Airbrake.respond_to?(:notify)
  end

  def use_airbrake
    APP_CONFIG && APP_CONFIG.use_airbrake
  end

  # For some weird reason, Airbrake gem returns true, if error is not sent
  # (e.g. due to missing api key). So, make sure the error_id is present
  # (i.e. not empty), but return false if the id is true
  def error_id_present?(error_id)
    error_id.present? && error_id != true
  end
end
