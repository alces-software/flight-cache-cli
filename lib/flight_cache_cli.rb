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

require 'commander'

require 'flight_cache'
require 'pp'

class FlightCacheCli
  extend Commander::UI
  extend Commander::UI::AskForClass
  extend Commander::Delegates

  program :name,        'flight-cache'
  program :version,     '0.4.0'
  program :description, 'Manages the flight file cache'
  program :help_paging, false

  silent_trace!

  def self.run!
    ARGV.push '--help' if ARGV.empty?
    super
  end

  def self.act(command)
    command.action do |args, opts|
      yield(*args, opts.to_h)
    end
  end

  def self.cache
    FlightCache.new(ENV['FLIGHT_CACHE_HOST'], ENV['FLIGHT_SSO_TOKEN'])
  end

  command :list do |c|
    c.syntax = 'list'
    c.description = 'Retrieve and filter multiple blobs or tags'
    c.sub_command_group = true
  end

  command :'list blobs' do |c|
    c.syntax = 'list blobs TAG'
    c.description = 'Retrieve all the blobs according to their TAG'
    act(c) do |tag|
      pp cache.blobs(tag).map(&:to_h)
    end
  end

  command :'list tags' do |c|
    c.syntax = 'list tags'
    c.description = 'Retrieve all the tags'
    act(c) { pp cache.tags.map(&:to_h) }
  end

  command :download do |c|
    c.syntax = 'download ID'
    c.description = 'Download the blob by id'
    act(c) do |id|
      print cache.download(id).read
    end
  end

  command :blob do |c|
    c.syntax = 'blob ID'
    c.description = 'Get the metadata about a particular blob'
    act(c) do |id|
      pp cache.blob(id).to_h
    end
  end

  command :upload do |c|
    c.syntax = 'upload CONTAINER_ID FILEPATH'
    c.description = 'Upload the file to the container'
    act(c) do |id, filepath|
      pp cache.client.blobs.uploader(
        filename: File.basename(filepath),
        io:       File.open(filepath, 'r')
      ).to_container(id: id).to_h
    end
  end
end

