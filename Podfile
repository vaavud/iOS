source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
use_frameworks!
project 'Vaavud'

target 'Vaavud' do

pod 'Dropbox-iOS-SDK'
pod 'Amplitude-iOS'

pod 'Firebase/Core'
pod 'Firebase/Database'
pod 'Firebase/Auth'

pod 'Bolts'
pod 'FBSDKCoreKit'
pod 'FBSDKLoginKit'
pod 'FBSDKShareKit'
pod 'GeoFire', :git => 'https://github.com/firebase/geofire-objc.git'

pod 'Palau', '~> 1.0'

end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            config.build_settings['SWIFT_VERSION'] = '2.3'
        end
    end
end
