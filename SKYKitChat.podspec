Pod::Spec.new do |s|
  s.name             = 'SKYKitChat'
  s.version          = '0.0.1'
  s.summary          = 'Chat extension for SKYKit'

  s.description      = <<-DESC
This is the client library for the Skygear Chat extension.
                       DESC

  s.homepage         = 'https://github.com/SkygearIO/chat-SDK-iOS'
  s.license          = 'Apache License, Version 2.0'
  s.author           = { "Oursky Ltd." => "hello@oursky.com" }
  s.source           = { :git => 'https://github.com/SkygearIO/chat-SDK-iOS.git', :tag => s.version.to_s }

  s.ios.deployment_target = '8.0'

  s.source_files = 'SKYKitChat/Classes/Core/**/*'
  s.dependency 'SKYKit', '~> 0.21.0'

  s.subspec 'UI' do |sp|
    sp.source_files = 'SKYKitChat/Classes/UI/**/*'
    sp.dependency 'JSQMessagesViewController', '~> 7.3.0'
  end

end
