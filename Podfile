# Podfile for BibleAI Companion

platform :ios, '17.0'

target 'BibleAI' do
  use_frameworks!

  # RevenueCat SDK
  pod 'RevenueCat', '~> 5.0'
  pod 'RevenueCatUI', '~> 5.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Suppress warnings for pods
      config.build_settings['WARNING_CFLAGS'] ||= ['$(inherited)', '-Wno-error=protocol']
    end
  end
end
