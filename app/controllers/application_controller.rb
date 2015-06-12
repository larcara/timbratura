class ApplicationController < ActionController::Base
  rescue_from DeviseLdapAuthenticatable::LdapException do |exception|
    render :text => exception, :status => 500
  end
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  #before_filter :check_administrative_ip
  before_action :authenticate_user!

  def check_administrative_ip
    redirect_to new_clock_url unless ADMINISTRATIVE_IPS.include? request.remote_ip
    #redirect_to url_for(action: :dashboard) if (current_user && current_user.is_camera? && !current_user.is_admin?)
    return false
  end

  def check_admin_role
    redirect_to new_clock_url unless current_user.is_admin?
    #redirect_to url_for(action: :dashboard) if (current_user && current_user.is_camera? && !current_user.is_admin?)
    return true
  end

  ADMINISTRATIVE_IPS = ["127.0.0.1","10.103.142.168","10.103.171.191", "10.103.142.249"]
end
