# coding: utf-8
require 'mtik'

module MtikPppActive2Directory
  class Mikrotik
    Error = Class.new(StandardError)
    RouterError = Class.new(Error)
    SyncError = Class.new(Error)

    def initialize(params)
      @mtik_params = params.select { |k,_| %w(host user pass).include? k.to_s }
      @mtik_params.update(cmd_timeout:86400)
    end

    # Enumerate the PPP active connections.
    #
    # @return [Enumerator] Arrays with: IP, user
    def list
      Enumerator.new do |y|
        @cache.each_value do |re|
          y << [re['address'], re['name']]
        end
      end
    end

    # Watch for modifications to the PPP active connections.
    #
    # @yield [method, *data]
    #
    # The first +method+ yielded is :start.
    # +data+ is a Hash of {IP => user}.
    #
    # Afterwards, two +method+s may be yielded: :add and :delete.
    # +data+ is the IP and user, added or deleted.
    def watch(&block)
      @cache = {}

      # Listen for modifications to the PPP active connections.
      # Since they haven't been fully fetched yet, buffer them for later.
      buffer = []
      request('/ppp/active/listen', '=.proplist=.dead,.id,name,address') do |re|
        buffer ? buffer.push(re) : update(re, &block) # [1]
      end

      # Fetch all PPP active connections.
      connection.wait_for_request(
          request('/ppp/active/print', '=.proplist=.id,name,address') do |re|
            @cache[re['.id']] = re
          end
      )

      # Apply modifications that happened during the 'print'.
      # Updates that happened after 'listen' started, but before 'print' completed,
      # may cause #update to raise SyncError. It's probably okay to ignore that.
      buffer.each do |bre|
        update(bre, &block) rescue SyncError
      end
      # With 'print' done, call 'update' directly instead of buffering.
      buffer = nil # See [1]

      # Start by yielding the entire PPP active connections list.
      # Afterwards, only changes will be yielded.
      yield(:start, Hash[list.to_a])

      # Give control to the 'mtik' gem.
      connection.wait_all
      raise(Error, "The 'watch' method should never return")
    end

    private

    # @param [Hash] re
    # @return [Hash] The same +re+
    def add(re)
      if @cache.key?(re['.id'])
        raise(SyncError, "ID #{re['.id']} already in cache")
      else
        @cache[re['.id']] = re
      end
    end

    # @param [Hash] re
    # @return [Hash] The deleted +re+
    def delete(re)
      @cache.delete(re['.id']).tap do |deleted_re|
        unless deleted_re
          raise(SyncError, "ID #{re['.id']} not in cache")
        end
      end
    end

    # @param [Hash] re
    def update(re)
      method = re.key?('.dead') ? :delete : :add
      re = send(method, re)
      yield(method, re['address'], re['name'])
    end

    # @return [MTik::Connection]
    def connection
      @connection ||= MTik::Connection.new(@mtik_params).tap do
        Log.info { "Connecting to Mikrotik at #{@mtik_params.inspect}" }
      end
    end

    # @return [MTik::Request]
    def request(*args)
      Log.info { "Mikrotik request: #{args.inspect}" }
      connection.request_each(*args) do |request|
        while (re = request.reply.shift)
          Log.info { "Mikrotik reply: #{re.inspect}" }
          if re.key?('!re') ; yield(re)
          elsif re.key?('!done') ; nil
          elsif re.key?('!trap') ; raise(RouterError, re['message'])
          else raise(Error, "Unrecognized Mikrotik reply: #{re.inspect}")
          end
        end
      end
    end
  end
end
