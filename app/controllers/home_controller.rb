class HomeController < ApplicationController
    def index
    end

    def login
    end

    def signup
        if request.POST
            @name = params[:name]
            @email = params[:email]
            @password = params[:password]

            user = User.new
            user.name = @name
            user.email = @email
            user.password = @password
            user.save
        end
    end

    def search
    end
end
