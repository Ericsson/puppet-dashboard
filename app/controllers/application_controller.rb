# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  include InheritedResources::DSL
  include PaginateScopeHelper
  include StringHelper
  include AuthenticatedSystem

  helper :all # include all helpers, all the time

  before_filter :expire_all_session

  before_filter :set_timezone
  before_filter :login_required
  
  before_filter :update_session
  before_filter :session_expiry

  before_filter :set_cache_buster



  protect_from_forgery

  private

  def update_session
    @session = Session.find_by_session_id(request.session_options[:id])
    unless @session.nil?
      if @session.user_id == current_user.id
        @session.update_attribute(:updated_at, Time.now.utc)
      else
        flash[:notice] = 'Please login again.'
        redirect_to new_session_path
      end
    end
  end

 def expire_all_session
    @null_session = Session.find( :all, :conditions => ["updated_at <=  ? and user_id IS NULL", 30.minutes.ago])
        unless @null_session.blank?
                @null_session.each do |exp_session|
                exp_session.destroy
                end
        end
    @idle_session = Session.find(:all , :conditions => ["updated_at <= ? and user_id <> ?", 10.minutes.ago, 'null'])
    unless @idle_session.blank?
        u_id = Array.new
        @idle_session.each do |session|
                u_id << session.user_id
                session.destroy
        end
        User.find(:all, :conditions => ["id IN (?)",u_id.uniq]).each do  |u|
                u.update_attribute(:is_login, 0)
        end
    end
    @user_in_session = Session.all(:select => "Distinct(user_id)", :conditions => ["user_id <> ?", "null"])
        unless @user_in_session.blank?
                user_in_session = Array.new
                @user_in_session.each do |user_session|
                user_in_session << user_session.user_id
                end
                User.find(:all, :conditions => ["id NOT IN (?) and is_login = ?",user_in_session, 1]).each do  |u|
                u.update_attribute(:is_login, 0)
                end
        end

  end
def session_expiry
    get_session_time_left
    unless @session_time_left > 0
        self.current_user.forget_me if logged_in?
        reset_session
        flash[:notice] = 'Your session has timed out. Please log back in.'
        #redirect_to new_session_path
render :action => "new"
    end
  end

  def get_session_time_left
    expire_time = session[:expires_at] || Time.now
    @session_time_left = (expire_time - Time.now).to_i
  end

  def set_cache_buster
    response.headers["Cache-Control"] = "no-cache, no-store, max-age=0, must-revalidate"
    response.headers["Pragma"] = "no-cache"
    response.headers["Expires"] = "Fri, 01 Jan 1990 00:00:00 GMT"
  end


  def raise_if_enable_read_only_mode
    raise ReadOnlyEnabledError.new if SETTINGS.enable_read_only_mode || session['ACCESS_CONTROL_ROLE'] == 'READ_ONLY'
  end

  def raise_unless_using_external_node_classification
    raise NodeClassificationDisabledError.new unless SETTINGS.use_external_node_classification
  end

  rescue_from NodeClassificationDisabledError do |e|
    render :text => "Node classification has been disabled", :content_type => 'text/plain', :status => 403
  end

  def set_timezone
    if SETTINGS.time_zone
      time_zone_obj = ActiveSupport::TimeZone.new(SETTINGS.time_zone)
      raise Exception.new("Invalid timezone #{SETTINGS.time_zone.inspect}") unless time_zone_obj
      Time.zone = time_zone_obj
    end
  end

  def store_location
    session[:return_to] = request.url
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  def handle_parameters_for(param)
    if params[param] && params[param][:parameters]
      parameter_pairs = params[param][:parameters][:key].zip(params[param][:parameters][:value]).flatten
      params[param][:parameters] = Hash[*parameter_pairs].reject{|k,v| k.blank?}
    else
      params[param][:parameters] = {}
    end
  end

  def set_node_autocomplete_data_sources(source_object)
    @node_data = {
      :class       => '#node_ids',
      :data_source => nodes_path(:format => :json),
      :objects     => source_object.nodes
    }
  end

  def set_group_and_class_autocomplete_data_sources(source_object)
    @class_data = {
      :class       => '#node_class_ids',
      :data_source => node_classes_path(:format => :json),
      :objects     => source_object.node_classes
    } if SETTINGS.use_external_node_classification

    @group_data = {
      :class       => '#node_group_ids',
      :data_source => node_groups_path(:format => :json),
      :objects     => source_object.node_groups
    }
  end

  def force_create?
    params[:force_create] == "true"
  end

  def force_update?
    params[:force_update] == "true"
  end

  def force_delete?
    params[:force_delete] == "true"
  end

end
