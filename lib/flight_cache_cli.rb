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

require 'tempfile'

require 'tty-editor'
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
  program :version,     '0.6.2'
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

  def self.admin_option(command)
    command.option '--admin', 'Preform an admin request [ADMINS ONLY]'
  end

  def self.set_title_option(command)
    command.option '--title TITLE', "Set the file's title"
  end

  def self.set_label_option(command)
    command.option '--label LABEL', "Set the file's label"
  end

  def self.cache
    FlightCache.new(Config.read.host, AccountConfig.read.auth_token)
  end

  def self.render_table(enum, table_data)
    return 'Nothing to display' if enum.empty?
    table = TTY::Table.new header: table_data.keys
    enum.each { |e| table << table_data.values.map { |v| v.call(e) } }
    table.render(:ascii, padding: [0, 1])
  end

  def self.pretty_bytes(num_byte)
    Filesize.new(num_byte).pretty(precision: 0)
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
      ownership scope.

      The `--label` option will filter the files to those that exactly match
      the label. This can be combined with the `--wild` flag to preform a
      wildcard search. Wildcard searches will contain the exact matches and
      any labels that conform to the `<label>/*` format.
    DESC
    scope_option(c)
    admin_option(c)
    c.option '--label LABEL', 'Return the files with a matching label'
    c.option '--wild', 'Preform a wildcard match on the label'
    act(c) do |tag = nil, opts|
      puts render_table(
        cache.client.blobs.list(tag: tag,
                                scope: opts[:scope],
                                label: opts[:label],
                                wild: opts[:wild],
                                admin: opts[:admin]
                               ).sort_by { |b| b.id.to_i },
        'ID' => proc { |b| { value: b.id, alignment: :right } },
        'Filename' => proc { |b| b.filename },
        'Title' => proc { |b| b.title },
        'Tag' => proc { |b| b.tag_name },
        'Label' => proc { |b| b.label },
        'Size' => proc do |b|
          { value: pretty_bytes(b.size), alignment: :right }
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
        cache.tags.sort_by { |t| t.name },
        'Name' => proc { |t| t.name },
        'Max. Size' => proc do |t|
          { value: pretty_bytes(t.max_size), alignment: :right }
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
    admin_option(c)
    set_title_option(c)
    set_label_option(c)
    act(c) do |tag, filepath, name = nil, opts|
      name ||= File.basename(filepath)
      raise <<~ERROR.gsub("\n", ' ').chomp if name == '-'
        The file name must not be a hypen. Please provide the second FILENAME
        argument if uploading from stdin
      ERROR
      io = (filepath == '-' ? $stdin : File.open(filepath, 'r'))
      blob = cache.client
                  .blobs
                  .upload(
                    filename: name,
                    io: io,
                    tag: tag,
                    scope: opts[:scope] || :user,
                    admin: opts[:admin],
                    label: opts[:label],
                    title: opts[:title]
                  )
      puts "File '#{blob.filename}' has been uploaded. Size: #{blob.size}B"
    end
  end

  command :edit do |c|
    c.syntax = 'edit ID'
    c.summary = "Update the file's metadata and content"
    set_title_option(c)
    set_label_option(c)
    c.option '--filename FILENAME', "Set the file's filename"
    act(c) do |id, opts|
      params = {}.tap do |hash|
        hash[:new_filename] = opts[:filename] if opts.key?(:filename)
        hash[:label] = opts[:label] if opts.key?(:label)
        hash[:title] = opts[:title] if opts.key?(:title)
      end
      blob = cache.client.blobs.update(id: id, **params)
      io = blob.download
      Tempfile.open(blob.filename) do |f|
        f.write(io.read)
        f.rewind
        TTY::Editor.open(f.path)
        blob = cache.client.blobs.update(id: blob.id, io: f)
      end
      puts "File #{blob.filename} has been updated"
    end
  end
end

