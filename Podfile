# Uncomment this line to define a global platform for your project
# platform :ios, "6.0"

source 'https://github.com/CocoaPods/Specs.git'

target "SpotifyAlarmClock" do
pod 'MBProgressHUD', '~> 0.8'
pod 'FFCircularProgressView', '~> 0.4'
end

target "SpotifyAlarmClockTests" do

end

# Remove 64-bit build architecture from Pods targets
post_install do |installer|
  installer.project.targets.each do |target|
    target.build_configurations.each do |configuration|
      target.build_settings(configuration.name)['ARCHS'] = '$(ARCHS_STANDARD_32_BIT)'
    end
  end
end
