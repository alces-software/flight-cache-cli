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

require 'tty-table'
require 'filesize'

class FlightCacheCli
  # Unicode messes with ruby syntax highlighting, thus it is easier to have
  # it as a constant instead
  LOCK_SUFFIX = ' 🔒'

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

  def self.render_table(enum, table_data)
    table = TTY::Table.new header: table_data.keys
    enum.each { |e| table << table_data.values.map { |v| v.call(e) } }
    table.render(:ascii, padding: [0, 1])
  end

  command :'list' do |c|
    c.syntax = 'list [TAG]'
    c.summary = 'Retrieve and filter the files'
    c.description = <<~DESC.chomp
      By default this will return all the files you have access to. This
      includes files in the user, group, and public ownership scopes of
      any tag.

      The TAG optional argument can be used to filter the files further by
      their tag. The `--scope` option will limit the resaults to a specific
      ownership scope
    DESC
    scope_option(c)
    act(c) do |tag = nil, opts|
      puts render_table(
        cache.blobs(tag: tag, scope: opts[:scope]),
        'ID' => proc { |b| { value: b.id, alignment: :right } },
        'Filename' => proc { |b| b.filename },
        'Size' => proc do |b|
          { value: Filesize.new(b.size).pretty, alignment: :right }
        end,
        'Scope' => proc do |b|
          b.scope + (b.protected ? LOCK_SUFFIX : '')
        end
      # Hack the unicode alignment b/c I can't work out how to fix it correctly
      ).gsub(LOCK_SUFFIX, "#{LOCK_SUFFIX} ")
    end
  end

  command :'list-tags' do |c|
    c.syntax = 'list-tags'
    c.description = 'Retrieve all the tags'
    act(c) do
      puts render_table(
        cache.tags,
        'Name' => proc { |t| t.name },
        'Max. Size' => proc do |t|
          { value: Filesize.new(t.max_size).pretty, alignment: :right }
        end,
        'Restricted' => proc do |t|
          { value: t.restricted ? '✓' : '-', alignment: :center }
        end
      )
    end
  end

  command :download do |c|
    c.syntax = 'download ID [FILEPATH]'
    c.summary = 'Download the file by id'
    c.description = <<~DESC.chomp
      Downloads the given file by its id. The file will be saved to the
      path given by FILEPATH. This can either be an absolute or relative to
      the current working directory.

      Alternatively the content can be wrote to stdout by setting the
      FILEPATH to '-' (without quotes). Finally, if the FILENAME is missing
      it will download the file according to its name on the server.
    DESC
    act(c) do |id, filename = nil, _o|
      filename ||= cache.blob(id).filename
      path = File.expand_path(filename)
      if File.exists?(path)
        cur_index = Dir.glob("#{path}\.*")
                       .map { |p| p.sub("#{path}.", '') }
                       .select { |s| s.match(/^(\d)+$/) }
                       .map(&:to_i)
                       .max || 0
        path = "#{path}.#{cur_index + 1}"
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
    c.summary = 'Destroys the given file and returns it metadata'
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

