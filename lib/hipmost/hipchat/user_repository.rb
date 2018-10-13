require 'json'
require 'forwardable'

module Hipmost
  module Hipchat
    class UserRepository
      attr_accessor :users
      extend Forwardable

      def_delegators :@users, :size, :[], :select, :each

      def self.load_from(path)
        new(path).tap(&:load)
      end

      def initialize(path)
        @path  = Pathname.new(path).join("users.json")
        @users = {}
        @name_index = {}
      end

      def load(data = file_data)
        json = JSON.load(data)

        json.each do |user_obj|
          user                           = user_obj["User"]
          user_obj                       = User.new(user)
          @users[user["id"]]             = user_obj
          @name_index[user_obj.username] = user["id"]
        end
      end

      def file_data
        File.read(@path)
      end

      class User
        def initialize(attrs)
          @id    = attrs["id"]
          @attrs = attrs
        end
        attr_reader :id, :attrs

        def guest?
          attrs["account_type"] == "guest"
        end

        def inactive?
          attrs["is_deleted"]
        end

        def method_missing(method)
          attrs[method.to_s]
        end

        def username
          attrs["email"].to_s.split("@")[0] || "deleted"
        end

        def email
          attrs["email"] || "#{username}@orbitalimpact.com"
        end

        def teams
          []
        end

        def to_jsonl
          %[{ "type": "user", "user": { "username": "#{username}", "email": "#{email}", "teams": #{teams.inspect} } }]
        end
      end
    end
  end
end
