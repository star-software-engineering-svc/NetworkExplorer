class HomeController < ApplicationController
    def index
    end

    def login
        @email = params[:email]
        @password = params[:password]

        if @email == ""
            @error = "The email is required."
            return
        end

        if @password == nil or @password == ""
            @error = "The password is required."
            return
        end

        exists = User.where(email: @email).exists?
        
        if exists
            @user = User.where(email: @email).first
            if @user.password == Digest::MD5.hexdigest(@password)
                session[:_id] = @user[:_id]
                session[:username] = @user[:name]
                session[:email] = @user[:email]
                redirect_to home_search_url() and return
            else
                @error = "The password is not correct."
            end
        else
            @error = "The email address is not registered yet."
        end

        render 'index'
    end

    def signup
        if request.POST.size > 0
            @name = params[:name]
            @email = params[:email]
            @password = params[:password]

            if @name == ""
                @error = "The name is required."
                return
            end

            if @email == ""
                @error = "The email is required."
                return
            end

            if @password == nil or @password == ""
                @error = "The password is required."
                return
            end

            exists = User.where(email: @email).exists?

            if exists 
                @error = "The email address exists already."
                return
            end

            user = User.new
            user.name = @name
            user.email = @email
            user.password = Digest::MD5.hexdigest(@password)
            user.save

            redirect_to home_index_url() and return
        end
    end

    def search
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

        query = params[:query]
        if ClientConnections.where(ipaddr: query).exists?
            @client_connections = ClientConnections.where(ipaddr: query).first
        end
    end

    def logout
        reset_session
        redirect_to home_index_url() and return
    end
end
