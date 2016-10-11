### 4.0.0 (2016-10-11)

This release is mainly about migrating to Swift 3, but I've also found it timely to adopt Swift Package Manager conventions.

Being able to drop the C helpers, thanks to Swift 3 support of C function pointer callbacks, is my favorite in this release.
([@michaelnisi])(https://github.com/michaelnisi))

#### Swift Package Manager

- Restructure repository
- Experimentally build with SPM
- Reluctantly, change Git tag format to comply with SPM

#### Code Coverage

- Gather test coverage data for iOS
- Add [CodeCov](https://codecov.io/)-badge

#### Cross Platform

- Complete Xcode schemes for all platforms
- Use patterns in Makefile

#### Swift 3

- Migrate to Swift 3
- Remove C helpers
- Fall back on NOPs for callbacks

#### Documentation

- Document SPM usage
- Add example
- Rewrite README
