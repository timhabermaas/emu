require "test_helper"

describe Emu do
  describe ".raw" do
    it "always returns the input" do
      assert_equal "foo", Emu.raw.run!("foo")
    end
  end

  describe ".nil" do
    it "accepts nil" do
      assert_equal nil, Emu.nil.run!(nil)
    end

    it "rejects anything else" do
      assert Emu.nil.run("foo").error?
    end
  end

  describe ".str_to_int" do
    before do
      @decoder = Emu.str_to_int
    end

    describe "not a string" do
      [nil, 2, {}, [], true].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "not valid integer" do
      ["a", "", "-", "123a", "a1"].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "valid integer" do
      [["0", 0], ["-1", -1], ["-3", -3], ["1234", 1234], ["421", 421]].each do |(input, output)|
        it "returns #{output.inspect} for #{input.inspect}" do
          assert_equal output, @decoder.run!(input)
        end
      end
    end
  end

  describe ".str_to_float" do
    before do
      @decoder = Emu.str_to_float
    end

    describe "not a string" do
      [nil, 2, {}, [], true].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "not a valid float" do
      ["a", "", "-", "123a", "a1"].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "valid float" do
      [["0", 0.0], ["-1.2", -1.2], ["-3.4", -3.4], ["1234.14", 1234.14], ["0.421", 0.421]].each do |(input, output)|
        it "returns #{output.inspect} for #{input.inspect}" do
          assert_equal output.class, Float
          assert_equal output, @decoder.run!(input)
        end
      end
    end
  end

  describe ".integer" do
    before do
      @decoder = Emu.integer
    end

    describe "given not an integer" do
      [nil, "2", {}, [], true].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "given integer" do
      it "returns the passed in integer" do
        assert_equal 3, @decoder.run!(3)
      end
    end
  end

  describe ".float" do
    before do
      @decoder = Emu.float
    end

    describe "given not a float" do
      [nil, "2", {}, [], true].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "given integer" do
      it "accepts the input and transforms it to a float" do
        assert_equal 3.0, @decoder.run!(3)
        assert_equal Float, @decoder.run!(3).class
      end
    end

    describe "given float" do
      it "returns the passed in float" do
        assert_equal 3.5, @decoder.run!(3.5)
      end
    end
  end

  describe ".boolean" do
    before do
      @decoder = Emu.boolean
    end

    describe "given not a boolean" do
      [nil, "2", {}, [], 2].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "given boolean" do
      it "returns the passed in boolean" do
        assert_equal true, @decoder.run!(true)
        assert_equal false, @decoder.run!(false)
      end
    end
  end

  describe ".str_to_bool" do
    before do
      @decoder = Emu.str_to_bool
    end

    describe "not a string" do
      [nil, 2, {}, [], true].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "not valid boolean" do
      ["a", "tru", "-", "123a", "a1", ""].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "valid boolean" do
      [["true", true], ["false", false], ["0", false], ["1", true]].each do |(input, output)|
        it "returns #{output.inspect} for #{input.inspect}" do
          assert_equal output, @decoder.run!(input)
        end
      end
    end
  end

  describe ".string" do
    before do
      @decoder = Emu.string
    end

    describe "given not a String" do
      [nil, 2, {}, [], true].each do |input|
        it "returns an error for #{input.inspect}" do
          assert @decoder.run(input).error?
        end
      end
    end

    describe "given String" do
      it "returns the passed in String" do
        assert_equal "", @decoder.run!("")
        assert_equal "a", @decoder.run!("a")
      end
    end
  end

  describe ".succeed" do
    it "always succeeds" do
      assert_equal 12, Emu.succeed(12).run!("foo")
    end
  end

  describe ".fail" do
    it "always fails" do
      assert Emu.fail("message").run("foo").error?
    end
  end

  describe ".match" do
    before do
      @decoder = Emu.match("matchMe")
    end

    it "returns the input if it matches do match" do
      assert_equal "matchMe", @decoder.run!("matchMe")
    end

    it "returns an error if input doesn't match" do
      assert @decoder.run("matchMe ").error?
    end
  end

  describe ".from_key" do
    before :each do
      @decoder = Emu.from_key(:a, Emu.str_to_int)
    end

    it "returns an error if the key is missing" do
      assert @decoder.run({b: "foo"}).error?
    end

    it "returns an error if the inner decoder fails" do
      assert @decoder.run({a: "foo"}).error?
    end

    it "returns the decoded value if the value exists and it can be decoded" do
      assert_equal 42, @decoder.run!({a: "42"})
    end
  end

  describe ".array" do
    before :each do
      @decoder = Emu.array(Emu.str_to_int)
    end

    it "returns an error if not an array is passed in" do
      assert @decoder.run("a").error?
    end

    it "returns an error if the inner decoder fails" do
      assert @decoder.run(["foo"]).error?
    end

    it "returns an array of decoded values if all values are decodeable" do
      assert_equal [42, 43], @decoder.run!(["42", "43"])
    end
  end

  describe ".at_index" do
    before :each do
      @decoder = Emu.at_index(1, Emu.str_to_int)
    end

    it "returns an error if the index is missing" do
      assert @decoder.run(["2"]).error?
    end

    it "returns an error if the inner decoder fails" do
      assert @decoder.run(["2", 3]).error?
    end

    it "returns the decoded value if the value exists and it can be decoded" do
      assert_equal 42, @decoder.run!(["2", "42"])
    end
  end

  describe ".map_n" do
    describe "two arguments" do
      before :each do
        @decoder = Emu.map_n(Emu.from_key(:a, Emu.str_to_int), Emu.from_key(:b, Emu.str_to_int)) do |int, str|
          [int, str]
        end
      end

      it "returns an error if one of the decoders fails" do
        assert @decoder.run({a: "a", b: "42"}).error?
        assert @decoder.run({a: "24", b: "b"}).error?
        assert @decoder.run({a: "24"}).error?
        assert @decoder.run({b: "42"}).error?
      end

      it "works" do
        assert_equal [24, 42], @decoder.run!({a: "24", b: "42"})
      end
    end
  end

  describe ".lazy" do
    before do
      @decoder =
       Emu.map_n(
         Emu.from_key(:name, Emu.string),
         Emu.from_key(:parent, Emu.match(nil) | Emu.lazy { @decoder })) do |name, parent|
           [name, parent]
       end
    end

    it "works" do
      input = {
        name: 'foo',
        parent: {
          name: 'bar',
          parent: nil
        }
      }
      @decoder.run!(input)
    end
  end

  describe "#fmap" do
    before :each do
      @decoder = Emu.str_to_int.fmap(&:succ)
    end

    describe "with a failed decode" do
      it "returns the error" do
        assert @decoder.run("a").error?
      end
    end

    describe "with a successful decode" do
      it "applies the block to the returned value" do
        assert_equal 43, @decoder.run!("42")
      end
    end
  end

  describe "#>" do
    before :each do
      @decoder = Emu.match("true") > true
    end

    describe "with a failed decode" do
      it "returns an error" do
        assert @decoder.run("false").error?
      end
    end

    describe "with a successful decode" do
      it "returns the constant" do
        assert_equal true, @decoder.run!("true")
      end
    end
  end

  describe "#then" do
    before :each do
      @decoder = Emu.from_key(:foo, Emu.str_to_int).then do |x|
        if x > 0
          Emu.from_key(:bar, Emu.raw)
        else
          Emu.from_key(:bar, Emu.str_to_int)
        end
      end
    end

    describe "with a failed decode" do
      it "returns an error" do
        assert @decoder.run({foo: "a"}).error?
        assert @decoder.run({foo: "12"}).error?
        assert @decoder.run({foo: "0", bar: "a"}).error?
      end
    end

    describe "with a successful decode" do
      it "returns the decoded value" do
        assert_equal 2, @decoder.run!({foo: "0", bar: "2"})
        assert_equal "string", @decoder.run!({foo: "1", bar: "string"})
      end
    end
  end

  describe "#|" do
    before :each do
      @decoder = Emu.match("42") | Emu.str_to_int | Emu.match("bar")
    end

    describe "with a failed decode" do
      it "returns an error" do
        assert @decoder.run("nope").error?
        assert @decoder.run(43).error?
      end
    end

    describe "with a successful decode" do
      it "returns the decoded value" do
        assert_equal "42", @decoder.run!("42")
        assert_equal 12, @decoder.run!("12")
        assert_equal "bar", @decoder.run!("bar")
      end
    end
  end
end
