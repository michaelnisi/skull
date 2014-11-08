
project=Skull.xcodeproj
scheme=SkullTests
sdk=iphonesimulator

all: test

test: modularize
	xctool test -project $(project) -scheme $(scheme) -sdk $(sdk)

modularize:
	sed -e "s;%SRC%;`pwd`/Skull;g" module/module.map.in > module/module.map
