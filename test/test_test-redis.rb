gem "minitest"
require "minitest/autorun"
require "redis"
require "test-redis"

class TestTestRedis < MiniTest::Unit::TestCase
  def setup
    @server ||= Test::Redis.new
  end

  def teardown
    server.stop
  end

  def test_start
    assert_nil server.pid
    server.start
    refute_nil server.pid
  end

  def test_ping_with_unixsocket
    server.start
    client = Redis.new :path => server.conf["unixsocket"]
    assert_equal "PONG", client.ping
  end

  def test_ping_with_port
    server.start
    client = Redis.new :port => server.conf["port"]
    assert_equal "PONG", client.ping
  end

  def test_stop
    server.start
    refute_nil server.pid
    server.stop
    assert_nil server.pid
  end

  def test_auto_start_option
    s = Test::Redis.new :auto_start => true
    refute_nil s.pid
    c = Redis.new :path => s.conf["unixsocket"]
    assert_equal "PONG", c.ping
    s.stop
  end

  def test_auto_start
    prev = Test::Redis.auto_start

    Test::Redis.auto_start = true

    s = Test::Redis.new
    refute_nil s.pid
    c = Redis.new :path => s.conf["unixsocket"]
    assert_equal "PONG", c.ping
    s.stop

    Test::Redis.auto_start = prev
  end

  def test_change_conf
    s = Test::Redis.new :conf => { "unknown_key" => "unknown_value" }
    e = assert_raises(RuntimeError) { s.start }
    assert_match "FATAL CONFIG FILE ERROR", e.message
  end

  attr_reader :server
end
