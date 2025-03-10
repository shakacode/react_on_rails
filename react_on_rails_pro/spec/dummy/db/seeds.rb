# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

# Clear existing data
puts "Clearing existing data..."
Comment.delete_all
Post.delete_all
User.delete_all

# Create Users
puts "Creating users..."
10.times do
  User.create!(
    name: Faker::Name.name,
    email: Faker::Internet.unique.email
  )
end

# Create Posts
puts "Creating posts..."
User.all.each do |user|
  rand(3..7).times do
    user.posts.create!(
      title: Faker::Lorem.sentence(word_count: 3),
      body: Faker::Lorem.paragraphs(number: 3).join("\n\n")
    )
  end
end

# Create Comments
puts "Creating comments..."
Post.all.each do |post|
  rand(2..5).times do
    post.comments.create!(
      user: User.all.sample,
      body: Faker::Lorem.paragraph
    )
  end
end

puts "Seed data created successfully!"
