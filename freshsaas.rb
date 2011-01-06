#!/usr/bin/env ruby
require 'rubygems'
require 'freshbooks'
require 'builder'
require 'rest_client'

### Config

# Found in Settings -> Web Services or https://secure.saasu.com/a/net/webservicessettings.aspx
saasu_api_key = "REPLACE ME" # looks like "AAAA-1111-BBBB-2222-CCCC-3333-DDDD-4444"
# Found right above your API key.
saasu_file_id = "REPLACE ME" # looks like "5555"

saasu_tax_code = 'G1,G3' # 'G1,G3' = No GST. 'G1' = inc. GST

# This is the url you login to your account.
freshbook_url = 'YOUR_URL.freshbooks.com'
# Found in My Account -> FreshBooks API
freshbook_key = 'REPLACE ME' # looks like "a1b2c3d4e5f6g7a8b9c0"

# Map contact ID's freshbooks => saasu
contact_map = {
  1 => '777777', # contact 1
  2 => '666666'  # contact 2
}
# Map contact ID to currency billed in
currency_map = {
  5 => 'AUD',
  6 => 'USD',
  8 => 'AUD'
}
# Map FB 'task'/'name' to saasu 'Items'. You'll need to add these as items first
item_map = {
  'Development' => '444444',
  'Research' => '444555',
  'Meetings' => '555666',
  'Administration' => '333444',
  'General' => '555444'
}

### end Config

@output = ""
xml = Builder::XmlMarkup.new(:target => @output, :indent => 2)
#xml = Builder::XmlMarkup.new(:target=>STDOUT, :indent=>2)
invoice_id = ARGV[0]
throw "Please call this script with a freshbooks invoice ID" unless invoice_id

puts "About to copy freshbooks Invoice #{invoice_id}, Yes to confirm>"
confirm = STDIN.gets.strip.downcase
exit unless confirm == "yes"

print "Connecting ..."
FreshBooks::Base.establish_connection(freshbook_url, freshbook_key)
puts " done"

print "Getting Invoice from Freshbooks ... "
fresh_invoice = FreshBooks::Invoice.get(invoice_id)
puts "done"

# Example URL to fetch Invoice XML:
# https://secure.saasu.com/webservices/rest/r1/invoice?wsaccesskey=[saasu_api_key]&fileuid=[file_id]&uid=888888
# To Post invoice
post_url = "https://secure.saasu.com/webservices/rest/r1/tasks?wsaccesskey=#{saasu_api_key}&fileuid=#{saasu_file_id}"

print "Generating XML "

xml.instruct!
xml.tasks(:'xmlns:xsd'=>"http://www.w3.org/2001/XMLSchema", :'xmlns:xsi'=>"http://www.w3.org/2001/XMLSchema-instance") do
  xml.insertInvoice(:emailToContact=>"false") do
    xml.invoice(:uid => 0) do
      xml.transactionType("S")
      xml.date(fresh_invoice.date.to_formatted_s("%Y-%M-%D"))
      xml.contactUid(contact_map[fresh_invoice.client_id])
      xml.ccy(currency_map[fresh_invoice.client_id])
      xml.autoPopulateFxRate('true')
      xml.requiresFollowUp('false')
      xml.layout('I')
      xml.status('I')
      xml.invoiceNumber(fresh_invoice.number)
      xml.invoiceItems do
        fresh_invoice.lines.each do |fl|
          next unless fl.amount > 0 or fl.quantity > 0
          print "."
          xml.itemInvoiceItem do
            xml.quantity(fl.amount/fl.unit_cost)
            xml.inventoryItemUid(item_map[fl.name])
            xml.description(fl.description)
            xml.unitPriceInclTax(fl.unit_cost)
            xml.percentageDiscount(0.0)
            xml.taxCode(saasu_tax_code)
          end
        end
      end
      xml.isSent('false')
    end
    xml.createAsAdjustmentNote('false')
  end
end
puts "done"
#puts @output
print "Posting to Saasu ... "
res = RestClient.post post_url, @output
puts "done"
puts res
