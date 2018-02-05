Pod::Spec.new do |s|
  s.name             = 'SKYKitChat'
  s.version          = '1.2.0-alpha.6'
  s.summary          = 'Chat extension for SKYKit'

  s.description      = <<-DESC
This is the client library for the Skygear Chat extension.
                       DESC

  s.homepage         = 'https://github.com/SkygearIO/chat-SDK-iOS'
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "Oursky Ltd." => "hello@oursky.com" }
  s.source           = { :git => 'https://github.com/SkygearIO/chat-SDK-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.2'
  s.default_subspecs = 'Core'
  s.dependency 'Realm', '~> 3.0.1'

  s.subspec 'Core' do |sp|
    sp.source_files = 'SKYKitChat/Classes/Core/**/*'
    sp.resource_bundles = {
        'SKYKitChatUI' => [
            'SKYKitChat/Assets/*.xcassets'
        ]
    }

    sp.dependency 'SKYKit/Core', '~> 1.3.1'
  end


  s.subspec 'UI' do |sp|

    sp.public_header_files = 'SKYKitChat/Classes/UI/**/*.h'
    sp.source_files = 'SKYKitChat/Classes/UI/**/*'

    sp.dependency 'SKYKitChat/Core'
    sp.dependency 'SKYKit/Core',                       '~> 1.3.1'
    sp.dependency 'SVProgressHUD',                     '~> 2.1.0'
    sp.dependency 'ALCameraViewController',            '~> 3.0'
    sp.dependency 'LruCache',                          '~> 0.1'
    sp.dependency 'CTAssetsPickerController',          '~> 3.3.1'
    sp.dependency 'SKPhotoBrowser',                    '~> 5.0'
    sp.dependency 'JSQSystemSoundPlayer',              '~> 2.0.1'
    sp.dependency 'JSQMessagesViewController-Skygear', '7.3.5.1'
  end

end
