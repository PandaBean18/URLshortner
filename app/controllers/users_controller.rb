class UsersController < ApplicationController

    def show 
        email = params[:email]
        user = User.find_by(email: email)
        if user
            render json: user
        else 
            render json: {}, status: :not_found
        end
    end
end