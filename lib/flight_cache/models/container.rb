# frozen_string_literal: true

#
# =============================================================================
# Copyright (C) 2019 Stephen F. Norledge and Alces Flight Ltd
#
# This file is part of Flight Cache
#
# Flight Cache is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# Flight Cache is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with Flight Cache.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Flight Cache, please visit:
# https://github.com/alces-software/flight-cache
# https://github.com/alces-software/flight-cache-cli
# ==============================================================================
#

module FlightCache
  module Models
    class Container < Hashie::Dash
      def self.api_build(data)
        new(
          id: data.id,
          tag: data.attributes&.tag,
          blobs: data.relationships&.blobs&.data&.map { |b| Blob.api_build(b) }
        )
      end

      def self.show(id, client:)
        api_build(client.connection.get_container_by_id(id).body.data)
      end

      property :id, required: true
      property :tag
      property :blobs
    end
  end
end
