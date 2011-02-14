require 'date'
require 'net/https'
require 'nokogiri'

class Date
  def mo
    strftime('%m')
  end
  def yr
    strftime('%y')
  end
end

class GiftCard
  attr_reader :number, :exp, :cvv
  
  def initialize(number, exp, cvv)
    @number = number.gsub('-','')
    @exp = Date.strptime(exp,"%m/%y")
    @cvv = cvv
  end
  def number_with_dashes
    "#{number[0..3]}-#{number[4..7]}-#{number[8..11]}-#{number[12..15]}"
  end
  def masked_number
    "XXXX-XXXX-XXXX-#{number[12..15]}"
  end
  def balance_as_s
    "$#{"%0.2f" % balance}"
  end
  def http(domain)
    # Return a Net::HTTP object for a given domain
    return @http if @http
    @http = Net::HTTP.new(domain, 443)
    @http.use_ssl = true
    @http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    @http
  end
  def cookie
    # Return the cookie for the card site
    return @cookie if @cookie
    login_page
    @cookie
  end
  def login_page(path)
    # Return page data for the card 'login' page, specified by path
    return @login_page if @login_page
    resp, data = http.get(path, nil)
    @cookie = resp.response['set-cookie']
    @login_page = data
  end
end

class VanillaVisa < GiftCard
  def http
    super('www.vanillavisa.com')
  end
  def login_page
    super('/home.html?product=giftcard&csrfToken=')
  end
  def csrfToken
    Nokogiri::HTML(login_page).xpath('//input[@name="csrfToken"]/@value').first.content
  end
  def balance
    return @balance if @balance
    data = "velocityCheckFlag=true&csrfToken=#{csrfToken}&cardType=visa&cardNumber=#{number}&expiryMonth=#{exp.mo}&expiryYear=#{exp.yr}&creditCardID=#{cvv}&go="
    headers = {'Cookie' => cookie, 'Content-Type' => 'application/x-www-form-urlencoded'}
    resp, data = http.post('/accountHistory.html', data, headers)
    @balance = Nokogiri::HTML(data).xpath('//table[@class="reportTable"][1]/tr[1]/td[2]/text()').first.content.gsub(/\s/,'').gsub('AvailableBalance:','').gsub('$','').to_f
  end
end

class VanillaMasterCard < GiftCard
  def http
    super('www.vanillamastercard.com')
  end
  def login_page
    super('/home.html?locale=en_US&product=giftcard&csrfToken=')
  end
  def csrfToken
    Nokogiri::HTML(login_page).xpath('//input[@name="csrfToken"]/@value').first.content
  end
  def balance
    return @balance if @balance
    data = "velocityCheckFlag=true&csrfToken=#{csrfToken}&cardType=mastercard&cardNumber=#{number}&expiryMonth=#{exp.mo}&expiryYear=#{exp.yr}&creditCardID=#{cvv}&go="
    headers = {'Cookie' => cookie, 'Content-Type' => 'application/x-www-form-urlencoded'}
    resp, data = http.post('/accountHistory.html', data, headers)
    @balance = Nokogiri::HTML(data).xpath('//table[@class="reportTable"][1]/tr[1]/td[2]/text()').first.content.gsub(/\s/,'').gsub('AvailableBalance:','').gsub('$','').to_f
  end
end

class CardsArray < Array
  def total
    return @total if @total
    @total = 0
    self.each do |c|
      @total += c.balance
    end
    @total
  end
  def sort_by_balance!
    self.sort! do |a, b|
      a.balance <=> b.balance
    end
  end
  def total_as_s
    "$#{"%0.2f" % total}"
  end
end
