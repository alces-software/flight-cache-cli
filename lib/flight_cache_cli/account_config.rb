
require 'flight_config'
require 'flight_cache_cli/errors'

class FlightCacheCli
  class AccountConfig
    include FlightConfig::Reader

    allow_missing_read

    def self.new__data__
      super().tap do |data|
        data.env_prefix = :flight
        data.set_from_env(:auth_token)
      end
    end

    def path
      File.expand_path('~/.config/flight/accounts/config.yml')
    end

    def auth_token
      __data__.fetch(:auth_token) do
        raise MissingToken, <<~ERROR.chomp
          Can not determine your flight credentials as you are not logged in
        ERROR
      end
    end
  end
end
