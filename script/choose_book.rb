#!/usr/bin/env ruby

# Will go through Amazon wish list and choose the cheapest/best book next

require 'rubygems'
require 'trollop'
require './lib/amazon_wish_list'

@opts = Trollop.options do
  banner "Choose next cheapest book from Amazon Wish List"
end

amazon = AmazonWishList.new
amazon.choose_cheapest_book
