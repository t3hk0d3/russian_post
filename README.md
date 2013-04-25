# Russian Post Tools

## Installation

Add this line to your application's Gemfile:

    gem 'russian_post'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install russian_post

## Usage

### Postal tracking

```ruby
require 'russian_post'

RussianPost::Tracking.new(tracking_code).track
# => [{...}, {...}, {...}]
```

### Captcha recognizer

```ruby
require 'russian_post'

RussianPost::Captcha.for_url(captcha_url).text
# => 96950

RussianPost::Captcha.for_data(png_blob).text
# => 43455
```