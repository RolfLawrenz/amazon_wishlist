class Book

  attr_accessor :title, :url, :author, :prime, :amazon_price, :used_price, :in_stock, :rating, :image_url, :img_width, :img_height

  USED_PRICE_SHIPPING_COST = 3.99

  def initialize(title, url, author, prime, amazon_price, used_price, in_stock, rating, image_url, img_width, img_height)
    @title = title
    @url = url
    @author = author
    @prime = prime
    @amazon_price = amazon_price
    @used_price = used_price
    @in_stock = in_stock
    @rating = rating
    @image_url = image_url
    @img_width = img_width
    @img_height = img_height
  end

  def best_price_with_shipping
    used = used_price
    amazon = amazon_price

    used = 9999 if used.nil? || used == 0.0
    amazon = 9999 if amazon.nil? || amazon == 0.0

    used += USED_PRICE_SHIPPING_COST
    amazon += USED_PRICE_SHIPPING_COST unless prime

    price = used < amazon ? used : amazon
    (price * 100).round / 100.0
  end

  def format_price(price)
    price.nil? ? "" : format("%.2f", price)
  end

  def format_amazon_price
    format_price(amazon_price)
  end

  def format_used_price
    format_price(used_price)
  end

  def format_best_price
    format_price(best_price_with_shipping)
  end

end
