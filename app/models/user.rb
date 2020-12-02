class User
    include Mongoid::Document

    field :name, type:String
    field :email, type:String
    field :password, type:String
    field :is_admin, type:Boolean
    field :is_verified, type:Boolean
end