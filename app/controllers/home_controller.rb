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
                session[:name] = @user[:name]
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

        @valid = IPAddress.valid? @query

        if @valid

            @aggResult = ClientConnections.collection.aggregate([
                { '$match' =>
                    { 'ipaddr' => @query }
                }, 
                {
                    '$lookup' => {
                        'from' => 'hashed_sites_seens',
                        'localField' => 'timestamp',
                        'foreignField' => 'timestamp',
                        'as' => 'matched_timestamp'
                    }
                }, 
                {
                    '$sort' => { 'timestamp' => 1 }
                }
            ]).count

            if @aggResult > 0
                @exists = GeoipInfo.where(ip: @query).exists?
                if @exists
                    @result = GeoipInfo.where(ip: @query).first
                end
            end
        end
    end

    def getConnections
        @query = params[:query]
        length = params[:length]

        result = ClientConnections.where(ipaddr: @query).order(:timestamp => 'asc').offset(0).limit(length)

        respond_to do |format|
            msg = { :result => result }
            format.json  { render :json => msg }
        end
    end

    def getConnectionsGraph
        @query = params[:query]
        length = params[:length]

        connections = ClientConnections.collection.aggregate([
            {
                '$match' => { 'ipaddr' => @query }
            }, 
            {
                "$group" => { 
                    '_id' => "$servername",
                    'count' => { '$sum' => 1 },
                    "servername" => { "$first" => "$servername" }, 
                    "conn_num" => { '$sum' => "$conn_num" } 
                }
            },
            {
                "$limit" => length.to_i
            }
        ])

        nodes = []
        nodes << {:id => @query, :label => @query, :color => '#ee5149', :x => 0, :y => 0, :size => 10}

        edges = []

        connections.each do |p|
            size = p[:conn_num]
            if size < 100
                size = 5
            elsif size < 1000
                size = 10
            elsif size < 5000
                size = 15
            elsif size < 10000
                size = 20
            else
                size = 30
            end

            nodes << {:id => p[:_id], :label => p[:_id], :color => '#193053', :x => Random.new.rand(-500..500), :y => Random.new.rand(-500..500), :size => size, :conn_num => p[:conn_num], :total => p[:count] }
            edges << {:sourceID => @query, :targetID => p[:_id], :size => 1}
        end

        respond_to do |format|
            msg = { :nodes => nodes, :edges => edges }
            format.json  { render :json => msg }
        end
    end

    def logout
        reset_session
        redirect_to home_index_url() and return
    end

    def users
        id = session[:_id]["$oid"]
        user = User.find_by(_id: id)

        if not user.is_admin
            render 'accessdenied'
            return
        end
    end

    def getUsers
        id = session[:_id]["$oid"]
        user = User.find_by(_id: id)

        if not user.is_admin
            respond_to do |format|
                msg = { :type => 'e_fail' }
                format.json  { render :json => msg }
            end
            return
        end
        
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
        
        myid = session[:_id]["$oid"]
        me = User.find_by(_id: myid)

        if not me.is_admin
            respond_to do |format|
                msg = { :type => 'e_fail' }
                format.json  { render :json => msg }
            end
            return
        end

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
        id = session[:_id]["$oid"]
        name = params[:name]
        current_password = params[:current_password]
        email = params[:name]
        password = params[:password]
        repassword = params[:repassword]

        if name == ""
            @error = "The name is the required field."
            render "profile"
            return
        end

        if current_password == ""
            @error = "Please input the current password."
            render "profile"
            return
        end

        if password == ""
            @error = "Please input the new password."
            render "profile"
            return
        end

        if password != repassword
            @error = "Please confirm the new password."
            render "profile"
            return
        end

        user = User.find_by(_id: id)

        if user.password != Digest::MD5.hexdigest(current_password)
            @error = "The current password is not correct."
            render "profile"
            return
        end

        user.name = name
        user.password = Digest::MD5.hexdigest(password)
        user.save

        session[:name] = name

        render "profile"
        return
    end
end
