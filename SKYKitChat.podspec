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

  s.source_files = 'SKYKitChat/Classes/**/*'
  s.dependency 'SKYKit', '~> 0.19.0'
  
  # s.resource_bundles = {
  #   'SKYKitChat' => ['SKYKitChat/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
