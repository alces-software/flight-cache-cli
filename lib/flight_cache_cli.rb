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

require 'flight_cache_cli/config'
require 'flight_cache_cli/account_config'

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
      yield(*args, opts.__hash__)
    end
  end

  def self.scope_option(command)
    command.option '-s', '--scope SCOPE', 'Specify the tagged scope'
  end

  def self.cache
    FlightCache.new(Config.read.host, AccountConfig.read.auth_token)
  end

  command :list do |c|
    c.syntax = 'list'
    c.description = 'Retrieve and filter multiple blobs or tags'
    c.sub_command_group = true
  end

  command :'list blobs' do |c|
    c.syntax = 'list blobs [TAG]'
    c.summary = 'Retrieve and filter the blobs'
    c.description = <<~DESC.chomp
      By default this will return all the blobs you have access to. This
      includes blobs in the user, group, and public ownership scopes of
      any tag.

      The TAG optional argument can be used to filter the blobs further by
      their tag. The `--scope` option will limit the resaults to a specific
      ownership scope
    DESC
    c.hidden = true
    scope_option(c)
    act(c) do |tag = nil, scope: nil|
      pp cache.blobs(tag: tag, scope: scope).map(&:to_h)
    end
  end

  command :'list tags' do |c|
    c.syntax = 'list tags'
    c.description = 'Retrieve all the tags'
    c.hidden = true
    act(c) { pp cache.tags.map(&:to_h) }
  end

  command :download do |c|
    c.syntax = 'download ID FILEPATH'
    c.summary = 'Download the blob by id'
    c.description = <<~DESC.chomp
      Downloads the given blob by its id. The file will be saved to the
      path given by FILEPATH. This can either be an absolute or relative to
      the current working directory.

      Alternatively the content can be wrote to standard out by setting the
      FILEPATH to '-' (without quotes).
    DESC
    act(c) do |id, filename|
      io = cache.download(id)
      if filename == '-'
        print io.read
      elsif io.is_a?(Tempfile)
        FileUtils.mv io.path, filename
      else
        File.write(filename, io.read)
      end
    end
  end

  command :get do |c|
    c.syntax = 'get ID'
    c.description = 'Get the metadata about a particular blob'
    act(c) do |id|
      pp cache.blob(id).to_h
    end
  end

  command :upload do |c|
    c.syntax = 'upload TAG FILEPATH'
    c.description = 'Upload the file to the TAG'
    scope_option(c)
    act(c) do |tag, filepath, scope: nil|
      filename = File.basename(filepath),
      io = File.open(filepath, 'r')
      pp cache.upload(filename, io, tag: tag, scope: scope).to_h
    end
  end
end

