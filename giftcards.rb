require 'date'
require 'mechanize'

class Date
  def mo
    # Convenience function to return 2-digit month
    strftime('%m')
  end
  def yr
    # Convenience function to return 2-digit year
    strftime('%y')
  end
end

class GiftCard
  attr_reader :number, :exp, :cvv
  
  def initialize(number, exp, cvv)
    # Initialize with number, expiration date, and cvv..
    # GiftCard.new('1234-5678-9012-3456', '01/12', 123)
    @number = number.gsub('-','')
    @exp = Date.strptime(exp,"%m/%y")
    @cvv = cvv
  end
  def number_with_dashes
    # Return the number with dashes
    "#{number[0..3]}-#{number[4..7]}-#{number[8..11]}-#{number[12..15]}"
  end
  def masked_number
    # Return the number with the first 12 digits censored
    "XXXX-XXXX-XXXX-#{number[12..15]}"
  end
  def balance_as_s
    # Return balance as a string
    "$#{"%0.2f" % balance}" if respond_to? :balance
  end
  def value_as_s
    # Return card value as a string
    "$#{"%0.2f" % value}" if respond_to? :value
  end
  def agent
    @agent ||= Mechanize.new
  end
end

class VanillaVisa < GiftCard
  attr_reader :value
  
  def balance
    # Return the balance
    return @balance if @balance
    page = agent.get 'http://www.vanillavisa.com/home.html?product=giftcard&csrfToken='
    page = page.form_with(:action => /^\/accountHistory\.html/).tap do |form|
      form.cardNumber = number
      form.expiryMonth = exp.mo
      form.expiryYear = exp.yr
      form.creditCardID = cvv
    end.submit
    account = page.search '.textBold.number'
    @value = account.last.content.gsub(/[\s$]/, '').to_f
    @balance = @value - account.first.content.gsub(/[\s$]/, '').to_f
  end
end

class VanillaMasterCard < GiftCard
  attr_reader :value
  
  def balance
    # Return the balance
    return @balance if @balance
    page = agent.get 'http://www.vanillamastercard.com/home.html?locale=en_US&product=giftcard&csrfToken='
    page = page.form_with(:action => /^\/accountHistory\.html/).tap do |form|
      form.cardNumber = number
      form.expiryMonth = exp.mo
      form.expiryYear = exp.yr
      form.creditCardID = cvv
    end.submit
    account = page.search '.textBold.number'
    @value = account.last.content.gsub(/[\s$]/, '').to_f
    @balance = @value - account.first.content.gsub(/[\s$]/, '').to_f
  end
end

class CardsArray < Array
  def total
    # Return the sum of each GiftCard's balance
    @total ||= self.inject(0) { |result, card| result += card.balance }
  end
  def total_as_s
    # Return the sum of each GiftCard's balance as a string
    "$#{"%0.2f" % total}"
  end
  # Sort GiftCards by balance destructively
  def sort_by_balance!
    self.sort! do |a, b|
      a.balance <=> b.balance
    end
  end
end
