class GeoipInfo
    include Mongoid::Document

    field :ip, type:String
    field :continent_code, type:String
    field :continent_name, type:String
    field :country_code2, type:String
    field :country_code3, type:String
    field :country_name, type:String
    field :country_capital, type:String
    field :state_prov, type:String
    field :district, type:String
    field :city, type:String
    field :zipcode, type:String
    field :latitude, type:String
    field :longitude, type:String
    field :is_eu, type:Boolean
    field :calling_code, type:String
    field :country_tld, type:String
    field :languages, type:String
    field :country_flag, type:String
    field :geoname_id, type:String
    field :isp, type:String
    field :connection_type, type:String
    field :organization, type:String
    field :asn, type:String
    field :currency, :type => Hash
    field :time_zone, :type => Hash
    field :security, :type => Hash
end