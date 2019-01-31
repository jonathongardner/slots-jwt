
require_dependency "slots/application_controller"
module Slots
  class ManagesController < ApplicationController
    require_login! load_user: true, except: [:create, :new_confirmation_token]

    # POST /manages
    def create
      @manage = authentication_model.new(manage_params(:password, :password_confirmation))
      if @manage.save
        # TODO Think about returning the token on create
        # @manage.create_token(ActiveModel::Type::Boolean.new.cast(params[:session]))
        # render json: @manage.as_json(methods: :token), status: :created
        render json: @manage.as_json, status: :created
      else
        render json: {errors: @manage.errors}, status: :unprocessable_entity
      end
    end

    # PATCH/PUT /manages
    def update
      # To change any user information you need to reenter the password
      return render json: {errors: {authentication: ['password is invalid']}}, status: :unauthorized unless current_user.authenticate?(params[:password])
      if current_user.update(manage_params(:password, :password_confirmation))
        render json: current_user.as_json, status: :accepted
      else
        render json: {errors: current_user.errors}, status: :unprocessable_entity
      end
    end

    def new_confirmation_token
      require_valid_loaded_user(confirmed: false)
      # This will unconfirm user if they are confirmed think about disabling this route
      current_user.set_new_confirmation_token
      if current_user.save
        head :accepted
      else
        render json: {errors: current_user.errors}, status: :unprocessable_entity
      end
    end

    catch_invalid_token
    catch_access_denied
    # # DELETE /manages/1
    # def destroy
    #   @manage.destroy
    #   redirect_to manages_url, notice: 'Manage was successfully destroyed.'
    # end

    private
      def authentication_model
        Slots.configuration.authentication_model
      end
      def manage_columns
        authentication_model.column_names - ['id', 'password_digest', 'approved', 'confirmed', 'confirmation_token']
      end

      # Only allow a trusted parameter "white list" through.
      def manage_params(*columns)
        params.require(authentication_model.name.underscore.to_sym).permit(*manage_columns, *columns)
      end
  end
end
