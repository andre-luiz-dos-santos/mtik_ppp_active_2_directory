# coding: utf-8

module MtikPppActive2Directory
  class Directory
    Error = Class.new(StandardError)
    SyncError = Class.new(Error)

    # The {#list} method will not enumerate symbolic links that do not match this regular expression.
    # Other methods may raise Error.
    IP_RE = %r{ \A \d{1,3} \. \d{1,3} \. \d{1,3} \. \d{1,3} \z }x

    # Manage a directory of symbolic links.
    #
    # The IP address is the name of the symbolic link.
    # The user name is what the symbolic link points to.
    #
    # @param [Hash] params
    # @option params [String] :path The path to the directory containing symbolic links
    def initialize(params)
      @path = params[:path]
    end

    # Return the user name associated with +ip+.
    #
    # @param [String] ip
    #
    # @raise [SyncError] When the +ip+ is not found
    # @return [String] The interface associated with +ip+
    def [](ip)
      (ip =~ IP_RE) || raise(Error, "Invalid IP [#{ip}]")
      file = File.join(@path, ip)
      File.readlink(file)
    rescue Errno::ENOENT
      raise(SyncError, "IP [#{ip}] not found [#{file}]")
    rescue Errno::EINVAL
      raise(Error, "IP [#{ip}] is not a symlink [#{file}]")
    end

    # Associate +user+ to +ip+.
    #
    # @param [String] ip
    # @param [String] user
    def []=(ip, user)
      (ip =~ IP_RE) || raise(Error, "Invalid IP [#{ip}]")
      file = File.join(@path, ip)
      tmp = "#{file}.tmp"
      File.symlink(user, tmp)
      File.rename(tmp, file)
    end

    # Delete the +ip+ association.
    #
    # @param [String] ip
    #
    # @raise [SyncError] When the +ip+ is not found
    # @return [void]
    def delete(ip)
      (ip =~ IP_RE) || raise(Error, "Invalid IP [#{ip}]")
      file = File.join(@path, ip)
      File.unlink(file)
    rescue Errno::ENOENT
      raise(SyncError, "IP [#{ip}] not found [#{file}]")
    end

    # Enumerate all IP associations.
    #
    # @return [Enumerator] Arrays with: IP, user
    def list
      Enumerator.new do |y|
        Dir.foreach(@path) do |de| file = File.basename(de)
        (file =~ IP_RE) && (value = self[file]) && (y << [file, value])
        end
      end
    end
  end
end
