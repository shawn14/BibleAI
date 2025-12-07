#!/usr/bin/env ruby

# Script to create IAP products using App Store Connect API
# Requires spaceship (part of fastlane)

require 'spaceship'

# Login credentials
APPLE_ID = "shawncarpenter@mac.com"
APP_BUNDLE_ID = "com.shawncarpenter.bibleai-companion"

# IAP Product definitions
IAP_PRODUCTS = [
  {
    product_id: "com.shawncarpenter.bibleai-companion.premium.monthly",
    reference_name: "Premium Monthly",
    type: "auto_renewable_subscription",
    subscription_duration: "1 month",
    price_tier: 70, # $6.99
    locales: {
      "en-US" => {
        subscription_name: "Premium Monthly",
        description: "Unlimited AI Bible study questions and features"
      }
    }
  },
  {
    product_id: "com.shawncarpenter.bibleai-companion.premium.yearly",
    reference_name: "Premium Yearly",
    type: "auto_renewable_subscription",
    subscription_duration: "1 year",
    price_tier: 500, # $49.99
    locales: {
      "en-US" => {
        subscription_name: "Premium Yearly",
        description: "Unlimited AI Bible study questions and features - Save 40%!"
      }
    }
  }
]

puts "🚀 Starting IAP product creation..."
puts "📧 Apple ID: #{APPLE_ID}"
puts "📦 Bundle ID: #{APP_BUNDLE_ID}"
puts ""

begin
  # Login to App Store Connect
  puts "🔐 Logging in to App Store Connect..."
  Spaceship::ConnectAPI.login(APPLE_ID)

  # Find the app
  puts "🔍 Finding app..."
  app = Spaceship::ConnectAPI::App.find(APP_BUNDLE_ID)

  if app.nil?
    puts "❌ App not found. Please create the app first using:"
    puts "   fastlane setup_app_store"
    exit 1
  end

  puts "✅ Found app: #{app.name}"
  puts ""

  # Create IAP products
  IAP_PRODUCTS.each do |product_def|
    puts "📱 Creating #{product_def[:reference_name]}..."

    begin
      # Note: This is a simplified example
      # The actual Spaceship API for IAP products may differ
      # You may need to use App Store Connect web UI or API directly

      puts "   Product ID: #{product_def[:product_id]}"
      puts "   Price: Tier #{product_def[:price_tier]}"
      puts "   Duration: #{product_def[:subscription_duration]}"

      # TODO: Use actual Spaceship API when available
      # For now, print instructions
      puts "   ⚠️  Manual creation required - see instructions below"
      puts ""

    rescue => e
      puts "   ❌ Error: #{e.message}"
    end
  end

  puts ""
  puts "=" * 60
  puts "📝 MANUAL STEPS REQUIRED"
  puts "=" * 60
  puts ""
  puts "Unfortunately, Fastlane/Spaceship doesn't fully support"
  puts "creating subscription products automatically."
  puts ""
  puts "Please create these products manually in App Store Connect:"
  puts "https://appstoreconnect.apple.com"
  puts ""

  IAP_PRODUCTS.each_with_index do |product, index|
    puts "#{index + 1}. #{product[:reference_name]}"
    puts "   Product ID: #{product[:product_id]}"
    puts "   Type: Auto-Renewable Subscription"
    puts "   Duration: #{product[:subscription_duration]}"
    puts "   Price: Tier #{product[:price_tier]} (~$#{product[:price_tier] == 70 ? '6.99' : '49.99'})"
    puts "   Display Name: #{product[:locales]['en-US'][:subscription_name]}"
    puts "   Description: #{product[:locales]['en-US'][:description]}"
    puts ""
  end

  puts "=" * 60

rescue Spaceship::Client::UnauthorizedAccessError
  puts "❌ Login failed. Please check your Apple ID credentials."
  puts "   You may need to generate an app-specific password:"
  puts "   https://appleid.apple.com/account/manage"
rescue => e
  puts "❌ Unexpected error: #{e.message}"
  puts e.backtrace
end
