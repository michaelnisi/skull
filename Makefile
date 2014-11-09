
project=Skull.xcodeproj
scheme=SkullTests
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild -configuration Debug build

test:
	xctool test -project $(project) -scheme $(scheme) -sdk $(sdk)

.PHONY: all clean test
