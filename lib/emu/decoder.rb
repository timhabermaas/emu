module Emu
  class DecodeError < StandardError
  end

  class Decoder
    def initialize(&block)
      @f = block
    end

    def run(value)
      @f.call(value)
    end

    def run!(value)
      result = run(value)
      if result.error?
        raise DecodeError, result.unwrap_err
      else
        result.unwrap
      end
    end

    def fmap
      Decoder.new do |input|
        result = run(input)
        if result.error?
          result
        else
          Ok.new(yield result.unwrap)
        end
      end
    end

    def then
      Decoder.new do |input|
        run(input).then do |result|
          (yield result).run(input)
        end
      end
    end

    def |(decoder)
      Decoder.new do |input|
        result = run(input)
        if result.error?
          decoder.run(input)
        else
          result
        end
      end
    end

    def >(value)
      fmap { |_| value }
    end
  end
end
