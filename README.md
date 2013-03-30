# Russian Post Tools

## Installation

Add this line to your application's Gemfile:

    gem 'russian_post'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install russian_post

## Usage

### Captcha recognizer

```ruby
require 'russian_post'

 RussianPost::Captcha.for_url('http://www.russianpost.ru/CaptchaService/CaptchaImage.ashx?Id=361256433').text
 => 96950
```