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
  # @return [Emu::Decoder<Integer>]
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

  # Creates a decoder which converts a string to an float. It uses ++Float++
  # for the conversion.
  #
  # @example
  #   Emu.str_to_float.run!("42.2") # => 42.2
  #   Emu.str_to_float.run!("42") # => 42.0
  #   Emu.str_to_float.run!("a") # => raise DecodeError, "`\"a\"` can't be converted to a Float"
  #   Emu.str_to_float.run!(42) # => raise DecodeError, "`42` is not a String"
  # @return [Emu::Decoder<Float>]
  def self.str_to_float
    Decoder.new do |s|
      next Err.new("`#{s.inspect}` is not a String") unless s.is_a?(String)

      begin
        Ok.new(Float(s))
      rescue TypeError, ArgumentError
        Err.new("`#{s.inspect}` can't be converted to a Float")
      end
    end
  end

  # Creates a decoder which only accepts integers.
  #
  # @example
  #   Emu.integer.run!(2) # => 2
  #   Emu.integer.run!("2") # => raise DecodeError, '`"2"` is not an Integer'
  # @return [Emu::Decoder<Integer>]
  def self.integer
    Decoder.new do |i|
      next Err.new("`#{i.inspect}` is not an Integer") unless i.is_a?(Integer)

      Ok.new(i)
    end
  end

  # Creates a decoder which only accepts floats (including integers).
  # Integers are converted to floats because the result type should be uniform.
  #
  # @example
  #   Emu.float.run!(2) # => 2.0
  #   Emu.float.run!(2.1) # => 2.1
  #   Emu.float.run!("2") # => raise DecodeError, '`"2"` is not a Float'
  # @return [Emu::Decoder<Float>]
  def self.float
    Decoder.new do |i|
      next Err.new("`#{i.inspect}` is not a Float") unless i.is_a?(Float) || i.is_a?(Integer)

      Ok.new(i.to_f)
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

  # Creates a decoder which converts a string to a boolean (<tt>true</tt>, <tt>false</tt>) value.
  #
  # <tt>"0"</tt> and <tt>"false"</tt> are considered ++false++, <tt>"1"</tt> and <tt>"true"</tt> are considered ++true++.
  # Trying to decode any other value will fail.
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
  # This might be useful if you don't care about the exact shape of
  # of your data and don't have a need to inspect it (e.g. some binary
  # data).
  #
  # @example
  #   Emu.raw.run!(true) # => true
  #   Emu.raw.run!("2") # => "2"
  # @return [Emu::Decoder<a>]
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

  # Creates a decoder which only accepts `nil` values.
  #
  # @example
  #   Emu.nil.run!(nil) # => nil
  #   Emu.nil.run!(42) # => raise DecodeError, "`42` isn't `nil`"
  # @return [Emu::Decoder<NilClass>]
  def self.nil
    Decoder.new do |s|
      s.nil? ? Ok.new(s) : Err.new("`#{s.inspect}` isn't `nil`")
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
      next Err.new("`#{hash.inspect}` is not a Hash") unless hash.respond_to?(:has_key?) && hash.respond_to?(:fetch)
      next Err.new("`#{hash.inspect}` doesn't contain key `#{key.inspect}`") unless hash.has_key?(key)

      decoder.run(hash.fetch(key))
    end
  end

  # Creates a decoder which extracts the value of an array at the given index.
  #
  # @example
  #   Emu.at_index(0, Emu.str_to_int).run!(["42"]) # => 42
  #   Emu.at_index(0, Emu.str_to_int).run!(["a"]) # => raise DecodeError, '`"a"` can't be converted to an integer'
  #   Emu.at_index(1, Emu.str_to_int).run!(["42"]) # => raise DecodeError, '`["42"]` doesn't contain index `1`'
  #
  # @param index [Integer] the key of the hash map
  # @param decoder [Emu::Decoder<b>] the decoder to apply to the value at index ++index++
  # @return [Emu::Decoder<b>]
  def self.at_index(index, decoder)
    Decoder.new do |array|
      next Err.new("`#{array.inspect}` doesn't contain index `#{index.inspect}`") if index >= array.length

      decoder.run(array[index])
    end
  end

  # Creates a decoder which decodes the values of an array and returns the decoded array.
  #
  # @example
  #   Emu.array(Emu.str_to_int).run!(["42", "43"]) # => [42, 43]
  #   Emu.array(Emu.str_to_int).run!("42") # => raise DecodeError, "`"a"` is not an Array"
  #   Emu.array(Emu.str_to_int).run!(["a"]) # => raise DecodeError, '`"a"` can't be converted to an Integer'
  #
  # @param decoder [Emu::Decoder<b>] the decoder to apply to all values of the array
  # @return [Emu::Decoder<b>]
  def self.array(decoder)
    Decoder.new do |array|
      next Err.new("`#{array.inspect}` is not an Array") unless array.is_a?(Array)

      result = []

      i = 0
      error_found = nil
      while i < array.length && !error_found
        r = decoder.run(array[i])
        if r.error?
          error_found = r
        else
          result << r.unwrap
        end
        i += 1
      end

      if error_found
        error_found
      else
        Ok.new(result)
      end
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
  #   d.run!("a") # => raise DecodeError, '`"a"` can't be converted to an Integer'
  #
  # @param decoders [Array<Decoder>] the decoders to map over
  # @yield [a, b, c, ...] Passes the result of all decoders to the block
  # @yieldreturn [z] the value the decoder should evaluate to
  # @return [Emu::Decoder<a>]
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

  # Wraps a decoder +d+ in a lazily evaluated block to avoid endless recursion when
  # dealing with recursive data structures. <tt>Emu.lazy { d }.run!</tt> behaves exactly like
  # +d.run!+.
  #
  # @example
  #   person =
  #     Emu.map_n(
  #       Emu.from_key(:name, Emu.string),
  #       Emu.from_key(:parent, Emu.nil | Emu.lazy { person })) do |name, parent|
  #         Person.new(name, parent)
  #     end
  #
  #   person.run!({name: "foo", parent: { name: "bar", parent: nil }}) # => Person("foo", Person("bar", nil))
  #
  # @yieldreturn [Emu::Decoder<a>] the wrapped decoder
  # @return [Emu::Decoder<a>]
  def self.lazy
    Decoder.new do |input|
      inner_decoder = yield
      inner_decoder.run(input)
    end
  end
end
