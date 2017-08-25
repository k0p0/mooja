# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)
require 'open-uri'
require 'nokogiri'

puts "Destroying Discounts"
Discount.destroy_all
puts "Destroying Bookings"
Booking.destroy_all
puts "Destroying Surfcamps"
Surfcamp.destroy_all
puts "Destroying Users"
User.destroy_all


puts "Creating Users"
i = 0
users = [
  "jackie@michel.com",
  "michel@jackie.com",
  "micheline@jackie.com"
]
first_names = [
  "Thibault",
  "Clemence",
  "Dima"
]

3.times do
  user = User.new
  user.email = users[i]
  user.password = 'password'
  user.first_name = first_names[i]
  user.last_name = Faker::Name.last_name
  urls = [
    "https://scontent-cdt1-1.xx.fbcdn.net/v/t1.0-9/10997490_907097779334969_1284262528561985815_n.jpg?oh=c3afa5c308ce7405d109656dda4ffd50&oe=5A2F762F",
    "https://scontent-cdt1-1.xx.fbcdn.net/v/t1.0-9/20799136_274376209715766_7099253975910970765_n.jpg?oh=e84997278e80801d94f81ca917120c19&oe=5A1A935E",
    "https://scontent-cdt1-1.xx.fbcdn.net/v/t1.0-9/19875558_10155671439642176_1610883172945385131_n.jpg?oh=482cbb47e3786e5c1c813330c294645e&oe=5A16D6B7"
  ]
  user.facebook_picture_url = urls[i]
  user.save!
  i += 1
end
puts "Users created"

puts "Creating Admin"
admin = User.new
admin.email = "admin@admin.admin"
admin.password = "astrongpassword"
admin.first_name = "admin"
admin.last_name = "ADMIN"
admin.facebook_picture_url = "https://scontent-cdt1-1.xx.fbcdn.net/v/t1.0-9/10997490_907097779334969_1284262528561985815_n.jpg?oh=c3afa5c308ce7405d109656dda4ffd50&oe=5A2F762F"
admin.admin = true
admin.save!
puts "Admin created"

puts "Creating Surfcamps"
# all the countries available on the website
countries = [
  "portugal",
  "morocco",
  "canary-islands",
  "costa-rica",
  "indonesia",
  "barbados",
  "spain",
  "france",
  "ireland"
  ]
# Showcasing the countries we will scrapp
puts ""
puts "    This is all the countries we will scrapp"
countries.each_with_index do |country, index|
  puts "    #{index +1}- #{country}"
end
puts ""
# iterating over all the countries
countries.each do |country|
  s = 0
  puts "    Iterating over #{country}"
  # The url we are scrapping
  url = "https://www.surfholidays.com/property-search?country=#{country}all&town=all&checkin=&checkout=&guests=2&suitable_for=surfcamps"
  base_url = "https://www.surfholidays.com"
  html_file = open(url).read
  html_doc = Nokogiri::HTML(html_file)
  surfcamp_total = html_doc.search(".name-location a").count
  # We look for all the a in the div that match our criterias
  puts "    #{surfcamp_total} Surfcamps to magically scrapp in #{country}"
  html_doc.search(".name-location a").each do |element|
    page_url = element.attribute('href').value
    complete_url = "#{base_url}#{page_url}"

    html_file = open(complete_url).read
    html_doc = Nokogiri::HTML(html_file)
    images_surfcamp = []

    # Initializing instance of surfcamp
    surfcamp = Surfcamp.new

    # We create surfcamp with the data that has been scrapped
    html_doc.search("#custom-slider ul li").each do |element|
      images_surfcamp << element['style'][/url\((.+)\)/, 1].gsub("'","")
    end
    # creating surfcamp image
    surfcamp.photo_url = images_surfcamp[0]
    html_doc.search("h1.sh-navy").each do |element|
      name = element.text
      # creating surfcamp name
      surfcamp.name = name
    end
    # creating surfcamp description
    surfcamp.description = Faker::Lorem.paragraph
     html_doc.search("#accom-detail-location").each do |element|
      address = element.text.strip
      # creating surfcamp address
      surfcamp.address = address
    end
    ratings = []
    html_doc.search("p.bolder.sh-orange span.bigger-font18").each do |element|
      ratings << element.text.strip
      # creating surfcamp rating
      surfcamp.rating = ratings[0]
    end
    # creating surfcamp capacity
    surfcamp.capacity = rand(6..50)
    # creating surfcamp price_per_night_per_person
    surfcamp.price_per_night_per_person = rand(30..70)
    surfcamp.save!
    s += 1
    puts "    #{s}/#{surfcamp_total} scrapped in #{country}"
  end
  puts ""
end
puts "Done creating surfcamps"


puts "Creating Discounted Prices"
sept_first = Date.parse("September 1st")

# creating 0 or 1 promo per surfcamp
Surfcamp.all.each do |surfcamp|

  # creating discount with a proba of 80%
  discount_occurence_probability = 80
  apply_discount = (1..100).to_a.sample > (100 - discount_occurence_probability)

  if apply_discount
    discount = Discount.new
    # creating discount between 20 and 50% reduction
    discount_rate = [20, 30, 40, 50].sample.to_f/100
    discounted_price = (1 - discount_rate) * surfcamp.price_per_night_per_person
    discount.discounted_price = discounted_price

    # Between September 1st and September 15th
    discount.limit_offer_date = (sept_first..(sept_first + 15.days)).to_a.sample

    discount.discount_starts_at = (sept_first..(sept_first + 15)).to_a.sample
    discount.discount_ends_at = discount.discount_starts_at + (7..28).to_a.sample.days

    discount.surfcamp_id = surfcamp.id
    discount.save!
  end
end

puts "Done Creating Discounted Prices"


puts "Creating Bookings"

surfcamps = Surfcamp.all
surfcamps.each do |surfcamp|
  # creating between 2 and 10 bookings per surfcamp
  rand(2..10).times do
    # initializing instance of Booking
    booking = Booking.new
    sept_first = Date.parse("September 1st")
    # creating starts at and ends at and status and foreign keys
    booking.starts_at = sept_first + rand(3..14).days
    booking.ends_at = booking.starts_at + rand(3..14).days
    booking.status = "paid"
    booking.surfcamp_id = surfcamp.id
    users = User.all
    user = users.sample
    booking.user_id = user.id
    # creating pax_nb
    booking.pax_nb = rand(1..4)
    # creating total original price
    booking_duration = (booking.ends_at - booking.starts_at)/86400
    booking.total_original_price = booking.pax_nb * surfcamp.price_per_night_per_person * booking_duration

    # creating total discounted price
    # is there a discount for this surfcamp
    surfcamp.discounts.first.blank? ? discount = nil : discount = surfcamp.discounts.first

    # Build array of nights
    nights = []
    night = booking.starts_at.to_date
    booking_duration.to_i.times do |_n|
      nights << night
      night += 1
    end

    total_discounted_price = 0
    # check if surfcamp has a discount
    if discount.nil?
      total_discounted_price = booking.total_original_price
    else
      # for each night
      nights.each do |night|
        # check for each night if a discount is applicable
        if night >= discount.discount_starts_at.to_date && night <= discount.discount_ends_at.to_date
          # then apply the discount for this night
          night_price = discount.discounted_price * booking.pax_nb
        else
          # otherwise normal price for this night
          night_price = surfcamp.price_per_night_per_person * booking.pax_nb
        end
        # sum each price per night with discount
        total_discounted_price += night_price
      end
    end

    booking.total_discounted_price = total_discounted_price

    booking.save!
    # puts "successfully saved a booking for #{surfcamp.name}"
  end
end

puts "Done Creating Bookings"

puts "Seed is done"
puts "Happy coding!!!"


