class HomeController < ApplicationController
    def index
    end

    def login
        @email = params[:email]
        @password = params[:password]

        if @email == ""
            @error = "The email is required."
            render 'index'
            return
        end

        if @password == nil or @password == ""
            @error = "The password is required."
            render 'index'
            return
        end

        exists = User.where(email: @email).exists?
        
        if exists
            @user = User.where(email: @email).first
            if @user.is_verified != true
                @error = "Your account is not verified yet."
                render 'index'
                return
            end

            if @user.password == Digest::MD5.hexdigest(@password)
                session[:_id] = @user[:_id]
                session[:username] = @user[:name]
                session[:email] = @user[:email]
                session[:is_admin] = @user[:is_admin]
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
            user.is_admin = false
            user.is_verified = false
            user.save

            redirect_to home_index_url() and return
        end
    end

    def search
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

        @query = params[:query]
        @exists = GeoipInfo.where(ip: @query).exists?
        if @exists
            @result = GeoipInfo.where(ip: @query).first
        end
    end

    def logout
        reset_session
        redirect_to home_index_url() and return
    end

    def users
    end

    def getUsers
        search = params[:search]
        search_value = search[:value]
        start = params[:start]
        length = params[:length]

        users = User.any_of({ :name => /.*#{search_value}.*/i }).offset(start).limit(length)

        i = 1
        results = Array.new
        users.each do |p|
            results << { :no => start.to_i + i, :_id => p[:_id], :name => p[:name], :email => p[:email], :is_admin => p[:is_admin], :is_verified => p[:is_verified] }
        end

        recordsTotal = User.any_of({ :name => /.*#{search_value}.*/i }).count
        recordsFiltered = User.any_of({ :name => /.*#{search_value}.*/i }).count
        respond_to do |format|
            msg = { :draw => params[:draw], :recordsTotal => recordsTotal, :recordsFiltered => recordsFiltered, :data => results }
            format.json  { render :json => msg }
        end
    end

    def activateUser
        id = params[:_id]
        flag = params[:flag]

        user = User.find_by(_id: id)
        
        if flag.to_i == 0
            user[:is_verified] = false
            user.save
        else
            user[:is_verified] = true
            user.save
        end

        respond_to do |format|
            msg = { :type => 's_ok' }
            format.json  { render :json => msg }
        end
    end

    def profile
    end

    def updateProfile
    end
end
