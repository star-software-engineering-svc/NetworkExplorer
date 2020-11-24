class HashedSitesSeen
    include Mongoid::Document

    field :timestamp, type:Integer
    field :hashed_site, type:String
    field :servername, type:String
end