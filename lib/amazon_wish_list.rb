require 'watir'
require 'highline/import'
require 'andand'
require 'byebug'
require 'nokogiri'
require './lib/book'

class AmazonWishList

  # Links
  LOGIN_PAGE = "https://www.amazon.com/ap/signin?_encoding=UTF8&openid.assoc_handle=usflex&openid.claimed_id=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.identity=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0%2Fidentifier_select&openid.mode=checkid_setup&openid.ns=http%3A%2F%2Fspecs.openid.net%2Fauth%2F2.0&openid.ns.pape=http%3A%2F%2Fspecs.openid.net%2Fextensions%2Fpape%2F1.0&openid.pape.max_auth_age=0&openid.return_to=https%3A%2F%2Fwww.amazon.com%2Fgp%2Fyourstore%2Fhome%3Fie%3DUTF8%26ref_%3Dnav_custrec_signin"
  WISH_LIST_PAGE = "http://www.amazon.com/gp/registry/wishlist/<wishlist_code>/ref=cm_wl_sortbar_o_page_"
  WISH_LIST_PAGE_SUFFIX = "?ie=UTF8&page="

  def choose_cheapest_book
    scan_wish_list
    create_html_book_reports
    puts "Done. See reports in project base folder for results."
  end

  private

  def config
    @config ||= YAML.load_file('config.yml')
  end

  def scan_wish_list
    @username = config["username"] || username
    @password = config["password"] || password
    @wishlist_code = config["wishlist_code"] || wishlist_code

    @book_titles = []

    @books = []
    puts "Scanning Wish List"
    with_amazon do |browser|
      # We dont know how many pages until we open first wish list page
      goto_wishlist(browser, 1)
      @books += read_books(browser)

      if @page_count > 1
        (2..@page_count).each do |page|
          goto_wishlist(browser, page)
          @books += read_books(browser)
        end
      end
    end

  end

  def username
    ask("Enter Amazon username: ")
  end

  def password
    ask("Enter Amazon password: ") { |q| q.echo = false }
  end

  def wishlist_code
    ask("Enter Amazon wishlist code (found on wishlist url): ")
  end

  def with_amazon(&block)
    browser = Watir::Browser.new :firefox
    login(browser)
    yield(browser)
  ensure
    logout(browser)
    browser.quit
  end

  def login(browser)
    puts "Login to Amazon"
    browser.goto LOGIN_PAGE
    usernm = browser.text_field(:id, "ap_email")
    usernm.set(@username)
    pwd = browser.text_field(:id, "ap_password")
    pwd.set(@password)
    f = browser.form(:name , "signIn")
    f.submit
  end

  def logout(browser)
    puts "Logging out"

  end

  def goto_wishlist(browser, page)
    puts "Goto Wishlist Page #{page}"
    url = "#{WISH_LIST_PAGE.gsub('<wishlist_code>',@wishlist_code)}#{page}"
    url += "#{WISH_LIST_PAGE_SUFFIX}#{page}" if page > 1
    browser.goto url

    # Count number of pages
    if page == 1
      @page_count = wishlist_page_count(browser)
      puts "There are #{@page_count} wish list pages"
    end
  end

  def read_books(browser)
    html = browser.html

    page = Nokogiri::HTML(html)

    books = []
    # Finding <h5> tags - easier
    book_info_collection = page.css("h5")
    book_info_collection.each do |book_info|
      link = book_info.css("a").select{|link| link["class"] == "a-link-normal a-declarative"}[0]
      next unless link

      #title
      title = link.text.strip

      # Author
      url = "http://www.amazon.com/#{link["href"]}"
      parent = book_info.parent
      author = parent.text.partition("by ").andand[2].strip

      # Rating
      bpp = book_info.parent.parent
      div2 = bpp.css("div")[1]
      rating = div2.css("i").andand[0].andand["class"] ? div2.css("i")[0]["class"].split[-1].gsub("a-star-","") : nil

      # Amazon Price and Prime
      div3 = bpp.css("div")[2]
      amazon_price = div3.css("div")[0].css("span")[0].text.strip.gsub("$","").to_f
      prime = div3.css("div")[0].css("i")[0] ? div3.css("div")[0].css("i")[0]["class"].include?("prime") : false

      # If there is a 'Price dropped' message, use next div
      # Used Price in Stock
      di = 2
      div_in_stock = nil
      div_used = nil
      # Some do not have a rating and prime row, just a used
      if div2.text.downcase.include?("used")
        div_in_stock = nil
        div_used = div2.css("div")[3]
      else
        if div3.css("div").size > 2
          if div3.css("div")[2].css("span").text.downcase.include?("dropped")
            di += 1
          end
          div_in_stock = div3.css("div")[di]
          div_used = div3.css("div")[di+1]
        end
      end

      if div_used
        used_price = div_used.css("span").empty? ? nil : div_used.css("span").text.gsub("$","").to_f
      else
        used_price = nil
      end

      if div_in_stock
        in_stock = div_in_stock.css("span").text.downcase.include?("in stock")
      else
        in_stock = nil
      end

      # Image
      image_elem = bpp.parent.parent.parent.parent.parent.parent.css("div")[2].css("div")[2].css("img")[0]
      image_url = image_elem["src"]
      img_width = image_elem["width"]
      img_height = image_elem["height"]

      book = Book.new(title, url, author, prime, amazon_price, used_price, in_stock, rating, image_url, img_width, img_height)
      puts "##{@books.count + books.count + 1} #{book.title}"
      if @book_titles.include?(book.title)
        puts "*** Duplicate"
      else
        books << book
        @book_titles << book.title
      end
    end
    books
  end

  def wishlist_page_count(browser)
    div1 = browser.div(id: "wishlistPagination")
    div1.lis[-2].attribute_value("data-pag-trigger").partition(':')[2].gsub("}",'').to_i
  end

  def create_html_book_reports
    # Sort books alphabetical
    @books.sort! { |a,b| a.title.downcase <=> b.title.downcase }
    create_html_book_report("Alphabetical")

    # Sort books by price
    @books.sort! do |a,b|
      # Best price
      if a.best_price_with_shipping == b.best_price_with_shipping
        # Alphabetical
        a.title.downcase <=> b.title.downcase
      else
        a.best_price_with_shipping <=> b.best_price_with_shipping
      end
    end
    create_html_book_report("Price")
  end

  def create_html_book_report(title)
    puts "Creating #{title} book report"
    @title = "Wish List sorted by #{title}"

    template = ERB.new File.new("reports/books_collection.html.erb").read, nil, "%"
    html = template.result(binding)
    File.open("WishList_#{title}.html", 'w') do |file|
      file.write(html)
    end
  end

end
