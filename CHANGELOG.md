### 4.0.3 (2016-10-29)

Correct iOS deployment target and version.

### 4.0.2 (2016-10-29)

Minor adjustments resulting from dogfooding.

- [`57e9d15`](https://github.com/michaelnisi/skull/commit/57e9d15c247fc68c235ae90f643af520fac96b39)
Complying with Apple’s recommendation to support the latest two majors, this sets the iOS deployment target to 9.0.
([@michaelnisi](https://github.com/michaelnisi))

- [`17cdd5f`](https://github.com/michaelnisi/skull/commit/17cdd5feeed31670a26d5ec3b7d391accbca8ded)
Type SkullRow value as Any.
([@michaelnisi](https://github.com/michaelnisi))

### 4.0.1 (2016-10-20)

A quick release improving the `README` and practicing writing this `CHANGELOG`—it’s quite likely that I won’t be doing this for long. Let’s see!

- [`a3784c3`](https://github.com/michaelnisi/skull/commit/a3784c39052468a4457b53e823ab74136790a34b)
Add a wonky Einstein citation and try to make it clearer that you have to generate the module maps before you can build the framework with Xcode. Also, as I just realized, a modification of the tvOS scheme has slipped in, which I’m not sure about. I hope it’s a leftover that should have been in the previous release.
([@michaelnisi](https://github.com/michaelnisi))

### 4.0.0 (2016-10-11)

This release is mainly about migrating to Swift 3, but I've also found it timely to adopt Swift Package Manager conventions.

Being able to drop the C helpers, thanks to Swift 3 support of C function pointer callbacks, is my favorite in this release.
([@michaelnisi](https://github.com/michaelnisi))

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
