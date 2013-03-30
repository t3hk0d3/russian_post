require 'russian_post/captcha/pattern'

class RussianPost::Captcha::Patterns
  attr_reader :patterns

  class << self

    def built_in
      @builtin_patterns ||= RussianPost::Captcha::Patterns.new(File.expand_path('characters.dat', File.dirname(__FILE__)))
    end

  end

  def initialize(file)
    @patterns = load_patterns(file)
  end

  def each(&block)
    @patterns.each(&block)
  end

  def add(pattern)
    @patterns << pattern
  end

  def find(image, x, y)
    each do |pattern|
      return pattern if pattern.match?(image, x, y)
    end

    return false
  end

  private 

  def serialize(patterns)
    array_hash = Hash.new{ |hash, key| hash[key] = []}

    data = patterns.inject(array_hash) do |result, pattern|
      result[pattern.character] << pattern.points
      result
    end

    Marshal.dump(data)
  end

  def deserialize(data)
    raw_data = Marshal.load(data)

    raw_data.inject([]) do |result, data|
      character, patterns = data

      result += patterns.map { |points| RussianPost::Captcha::Pattern.new(points, character) }
    end
  end

  def save_patterns(file, patterns)
    File.open(file, 'wb') { |file| file.write(serialize(patterns)) }
  end

  def load_patterns(file)
    raise "Specified patterns file not exists (#{file})" unless File.exists?(file)

    deserialize(File.open(file, 'rb') { |file| file.read })
  end

end
