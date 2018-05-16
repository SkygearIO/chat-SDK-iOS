VERSION := v$(shell git describe --always)

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
