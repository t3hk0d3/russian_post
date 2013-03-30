
class RussianPost::Captcha::Pattern

  TARGET_MATCH_RATE = 1.0

  attr_reader :points, :character

  def initialize(points, character)
    @points, @character = points, character
  end

  def match?(image, x, y)
    matching = 0

    points.each do |px, py|
      cx, cy = x + px, y + py

      break if cx >= image.width || cy >= image.height || image[cx, cy] == 255

      matching += 1
    end

    matching / points.size >= TARGET_MATCH_RATE
  end

end
