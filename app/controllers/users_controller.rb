class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy]

  # GET /users
  def index
    @users = User.all
  end

  # GET /users/1
  def show
  end

  # /signup
  def new
    if signed_in?
      redirect_to root_url
    else
      @user = User.new
    end
  end

  # /signup
  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to signin_path, notice: 'User was successfully created.'
    else
      render :new
    end
  end

  # /profile
  def edit
  end

  # /profile
  def update
    if @user.update(user_params)
      redirect_to profile_path, notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to root_url, notice: 'User was successfully destroyed.'
  end

  private

  def set_user
    @user = current_user
  end

  def user_params
    params.require(:user).permit(:avatar,
      :email,
      :password,
      :password_confirmation,
      :name)
  end
end