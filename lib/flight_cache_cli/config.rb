# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2019-present Alces Flight Ltd.
#
# This file is part of flight-cache-cli.
#
# This program and the accompanying materials are made available under
# the terms of the Eclipse Public License 2.0 which is available at
# <https://www.eclipse.org/legal/epl-2.0>, or alternative license
# terms made available by Alces Flight Ltd - please direct inquiries
# about licensing to licensing@alces-flight.com.
#
# This project is distributed in the hope that it will be useful, but
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, EITHER EXPRESS OR
# IMPLIED INCLUDING, WITHOUT LIMITATION, ANY WARRANTIES OR CONDITIONS
# OF TITLE, NON-INFRINGEMENT, MERCHANTABILITY OR FITNESS FOR A
# PARTICULAR PURPOSE. See the Eclipse Public License 2.0 for more
# details.
#
# You should have received a copy of the Eclipse Public License 2.0
# along with this project. If not, see:
#
#  https://opensource.org/licenses/EPL-2.0
#
# For more information on flight-cache-cli, please visit:
# https://github.com/alces-software/flight-cache-cli
#===============================================================================

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
