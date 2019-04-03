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
  program :version,     '0.5.1'
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

  command :'list' do |c|
    c.syntax = 'list [TAG]'
    c.summary = 'Retrieve and filter the blobs'
    c.description = <<~DESC.chomp
      By default this will return all the blobs you have access to. This
      includes blobs in the user, group, and public ownership scopes of
      any tag.

      The TAG optional argument can be used to filter the blobs further by
      their tag. The `--scope` option will limit the resaults to a specific
      ownership scope
    DESC
    scope_option(c)
    act(c) do |tag = nil, scope: nil|
      pp cache.blobs(tag: tag, scope: scope).map(&:to_h)
    end
  end

  command :'list-tags' do |c|
    c.syntax = 'list-tags'
    c.description = 'Retrieve all the tags'
    act(c) { pp cache.tags.map(&:to_h) }
  end

  command :download do |c|
    c.syntax = 'download ID [FILEPATH]'
    c.summary = 'Download the blob by id'
    c.description = <<~DESC.chomp
      Downloads the given blob by its id. The file will be saved to the
      path given by FILEPATH. This can either be an absolute or relative to
      the current working directory.

      Alternatively the content can be wrote to stdout by setting the
      FILEPATH to '-' (without quotes). Finally, if the FILENAME is missing
      it will download the file according to its name on the server.
    DESC
    c.option '-f', '--force', 'Overwrite any existing files'
    act(c) do |id, filename = nil, opts|
      filename ||= cache.blob(id).filename
      path = File.expand_path(filename)
      if opts[:force] && File.exists?(path)
        $stderr.puts "Overwriting existing file..."
      elsif File.exists?(path)
        raise ExistingFileError, "The file already exists: #{path}"
      end
      io = cache.download(id)
      if filename == '-'
        print io.read
      elsif io.is_a?(Tempfile)
        FileUtils.mv io.path, path
        puts "Downloaded: #{path}"
      else
        File.write(path, io.read)
        puts "Downloaded: #{path}"
      end
    end
  end

  command :delete do |c|
    c.syntax = 'delete ID'
    c.summary = 'Destroys the given blob and returns it metadata'
    act(c) do |id|
      blob = cache.delete(id)
      puts "File '#{blob.filename}' has been deleted"
    end
  end

  command :upload do |c|
    c.syntax = 'upload TAG FILEPATH [FILENAME]'
    c.summary = 'Upload the file to the TAG'
    c.description = <<~DESC.chomp
      Uploads the file to the given tag. The FILENAME is used as a label on
      the server. The FILEPATH gives the file to be uploaded. Content can be
      uploaded from stdin by setting FILEPATH to '-' (without quotes).
    DESC
    scope_option(c)
    act(c) do |tag, filepath, name = nil, opts|
      name ||= File.basename(filepath)
      io = (filepath == '-' ? $stdin : File.open(filepath, 'r'))
      blob = cache.upload(name, io, tag: tag, scope: opts[:scope])
      puts "File '#{blob.filename}' has been uploaded. Size: #{blob.size}B"
    end
  end
end

