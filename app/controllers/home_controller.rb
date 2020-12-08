require 'csv'
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

    def isHash(query)
        return query && (query.length == 16 || query.length == 53)
    end

    def search
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

        @query = params[:query]

        @validIp = IPAddress.valid? @query
        @validHash = self.isHash(@query)
        @valid = @validIp | @validHash
        
        if not @valid
            @errorMsg = "The site or ip address is not valid."
            return
        end

        if @validIp
            @aggResult = ClientConnection.collection.aggregate([
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
                    @connCount = ClientConnection.where(ipaddr: @query).count
                    @graphCount = ClientConnection.collection.aggregate([
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
                        }
                    ]).count
                    render 'searchip' and return
                else
                    @errorMsg = "No results found."
                end
            else
                @errorMsg = "No results found."
            end
        elsif @validHash
            @aggResult = HashedSitesSeen.collection.aggregate([
                { '$match' =>
                    { 'hashed_site' => @query }
                }, 
                {
                    '$lookup' => {
                        'from' => 'client_connections',
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
                @hash_sites_seen = HashedSitesSeen.where(hashed_site: @query).first
                @connCount = ClientConnection.where(timestamp: @hash_sites_seen.timestamp).count
                @graphCount = ClientConnection.collection.aggregate([
                    {
                        '$match' => { 'timestamp' => @hash_sites_seen.timestamp }
                    }, 
                    {
                        '$lookup' => {
                            'from' => 'geoip_infos',
                            'localField' => 'ipaddr',
                            'foreignField' => 'ip',
                            'as' => 'matched_geoip'
                        }
                    }
                ]).count
                @connections = ClientConnection.collection.aggregate([
                    {
                        '$match' => { 'timestamp' => @hash_sites_seen.timestamp }
                    }, 
                    {
                        '$lookup' => {
                            'from' => 'geoip_infos',
                            'localField' => 'ipaddr',
                            'foreignField' => 'ip',
                            'as' => 'matched_geoip'
                        }
                    }, 
                    {
                        '$sort' => { 'conn_num' => -1 }
                    },
                    {
                        "$limit" => 3
                    }
                ])
            
                render 'searchsite' and return
            else
                @errorMsg = "No results found."
            end
        end
    end

    def getConnections
        if session[:email] == nil
            respond_to do |format|
                msg = { :type => 'e_fail' }
                format.json  { render :json => msg }
            end
            return
        end

        @query = params[:query]
        length = params[:length]

        valid = IPAddress.valid? @query

        if valid 
            result = ClientConnection.where(ipaddr: @query).order(:timestamp => 'asc').offset(0).limit(length)
        else
            hash_sites_seen = HashedSitesSeen.where(hashed_site: @query).first
            result = ClientConnection.where(timestamp: hash_sites_seen.timestamp).order(:timestamp => 'asc').offset(0).limit(length)
        end

        respond_to do |format|
            msg = { :result => result }
            format.json  { render :json => msg }
        end
    end

    def to_conn_csv(result)
        attributes = %w{servername conn_num timestamp} #customize columns here

        CSV.generate(headers: true) do |csv|
            csv << attributes

            result.each do |conn|
                csv << attributes.map{ |attr| conn.send(attr) }
            end
        end
    end

    def exportConnections
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

        @query = params[:query]
        length = params[:length]

        valid = IPAddress.valid? @query

        result = []
        if valid 
            if length.to_i > 0
                result = ClientConnection.where(ipaddr: @query).order(:timestamp => 'asc').offset(0).limit(length)
            else
                result = ClientConnection.where(ipaddr: @query)
            end
        else
            hash_sites_seen = HashedSitesSeen.where(hashed_site: @query).first
            if length.to_i > 0
                result = ClientConnection.where(timestamp: hash_sites_seen.timestamp).order(:timestamp => 'asc').offset(0).limit(length)
            else
                result = ClientConnection.where(timestamp: hash_sites_seen.timestamp)
            end
        end

        send_data self.to_conn_csv(result), filename: "connections-#{Date.today}.csv"
    end

    def getConnectionsGraph
        if session[:email] == nil
            respond_to do |format|
                msg = { :type => 'e_fail' }
                format.json  { render :json => msg }
            end
            return
        end
        
        @query = params[:query]
        length = params[:length]

        valid = IPAddress.valid? @query

        if valid
            connections = ClientConnection.collection.aggregate([
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
        else
            hash_sites_seen = HashedSitesSeen.where(hashed_site: @query).first
            connections = ClientConnection.collection.aggregate([
                {
                    '$match' => { 'timestamp' => hash_sites_seen.timestamp }
                }, 
                {
                    '$lookup' => {
                        'from' => 'geoip_infos',
                        'localField' => 'ipaddr',
                        'foreignField' => 'ip',
                        'as' => 'matched_geoip'
                    }
                }, 
                {
                    '$sort' => { 'conn_num' => -1 }
                },
                {
                    "$limit" => length.to_i
                }
            ])
        end

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

            if valid
                nodes << {:id => p[:_id], :label => p[:_id], :color => '#193053', :x => Random.new.rand(-500..500), :y => Random.new.rand(-500..500), :size => size, :conn_num => p[:conn_num], :total => p[:count] }
                edges << {:sourceID => @query, :targetID => p[:_id], :size => 1}
            else
                nodes << {:id => p[:ipaddr], :label => p[:ipaddr], :color => '#193053', :x => Random.new.rand(-500..500), :y => Random.new.rand(-500..500), :size => size, :conn_num => p[:conn_num], :total => p[:count] }
                edges << {:sourceID => @query, :targetID => p[:ipaddr], :size => 1}
            end
        end

        respond_to do |format|
            msg = { :nodes => nodes, :edges => edges }
            format.json  { render :json => msg }
        end
    end

    def to_conn_graph_csv(result)
        attributes = %w{servername conn_num count} #customize columns here

        CSV.generate(headers: true) do |csv|
            csv << attributes

            result.each do |conn|
                csv << [conn[:servername], conn[:conn_num], conn[:count]]
            end
        end
    end

    def to_conn_graph_site_csv(result)
        attributes = %w{servername ipaddr conn_num count} #customize columns here

        CSV.generate(headers: true) do |csv|
            csv << attributes

            result.each do |conn|
                csv << [conn[:servername], conn[:ipaddr], conn[:conn_num], conn[:count]]
            end
        end
    end

    def exportConnectionsGraph
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

        @query = params[:query]
        length = params[:length]

        result = []
        valid = IPAddress.valid? @query
        if  valid
            if length.to_i > 0
                connections = ClientConnection.collection.aggregate([
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
            else
                connections = ClientConnection.collection.aggregate([
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
                ])
            end
        
            send_data self.to_conn_graph_csv(connections), filename: "connections-graph-#{Date.today}.csv"
        else
            hash_sites_seen = HashedSitesSeen.where(hashed_site: @query).first

            if length.to_i > 0
                connections = ClientConnection.collection.aggregate([
                    {
                        '$match' => { 'timestamp' => hash_sites_seen.timestamp }
                    }, 
                    {
                        '$lookup' => {
                            'from' => 'geoip_infos',
                            'localField' => 'ipaddr',
                            'foreignField' => 'ip',
                            'as' => 'matched_geoip'
                        }
                    }, 
                    {
                        '$sort' => { 'conn_num' => -1 }
                    },
                    {
                        "$limit" => length.to_i
                    }
                ])
            else
                connections = ClientConnection.collection.aggregate([
                    {
                        '$match' => { 'timestamp' => hash_sites_seen.timestamp }
                    }, 
                    {
                        '$lookup' => {
                            'from' => 'geoip_infos',
                            'localField' => 'ipaddr',
                            'foreignField' => 'ip',
                            'as' => 'matched_geoip'
                        }
                    }, 
                    {
                        '$sort' => { 'conn_num' => -1 }
                    }
                ])
            end
        
            send_data self.to_conn_graph_site_csv(connections), filename: "connections-graph-#{Date.today}.csv"
        end
    end

    def logout
        reset_session
        redirect_to home_index_url() and return
    end

    def users
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

        id = session[:_id]["$oid"]
        user = User.find_by(_id: id)

        if not user.is_admin
            render 'accessdenied'
            return
        end
    end

    def getUsers
        if session[:email] == nil
            respond_to do |format|
                msg = { :type => 'e_fail' }
                format.json  { render :json => msg }
            end
            return
        end

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
        if session[:email] == nil
            redirect_to home_index_url() and return
        end
        
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
        if session[:email] == nil
            redirect_to home_index_url() and return
        end

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
