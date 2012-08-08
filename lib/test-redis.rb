require "test-redis/version"
require "fileutils"
require "tmpdir"
require "mkmf"
require "socket"

module Test
  class Redis
    def self.auto_start
      @@auto_start ||= false
    end

    def self.auto_start=(value)
      @@auto_start = !!value
    end

    def initialize(options={})
      setup options
      start if !!options[:auto_start] || self.class.auto_start
    end

    def start
      return if @pid
      write_conf conf
      fork_redis
      at_exit { stop }
      wait_redis
      nil
    end

    def stop(signal=nil)
      return unless @pid

      if File.exist? conf["pidfile"]
        realpid = File.read(conf["pidfile"]).strip.to_i
        kill realpid, signal
        FileUtils.rm_f conf["pidfile"]
      end

      kill @pid, signal

      @pid = nil
    end

    def restart
      stop
      start
    end

    def info
      read_info
    end

    attr_reader :base_dir, :conf, :redis, :pid

    private

    def read_info
      info = nil
      sock = TCPSocket.open("127.0.0.1", conf["port"])
      begin
        sock.write "INFO\r\n"
        size = sock.gets("\r\n")[1..-3].to_i
        info = sock.read(size + 2)
        sock.write "QUIT\r\n"
      ensure
        sock.close
      end
      return nil unless info
      info.each_line("\r\n").each_with_object({}) do |line, result|
        key, value = line.chomp.split ":"
        next if key.nil?
        result[key] = value
      end
    end

    def write_conf(conf)
      File.open(base_dir + "/redis.conf", "w") do |f|
        conf.each do |key, val|
          f.puts "#{key} #{val}"
        end
      end
    end

    def fork_redis
      redis_log = File.open(base_dir + "/redis-server.log", "a")
      @pid = fork do
        $stdout.reopen redis_log
        $stderr.reopen redis_log
        exec %[#{redis} "#{base_dir}/redis.conf"]
      end
      exit unless @pid
      redis_log.close
    end

    def wait_redis
      output = nil
      begin
        while !File.exist? conf["pidfile"]
          if Process.waitpid pid, Process::WNOHANG
            output = File.read base_dir + "/redis-server.log"
            output+= File.read conf["logfile"]
          end
          sleep 0.1
        end
      rescue
        raise "redis-server failed " + (output ||= "")
      end
    end

    def kill(pid, signal)
      Process.kill Signal.list[signal || "TERM"], pid rescue nil
      Process.waitpid pid rescue nil
    end

    def setup(options)
      @base_dir = options[:base_dir] || default_base_dir
      @redis    = options[:redis] || find_redis
      @conf     = default_conf.merge(options[:conf] || {})
    end

    def default_conf
      {
        "daemonize"      => "yes",
        "databases"      => 16,
        "dbfilename"     => "dump.rdb",
        "dir"            => base_dir,
        "logfile"        => base_dir + "/redis.log",
        "loglevel"       => "debug",
        "pidfile"        => base_dir + "/redis.pid",
        "port"           => 16379,
        "rdbcompression" => "no",
        "timeout"        => 0,
        "unixsocket"     => base_dir + "/redis.sock",
      }
    end

    def default_base_dir
      Dir.mktmpdir.tap { |dir|
        at_exit { FileUtils.remove_entry_secure dir if FileTest.directory? dir }
      }
    end

    def find_redis
      suppress_logging
      find_executable "redis-server"
    end

    def suppress_logging
      Logging.quiet = true
      Logging.logfile base_dir + "/mkmf.log"
    end
  end
end
