
require 'flight_config'

class FlightCacheCli
  class Config
    include FlightConfig::Reader

    allow_missing_read

    def self.new__data__
      super().tap do |data|
        data.env_prefix = :flight_cache
        data.set_from_env(:host)
      end
    end

    def path
      File.expand_path(File.join(__dir__, '../..', 'etc/config.yaml'))
    end

    def host
      __data__.fetch(:host, default: 'https://cache.alces-flight.com')
    end
  end
end
