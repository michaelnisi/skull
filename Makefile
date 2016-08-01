project=Skull.xcodeproj
scheme=Skull
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild build -configuration Debug

test:
	xcodebuild test -configuration Debug -scheme Skull -sdk iphonesimulator9.3

.PHONY: all clean test
