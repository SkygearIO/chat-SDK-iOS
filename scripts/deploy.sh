#!/bin/bash -e

# Update docs.skygear.io
generate-ios-doc --pwd $PWD/Example --prefix https://github.com/SkygearIO/chat-SDK-iOS/tree/latest
publish-doc --platform ios --pwd $PWD  --doc-dir $PWD/docs --bucket 'docs.skygear.io' --prefix '/ios/chat/reference' --version 'latest' --distribution-id E31J8XF8IPV2V
