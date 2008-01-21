
HERE = File.dirname(__FILE__)
$LOAD_PATH << "#{HERE}/../../lib/"

require 'memcached'
require 'ostruct'
require 'benchmark'
require 'rubygems'
require 'memcache'

# We'll use a simple @value to try to avoid spending time in Marshal, 
# which is a constant penalty that both clients have to pay
@value = []
@marshalled = Marshal.dump(@value)

@opts = [
  ['127.0.0.1:43042', '127.0.0.1:43043'], 
  {
    :buffer_requests => true,
    :no_block => true,
    :namespace => "benchmark_namespace"
  }
]
@key1 = "Short" 
@key2 = "Sym1-2-3::45"*8
@key3 = "Long"*40
@key4 = "Medium"*8

def restart_servers
  system("ruby #{HERE}/../setup.rb")
  sleep(1)
end


Benchmark.bm(31) do |x|
  restart_servers

  n = 1000  
  
  @m = Memcached.new(*@opts)
  x.report("set:plain:memcached") do
    n.times do
      @m.set @key1, @marshalled, 0, false
      @m.set @key2, @marshalled, 0, false
      @m.set @key3, @marshalled, 0, false
      @m.set @key1, @marshalled, 0, false
      @m.set @key2, @marshalled, 0, false
      @m.set @key3, @marshalled, 0, false
    end
  end
  @m = Memcached.new(
    @opts[0], 
    @opts[1].merge(:no_block => false, :buffer_requests => false)
  )
  x.report("set:plain:unbuffered:memcached") do
    n.times do
      @m.set @key1, @marshalled, 0, false
      @m.set @key2, @marshalled, 0, false
      @m.set @key3, @marshalled, 0, false
      @m.set @key1, @marshalled, 0, false
      @m.set @key2, @marshalled, 0, false
      @m.set @key3, @marshalled, 0, false
    end
  end
  @m = MemCache.new(*@opts)
  x.report("set:plain:memcache-client") do
    n.times do
      @m.set @key1, @marshalled, 0, true
      @m.set @key2, @marshalled, 0, true
      @m.set @key3, @marshalled, 0, true
      @m.set @key1, @marshalled, 0, true
      @m.set @key2, @marshalled, 0, true
      @m.set @key3, @marshalled, 0, true
    end
  end
  
  restart_servers 

  @m = Memcached.new(*@opts)
  x.report("set:ruby:memcached") do
    n.times do
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
    end
  end
  @m = Memcached.new(
    @opts[0], 
    @opts[1].merge(:no_block => false, :buffer_requests => false)
  )
  x.report("set:ruby:unbuffered:memcached") do
    n.times do
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
    end
  end
  @m = MemCache.new(*@opts)
  x.report("set:ruby:memcache-client") do
    n.times do
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
    end
  end

  @m = Memcached.new(*@opts)
  x.report("get:plain:memcached") do
    n.times do
      @m.get @key1, false
      @m.get @key2, false
      @m.get @key3, false
      @m.get @key1, false
      @m.get @key2, false
      @m.get @key3, false
    end
  end
  @m = MemCache.new(*@opts)
  x.report("get:plain:memcache-client") do
    n.times do
      @m.get @key1, true
      @m.get @key2, true
      @m.get @key3, true
      @m.get @key1, true
      @m.get @key2, true
      @m.get @key3, true
    end
  end

  @m = Memcached.new(*@opts)
  x.report("get:ruby:memcached") do
    n.times do
      @m.get @key1
      @m.get @key2
      @m.get @key3
      @m.get @key1
      @m.get @key2
      @m.get @key3
    end
  end
  @m = MemCache.new(*@opts)
  x.report("get:ruby:memcache-client") do
    n.times do
      @m.get @key1
      @m.get @key2
      @m.get @key3
      @m.get @key1
      @m.get @key2
      @m.get @key3
    end
  end

  restart_servers

  @m = Memcached.new(*@opts)
  x.report("missing:ruby:memcached") do
    n.times do
      begin @m.delete @key1; rescue Memcached::NotFound; end
      begin @m.get @key1; rescue Memcached::NotFound; end
      begin @m.delete @key2; rescue Memcached::NotFound; end
      begin @m.get @key2; rescue Memcached::NotFound; end
      begin @m.delete @key3; rescue Memcached::NotFound; end
      begin @m.get @key3; rescue Memcached::NotFound; end
    end
  end
  @m = MemCache.new(*@opts)
  x.report("missing:ruby:memcache-client") do
    n.times do
      begin @m.delete @key1; rescue; end
      begin @m.get @key1; rescue; end
      begin @m.delete @key2; rescue; end
      begin @m.get @key2; rescue; end
      begin @m.delete @key3; rescue; end
      begin @m.get @key3; rescue; end
    end
  end

  restart_servers

  @m = Memcached.new(*@opts)
  x.report("mixed:ruby:memcached") do
    n.times do
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
      @m.get @key1
      @m.get @key2
      @m.get @key3
      @m.set @key1, @value
      @m.get @key1
      @m.set @key2, @value
      @m.get @key2
      @m.set @key3, @value
      @m.get @key3
    end
  end
  @m = MemCache.new(*@opts)
  x.report("mixed:ruby:memcache-client") do
    n.times do
      @m.set @key1, @value
      @m.set @key2, @value
      @m.set @key3, @value
      @m.get @key1
      @m.get @key2
      @m.get @key3
      @m.set @key1, @value
      @m.get @key1
      @m.set @key2, @value
      @m.get @key2
      @m.set @key3, @value
      @m.get @key3
    end
  end

  restart_servers
    
  n = 10000
  Memcached::HASH_VALUES.each do |mode,|
    @m = Memcached.new(@opts[0], @opts[1].merge(:hash => mode))
    x.report("hash:#{mode}:memcached") do
      n.times do
        @m.set @key1, @marshalled, 0, true
        @m.get @key1, true
        @m.set @key2, @marshalled, 0, true
        @m.get @key2, true
        @m.set @key3, @marshalled, 0, true
        @m.get @key3, true
      end
    end
  end
end