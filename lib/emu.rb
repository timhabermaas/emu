require "emu/version"
require "emu/result"
require "emu/decoder"

module Emu

  # Creates a decoder which only accepts strings.
  #
  # @example
  #   Emu.string.run!("2") # => "2"
  #   Emu.string.run!(2) # => raise DecodeError, "`2` is not a String"
  # @return [Emu::Decoder<String>]
  def self.string
    Decoder.new do |s|
      next Err.new("`#{s.inspect}` is not a String") unless s.is_a?(String)

      Ok.new(s)
    end
  end

  def self.str_to_int
    Decoder.new do |s|
      next Err.new("`#{s.inspect}` is not a String") unless s.is_a?(String)

      begin
        Ok.new(Integer(s))
      rescue TypeError, ArgumentError
        Err.new("`#{s.inspect}` can't be converted to an integer")
      end
    end
  end

  def self.integer
    Decoder.new do |i|
      next Err.new("`#{i.inspect}` is not an Integer") unless i.is_a?(Integer)

      Ok.new(i)
    end
  end

  def self.boolean
    Decoder.new do |b|
      next Err.new("`#{b.inspect}` is not a Boolean") unless b.is_a?(TrueClass) || b.is_a?(FalseClass)

      Ok.new(b)
    end
  end

  def self.str_to_bool
    Decoder.new do |s|
      next Err.new("`#{s.inspect}` is not a String") unless s.is_a?(String)

      if s == "true" || s == "1"
        Ok.new(true)
      elsif s == "false" || s == "0"
        Ok.new(false)
      else
        Err.new("`#{s.inspect}` can not be converted to a Boolean")
      end
    end
  end

  def self.id
    Decoder.new do |s|
      Ok.new(s)
    end
  end

  def self.succeed(v)
    Decoder.new do |_|
      Ok.new(v)
    end
  end

  def self.fail(e)
    Decoder.new do |_|
      Err.new(e)
    end
  end

  # Returns a decoder which succeeds if the input value matches ++constant++.
  # #== is used for comparision, no type checks are performed.
  #
  # @example
  #   Emu.match(42).run!(42) # => 42
  #   Emu.match(42).run!(41) # => raise DecodeError, "`41` doesn't match `42`"
  # @param constant [Object] the value to match against
  # @return [Emu::Decoder<Object>]
  def self.match(constant)
    Decoder.new do |s|
      s == constant ? Ok.new(s) : Err.new("`#{s.inspect}` doesn't match `#{constant.inspect}`")
    end
  end

  def self.from_key(key, decoder)
    Decoder.new do |hash|
      next Err.new("'#{hash}' doesn't contain key '#{key}'") unless hash.has_key?(key)

      decoder.run(hash.fetch(key))
    end
  end

  def self.map_n(*decoders, &block)
    raise "decoder count must match argument count of provided block" unless decoders.size == block.arity

    Decoder.new do |input|
      results = decoders.map do |c|
        c.run(input)
      end

      first_error = results.find(&:error?)
      if first_error
        first_error
      else
        Ok.new(block.call(*results.map(&:unwrap)))
      end
    end
  end
end
