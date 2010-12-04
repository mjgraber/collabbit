class ApplicationController < ActionController::Base
  require 'digest/sha1'
  helper :all # include all helpers, all the time

  #Filter to catch exceptions and display nice page
  around_filter :catch_exceptions
  
  filter_parameter_logging 'password'

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery # :secret => 'd9a4fa2487b71adf1f4fb8d68c2fcc59'
  
  rescue_from Instance::Missing do |instance|
    flash[:error] = "We're sorry, we couldn't find a Collabbit for <strong>#{instance}</strong>."
    render "shared/404", :layout => 'home'
  end
  
   rescue_from ActiveRecord::RecordNotFound do
       flash.now[:error] = "We're sorry, something you just requested was misplaced."
       redirect_to @instance
     end
  
  layout :check_if_promo_layout
  
  
  after_filter :set_admin_flash
  before_filter :set_current_account, :set_environment
  before_filter :check_account_redirect
  
  helper_method :promo?, :subdomain
  
  def set_current_account
    @instance = subdomain == '' ? nil : Instance.find_by_short_name(subdomain)
    raise Instance::Missing, subdomain if @instance.blank? && !subdomain_forbidden?
  end

  def set_environment
    @in_production = ENV['RAILS_ENV'] == 'production'
  end
  
  def subdomain_forbidden?
    Instance::FORBIDDEN_SUBDOMAINS.include?(subdomain) || subdomain.blank?
  end
  
  def check_account_redirect
    redirect_to login_path unless promo? || controller_name != 'home'
    redirect_to about_path if promo? && params[:page].blank?
  end
  
  def check_if_promo_layout
    promo? ? 'home' : 'application'
  end
  
  def promo?
    return true if Instance::FORBIDDEN_SUBDOMAINS.include? subdomain || subdomain.blank?
    return true unless !subdomain.blank? && Instance.exists?(:short_name => subdomain)
    return controller_name == 'home' && !params[:page].blank?
  end
  
  def subdomain
    request.subdomains.first || ''
  end
  
  def notice=(*args)
    flash[:notice] = t(*args)
  end
  def error=(*args)
    flash[:error] = t(*args)
  end
  
  def set_admin_flash
    if !promo? && logged_in? && @current_user.permission_to?(:update, User) && @instance.users.exists?(:state => 'pending') && flash[:notice].blank?
      flash[:notice] = t('notice.user.pending_users', :url => users_path(:states_filter => 'pending'))
    end
  end
  
  #function to catch all general exceptions and redirect to 404 page
  private
  def catch_exceptions
    yield
   rescue => exception
    logger.debug "Caught Exception: #{exception}"
    flash.now[:error] = "We're sorry, either that page doesn't exist or that url is mistyped."
    render "shared/404", :layout => 'home'
  end

  
end
