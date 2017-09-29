P=Skull.xcodeproj

XCODEBUILD=xcodebuild

IOS_DEST=-destination 'platform=iOS Simulator,name=iPhone 7'
TVOS_DEST=-destination 'platform=tvOS Simulator,name=Apple TV'

all: macOS iOS watchOS tvOS

module:
	./configure

clean:
	rm -rf module
	$(XCODEBUILD) clean

test_%: module
	$(XCODEBUILD) test -project $(P) -configuration Debug -scheme $(SCHEME) $(DEST)

build_%: module
	$(XCODEBUILD) build -project $(P) -configuration Release -scheme $(SCHEME)

%macOS: SCHEME := Skull-macOS
%iOS: SCHEME := Skull-iOS
%watchOS: SCHEME := Skull-watchOS
%tvOS: SCHEME := Skull-tvOS

test_iOS: DEST := $(IOS_DEST)
test_tvOS: DEST := $(TVOS_DEST)

macOS: build_macOS
check_macOS: test_macOS

iOS: build_iOS
check_iOS: test_iOS

watchOS: build_watchOS
# No tests for watchOS because XCTest isn't available there.

tvOS: build_tvOS
check_tvOS: test_tvOS

check: check_macOS check_iOS check_tvOS

.PHONY: all, clean, check, %OS
