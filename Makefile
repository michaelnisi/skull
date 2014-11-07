
# Just for testing with xctool. Build with Xcode.

project=Skull.xcodeproj
scheme=SkullTests
sdk=iphonesimulator

all: test

test:
	xctool test -project $(project) -scheme $(scheme) -sdk $(sdk)
