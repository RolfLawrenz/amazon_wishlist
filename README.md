# Amazon Wishlist
Reads your amazon wishlist and generates a html file of all your items ordered by price and alphabetical.
Goes through each page and scrapes all details.

You enter your username, password and wishlist code and the script will generate 2 reports:
  * HTML report sorted by Price
  * HTML report sorted by Alphabetical

## Configuration
Rather than enter your username, password or wishlist code each time you can enter those values in the **config.yml** file.

Wishlist code can be found on your wishlist url:

    http://www.amazon.com/gp/registry/wishlist/<wishlist_code>/ref=cm_wl_sortbar_o_page_

## Reports
Reports will contain:
  * Image
  * Title
  * Author
  * Prime
  * In Stock
  * Rating
  * Amazon Price
  * Used Price
  * Best Price

