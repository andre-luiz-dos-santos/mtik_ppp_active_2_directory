require 'mtik_ppp_active_2_directory/version'
require 'mtik_ppp_active_2_directory/log'
require 'mtik_ppp_active_2_directory/directory'
require 'mtik_ppp_active_2_directory/mikrotik'

module MtikPppActive2Directory
  # Synchronize Mikrotik's PPP active connections with a directory containing symbolic links.
  #
  # @param [Hash] src The object passed to the +mtik+ gem (keys: +host+, +user+, +pass+)
  # @param [String] dst The directory holding the symbolic links
  def self.sync(src, dst)
    Log.info { "Synchronizing router at [#{src[:host]}] with directory [#{dst}]" }
    Sync.new(src, dst).sync
  end

  class Sync
    def initialize(src, dst)
      @mtik = Mikrotik.new(src)
      @dir = Directory.new(path:dst)
    end

    def sync
      @mtik.watch { |*args| send(*args) }
    end

    # @param [Hash] mm Mikrotik Map {IP => user}
    def start(mm)
      dm = Hash[@dir.list.to_a] # Directory Map {IP => user}
      mm.each_pair do |m_ip, m_user|
        if dm.key? m_ip
          if m_user != dm[m_ip]
            update(m_ip, m_user)
          end
        else
          add(m_ip, m_user)
        end
      end
      dm.each_pair do |d_ip, d_user|
        unless mm.key? d_ip
          delete(d_ip, d_user)
        end
      end
    end

    # @param [String] ip
    # @param [String] user
    def add(ip, user)
      Log.info { "Adding IP [#{ip}] user [#{user}]" }
      @dir[ip] = user
    end

    # @param [String] ip
    # @param [String] user
    def update(ip, user)
      Log.info { "Updating IP [#{ip}] user [#{user}]" }
      @dir[ip] = user
    end

    # @param [String] ip
    # @param [String] user
    def delete(ip, user)
      Log.info { "Deleting IP [#{ip}] user [#{user}]" }
      @dir.delete(ip)
    end
  end
end
