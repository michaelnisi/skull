project=Skull.xcodeproj
scheme=Skull
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild build -configuration Debug

test:
	xcodebuild test -configuration Debug -scheme Skull -destination 'platform=iOS Simulator,name=iPhone 6s'

.PHONY: all clean test
