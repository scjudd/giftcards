giftcards
=========

A ruby library to check the balance on various gift cards

Example
-------

```ruby
require 'giftcards'

cards = CardsArray.new([
  VanillaVisa.new('4315-1234-5678-9012', '01/13', 123),
  VanillaMasterCard.new('5154-1234-5678-9012', '01/13', 123),
  GiftCardMallVisa.new('4416-6912-3456-7890', '9999', 491),
])
cards.sort_by_balance!

cards.each do |c|
  puts "#{c.masked_number}: #{c.balance_as_s}"
end
puts "Total: #{cards.total_as_s}"
```

