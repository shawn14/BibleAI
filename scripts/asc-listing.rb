# Read (default) or write the BibleAI App Store listing with the shared App Manager API key.
#   ruby scripts/asc-listing.rb               -> prints current listing JSON
#   ruby scripts/asc-listing.rb push 2.0      -> applies docs/aso/en-US/*.txt to version 2.0 (creates it if needed)
require 'spaceship' unless defined?(Spaceship)
require 'json'

Spaceship::ConnectAPI.auth(key_id: '6T6GWQ6BW7', issuer_id: '69a6de83-d381-47e3-e053-5b8c7c11a4d1',
                           filepath: File.expand_path('~/.appstoreconnect/private_keys/AuthKey_6T6GWQ6BW7.p8'))
app = Spaceship::ConnectAPI::App.find('com.shawncarpenter.bibleai-companion') or abort 'App not found'
mode = ENV['LISTING_MODE'].to_s.empty? ? ARGV[0] : ENV['LISTING_MODE']
version_string = ENV['LISTING_VERSION'].to_s.empty? ? ARGV[1] : ENV['LISTING_VERSION']

def info_loc(app)
  info = app.fetch_edit_app_info || app.fetch_live_app_info
  [info, info.get_app_info_localizations.find { |l| l.locale == 'en-US' }]
end

if mode == 'push'
  abort 'Pass a version' unless version_string
  dir = File.expand_path('../docs/aso/en-US', __dir__)
  read = ->(f) { p = File.join(dir, "#{f}.txt"); File.exist?(p) ? File.read(p).strip : nil }
  version = app.get_edit_app_store_version(platform: 'IOS')
  if version.nil?
    Spaceship::ConnectAPI.post_app_store_version(app_id: app.id, attributes: { platform: 'IOS', versionString: version_string })
    version = app.get_edit_app_store_version(platform: 'IOS') or abort 'Could not create version'
  elsif version.version_string != version_string
    version.update(attributes: { versionString: version_string })
  end
  loc = version.get_app_store_version_localizations.find { |l| l.locale == 'en-US' }
  attrs = { description: read['description'], keywords: read['keywords'], promotionalText: read['promotional_text'],
            whatsNew: read['release_notes'], marketingUrl: read['marketing_url'], supportUrl: read['support_url'] }.compact
  loc.update(attributes: attrs)
  info, iloc = info_loc(app)
  iattrs = { name: read['name'], subtitle: read['subtitle'], privacyPolicyUrl: read['privacy_url'] }.compact
  iloc.update(attributes: iattrs) if iloc && info.app_store_state.to_s !~ /READY_FOR_SALE/
  puts "Pushed listing to #{version.version_string} (#{version.app_store_state})"
end

out = { app_id: app.id, name: app.name }
live = app.get_live_app_store_version(platform: 'IOS')
edit = app.get_edit_app_store_version(platform: 'IOS')
[['live', live], ['edit', edit]].each do |label, v|
  next unless v
  l = v.get_app_store_version_localizations.find { |x| x.locale == 'en-US' }
  out[label] = { version: v.version_string, state: v.app_store_state,
                 description: l&.description, keywords: l&.keywords, promo: l&.promotional_text,
                 whats_new: l&.whats_new, support: l&.support_url, marketing: l&.marketing_url }
end
info, iloc = info_loc(app)
out['info'] = { state: info.app_store_state, name: iloc&.name, subtitle: iloc&.subtitle, privacy: iloc&.privacy_policy_url }
puts JSON.pretty_generate(out)
