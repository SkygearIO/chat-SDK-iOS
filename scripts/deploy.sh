#!/bin/bash -e

# Update docs.skygear.io
generate-ios-doc --pwd $PWD
publish-doc --platform ios --pwd $PWD  --doc-dir $PWD/jazzy_docs --bucket 'docs.skygear.io' --prefix '/ios/chat/reference' --version 'latest' --distribution-id E31J8XF8IPV2V
