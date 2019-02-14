# Emu
[![Build Status](https://travis-ci.org/timhabermaas/emu.svg?branch=master)](https://travis-ci.org/timhabermaas/emu)

Emu is a composable decoder/type coercion library. It can be used to transform Rails' `params` or the result of `JSON.parse` to objects your business logic understands.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'emu'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install emu

## Usage

Here's an example converting a `Hash` with some wind speed and direction data into a single vector describing both
parameters at once.

```ruby
require 'emu'

direction =
  (Emu.match('N') > [0, -1]) |
  (Emu.match('E') > [-1, 0]) |
  (Emu.match('S') > [0, 1]) |
  (Emu.match('W') > [1, 0])

speed = Emu.str_to_float

wind = Emu.map_n(
  Emu.from_key(:direction, direction),
  Emu.from_key(:speed, speed)) do |(x, y), speed|
    [x * speed, y * speed]
end

params = {
  direction: "W",
  speed: "4.5"
}
wind.run!(params) # => [4.5, 0.0]
```

This small example highlights almost all the features of `Emu`, hence there's a lot going on. So, let's break it down:

_For a quick overview of the most common use cases, skip to [TODO](#foo)._

All methods defined on the module `Emu` return a `Emu::Decoder`. A `Emu::Decoder` is a glorified lambda which can be run at a later time using `run!`. A decoder can either succeed or fail with a `Emu::DecodeError` exception:

```ruby
decoder = Emu.str_to_int # a decoder converting strings to integers
decoder.run!("42") # => 42
decoder.run!("foo") # => raise DecodeError, '`"foo"` is not an Integer'
```

The individual decoders defined on `Emu` can be split into two parts:

* Basic decoders, e.g. `str_to_int` which takes a String and tries to convert it into an Integer and
* Higher order decoders which take other decoders and wrap/manipulate them.


### Basic decoders

#### Primitive types (no type conversion)

* `string`
* `integer`
* `float`
* `boolean`
* `raw`

### Higher order decoders

Just like "higher order functions" describe functions which take other functions as input "higher order decoders" describe decoders which take other decoders as input.

* `fmap`
* ...


## Common Use-Cases

### Mapping

### dependent decoding (bind/then)

### Decoding Recursive Structures

When decoding recursive structures we quickly run into the issue of endless recursion:

```ruby
{
  name: 'Elvis Presley',
  parent: {
    name: 'R2D2',
    parent: {
      name: 'Barack Obama'
      parent: nil
    }
  }
}

# person will be nil on the right-hand side => runtime error
person =
  Emu.map_n(
    Emu.from_key(:name, Emu.string),
    Emu.from_key(:parent, Emu.nil | person)) do |name, parent|
      Person.new(name, parent)
  end

# person calls itself => infinite recursion
def person
  Emu.map_n(
    Emu.from_key(:name, Emu.string),
    Emu.from_key(:parent, Emu.nil | person)) do |name, parent|
      Person.new(name, parent)
  end
end
```

This can be solved by wrapping the recursive call in `lazy`:

```ruby
person =
  Emu.map_n(
    Emu.from_key(:name, Emu.string),
    Emu.from_key(:parent, Emu.nil | Emu.lazy { person })) do |name, parent|
      Person.new(name, parent)
  end
```

`lazy` takes a block which is only evaluated once you call `run` on the decoder. This avoids funky behavior when defining recursive decoders.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/emu.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
