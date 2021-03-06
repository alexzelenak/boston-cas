class AccountsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user

  def edit

  end

  def update
    changed_notes = []
    if @user.first_name != account_params[:first_name] && @user.last_name != account_params[:last_name] 
      changed_notes << "Account name was updated."
    end
    if @user.email != account_params[:email]
      changed_notes << "Account email was updated, check your inbox for a confirmation link."
    end
    if  account_params[:password] == account_params[:password_confirmation]
      changed_notes << "Password was changed."
    end
    if @user.update_with_password(account_params)
      flash[:notice] = changed_notes.join(' ')
      # Update any associated contact
      @user.contact.update(contact_params)
      sign_in(@user, :bypass => true)
      redirect_to edit_account_path
    else
      render 'edit'
    end

  end
  private
    def account_params
      params.require(:user).
        permit(
          :first_name,
          :last_name,
          :email,
          :current_password,
          :password,
          :password_confirmation,
        )
    end

    def contact_params
      params.require(:user).
        permit(
          :first_name,
          :last_name,
          :email,
        )
    end

    def set_user
      @user = current_user
    end

end