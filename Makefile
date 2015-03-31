
project=Skull.xcodeproj
scheme=Skull
sdk=iphonesimulator

all: clean build

clean:
	-rm -rf build

build:
	xcodebuild -configuration Debug build

test:
	xctool test \
		-project $(project) \
		-scheme $(scheme) \
		-sdk $(sdk) \
		-reporter pretty

.PHONY: all clean test
