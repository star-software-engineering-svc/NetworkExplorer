class ClientConnections
    include Mongoid::Document

    field :timestamp, type:Integer
    field :conn_type, type:String
    field :socket_num, type:Integer
    field :ipaddr, type:String
    field :conn_num, type:Integer
    field :"servername", type:String
end