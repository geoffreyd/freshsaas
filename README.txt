FreshSaas is a script that will read an invoice from Freshbooks[1] and push it to saasu[2].

You'll need to following gems
  gem install builder rest-client bcurren-freshbooks.rb

Before running there is a little bit of setup needed. Open up freshsaas.rb, and fill in the config section.

To run, just pass in the freshbooks invoice id:

./freshsaas.rb 42

Then type 'yes' to confirm that you want todo this. Done.

[1] freshbooks.com
[2] saasu.com