class SessionController < ApplicationController
  after_action :track_visit, only: %i[new]

  def new; end

  def create
    user = User.find_by_email(login_params[:email])
    if !user.nil? && user.authenticate(login_params[:password])
      session[:user_id] = user.id unless params[:keep_me_logged_in]
      cookies.signed[:permanent_session_id] = { value: user.id, expires: 14.days.from_now } if params[:keep_me_logged_in]
      ahoy.authenticate(user)
      track :regular, :logged_in
      redirect_to url_for(controller: :dashboard, action: :index), notice: 'Logged in!'
    else
      @error = 'Wrong email or password.'
      track :nefarious, :failed_to_log_in, email: login_params[:email]
      render 'new', status: :unprocessable_entity
    end
  end

  def destroy
    track :regular, :logged_out
    session[:user_id] = nil
    cookies.delete :permanent_session_id if cookies.signed[:permanent_session_id]
    redirect_to root_path, notice: 'Logged out!'
  end

  private

  def login_params
    params.permit(:email, :password)
  end
end
