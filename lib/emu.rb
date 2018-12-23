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

  # Creates a decoder which converts a string to an integer. It uses ++Integer++
  # for the conversion.
  #
  # @example
  #   Emu.str_to_int.run!("42") # => 42
  #   Emu.str_to_int.run!("a") # => raise DecodeError, "`\"a\"` can't be converted to an Integer"
  #   Emu.str_to_int.run!(42) # => raise DecodeError, "`42` is not a String"
  def self.str_to_int
    Decoder.new do |s|
      next Err.new("`#{s.inspect}` is not a String") unless s.is_a?(String)

      begin
        Ok.new(Integer(s))
      rescue TypeError, ArgumentError
        Err.new("`#{s.inspect}` can't be converted to an Integer")
      end
    end
  end

  # Creates a decoder which only accepts integers.
  #
  # @example
  #   Emu.integers.run!(2) # => 2
  #   Emu.integers.run!("2") # => raise DecodeError, '`"2"` is not an Integer'
  # @return [Emu::Decoder<Integer>]
  def self.integer
    Decoder.new do |i|
      next Err.new("`#{i.inspect}` is not an Integer") unless i.is_a?(Integer)

      Ok.new(i)
    end
  end

  # Creates a decoder which only accepts booleans.
  #
  # @example
  #   Emu.boolean.run!(true) # => true
  #   Emu.boolean.run!(false) # => false
  #   Emu.boolean.run!(nil) # => raise DecodeError, "`nil` is not a Boolean"
  #   Emu.boolean.run!(2) # => raise DecodeError, "`2` is not a Boolean"
  # @return [Emu::Decoder<TrueClass|FalseClass>]
  def self.boolean
    Decoder.new do |b|
      next Err.new("`#{b.inspect}` is not a Boolean") unless b.is_a?(TrueClass) || b.is_a?(FalseClass)

      Ok.new(b)
    end
  end

  # Creates a decoder which converts a string to a boolean (++true++, ++false++) value.
  #
  # "0" and "false" is considered ++false++, "1" and "true" is considered ++true++.
  # Decoding every other value will fail.
  #
  # @example
  #   Emu.str_to_bool.run!("true") # => true
  #   Emu.str_to_bool.run!("1") # => true
  #   Emu.str_to_bool.run!("false") # => false
  #   Emu.str_to_bool.run!("0") # => false
  #   Emu.str_to_bool.run!(true) # => raise DecodeError, "`true` is not a String"
  #   Emu.str_to_bool.run!("2") # => raise DecodeError, "`\"2\"` can't be converted to a Boolean"
  #
  # @return [Emu::Decoder<TrueClass|FalseClass>]
  def self.str_to_bool
    Decoder.new do |s|
      next Err.new("`#{s.inspect}` is not a String") unless s.is_a?(String)

      if s == "true" || s == "1"
        Ok.new(true)
      elsif s == "false" || s == "0"
        Ok.new(false)
      else
        Err.new("`#{s.inspect}` can't be converted to a Boolean")
      end
    end
  end

  # Creates a decoder which always succeeds and yields the input.
  #
  # This might be useful if you want to do defer type conversion to
  # a later time.
  #
  # @example
  #   Emu.raw.run!(true) # => true
  #   Emu.raw.run!("2") # => "2"
  def self.raw
    Decoder.new do |s|
      Ok.new(s)
    end
  end

  # Creates a decoder which always succeeds with the provided value.
  #
  # @example
  #   Emu.succeed("foo").run!(42) # => "foo"
  # @param value [a] the value the decoder evaluates to
  # @return [Emu::Decoder<a>]
  def self.succeed(value)
    Decoder.new do |_|
      Ok.new(value)
    end
  end

  # Creates a decoder which always fails with the provided message.
  #
  # @example
  #   Emu.fail("foo").run!(42) # => raise DecodeError, "foo"
  # @param message [String] the error message the decoder evaluates to
  # @return [Emu::Decoder<Void>]
  def self.fail(message)
    Decoder.new do |_|
      Err.new(message)
    end
  end

  # Returns a decoder which succeeds if the input value matches ++constant++.
  # If the decoder succeeds it resolves to the input value.
  # #== is used for comparision, no type checks are performed.
  #
  # @example
  #   Emu.match(42).run!(42) # => 42
  #   Emu.match(42).run!(41) # => raise DecodeError, "Input `41` doesn't match expected value `42`"
  # @param constant [a] the value to match against
  # @return [Emu::Decoder<a>]
  def self.match(constant)
    Decoder.new do |s|
      s == constant ? Ok.new(s) : Err.new("Input `#{s.inspect}` doesn't match expected value `#{constant.inspect}`")
    end
  end

  # Creates a decoder which extracts the value of a hash map according to the given key.
  #
  # @example
  #   Emu.from_key(:a, Emu.str_to_int).run!({a: "42"}) # => 42
  #   Emu.from_key(:a, Emu.str_to_int).run!({a: "a"}) # => raise DecodeError, '`"a"` can't be converted to an integer'
  #   Emu.from_key(:a, Emu.str_to_int).run!({b: "42"}) # => raise DecodeError, '`{:b=>"42"}` doesn't contain key `:a`'
  #
  # @param key [a] the key of the hash map
  # @param decoder [Emu::Decoder<b>] the decoder to apply to the value at key ++key++
  # @return [Emu::Decoder<b>]
  def self.from_key(key, decoder)
    Decoder.new do |hash|
      next Err.new("`#{hash.inspect}` doesn't contain key `#{key.inspect}`") unless hash.has_key?(key)

      decoder.run(hash.fetch(key))
    end
  end

  # Builds a decoder out of ++n++ decoders and maps a function over the result
  # of the passed in decoders. For the block to be called all decoders must succeed.
  #
  # @example
  #   d = Emu.map_n(Emu.string, Emu.str_to_int) do |string, integer|
  #     string * integer
  #   end
  #
  #   d.run!("3") # => "333"
  #   d.run!("a") # => raise DecodeError, '`"a"` can't be converted to an integer'
  #
  # @param decoders [Array<Decoder>] the decoders to map over
  # @yield [a, b, c, ...] Passes the result of all decoders to the block
  # @yieldreturn [z] the value the decoder should evaluate to
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
