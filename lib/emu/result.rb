module Emu
  class Err
    def initialize(error)
      @error = error
    end

    def to_s
      "Err(#{@error})"
    end

    def then
      self
    end

    def unwrap
      raise "can't unwrap Err(#{@error.inspect})"
    end

    def unwrap_err
      @error
    end

    def error?
      true
    end
  end

  class Ok
    def initialize(value)
      @value = value
    end

    def to_s
      "Ok(#{@value})"
    end

    def then
      yield @value
    end

    def unwrap
      @value
    end

    def unwrap_err
      raise "can't unwrap_err Ok(#{@value.inspect})"
    end

    def error?
      false
    end
  end
end
