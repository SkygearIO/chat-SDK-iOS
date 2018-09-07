VERSION := v$(shell git describe --always)
GIT_REF_NAME := master

DOCS_AWS_BUCKET := docs.skygear.io
DOCS_AWS_DISTRIBUTION := E31J8XF8IPV2V
DOCS_PREFIX = /ios/chat/reference

SKYKIT_VERSION := $(shell grep 'SKYKit/Core' Example/Podfile.lock | grep -v '~' | grep -o '\d.\d.\d\.')

ifeq ($(SKYKIT_VERSION),)
SKYKIT_VERSION = latest
endif

ifeq ($(VERSION),)
$(error VERSION is empty)
endif

.PHONY: update-version
update-version:
	sed -i "" "s/\(s\.version[^=]*=[^\']*\'\)[^\']*/\1$(VERSION)/" SKYKitChat.podspec
	cd Example; pod install

.PHONY: release-commit
release-commit:
	./scripts/release-commit.sh

.PHONY: before-gen-doc
before-gen-doc:
	mkdir -p vendors
	git clone -b $(SKYKIT_VERSION) \
		https://github.com/SkygearIO/skygear-SDK-iOS \
		vendors/skygear-SDK-iOS
	ln -s vendors/skygear-SDK-iOS/Pod/Classes SKYKit

.PHONY: after-gen-doc
after-gen-doc:
	rm -rf vendors/skygear-SDK-iOS SKYKit

.PHONY: gen-doc
gen-doc:
	jazzy \
		--github-file-prefix \
			https://github.com/SkygearIO/chat-SDK-iOS/tree/$(GIT_REF_NAME)

.PHONY: doc
doc: before-gen-doc gen-doc after-gen-doc

.PHONY: doc-clean
doc-clean:
	-rm docs

.PHONY: doc-upload
doc-upload:
	aws s3 sync docs s3://$(DOCS_AWS_BUCKET)$(DOCS_PREFIX)/$(VERSION) --delete

.PHONY: doc-invalidate
doc-invalidate:
		aws cloudfront create-invalidation \
			--distribution-id $(DOCS_AWS_DISTRIBUTION) \
			--paths "$(DOCS_PREFIX)/$(VERSION)/*"

.PHONY: doc-deploy
doc-deploy: doc-clean doc doc-upload doc-invalidate
