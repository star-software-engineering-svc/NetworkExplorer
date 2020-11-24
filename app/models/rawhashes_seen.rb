class RawhashesSeen
    include Mongoid::Document

    field :timestamp, type:Integer
    field :site_type, type:String
    field :rawhash, type:String
    field :servername, type:String
end