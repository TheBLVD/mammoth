[![Crowdin](https://badges.crowdin.net/mammoth-app/localized.svg)](https://crowdin.com/project/mammoth-app)

## Welcome

This repository contains the source code for the [Mammoth app](https://getmammoth.app) for iOS, iPadOS and MacOS, released under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html).

Feel free to take a look around. We are not yet taking patches as we still have a little bit of tidying up to do. When we do, there will be a contributor license agreement. Also, over the next week or two we'll start having some simple "infrastructure" (think: discord channel, etc.). Stay tuned... Bear with us; it's launch week and weekend!

The Mammoth Team


## Getting Started

**Requirements:**

- Ruby 3.1+
- Node.js 16+
- Xcode 13+
- Swift 5+

1. Clone the repo
1. Copy the `sample.env` to `.env`
1. Run `bundle install` to get the needed gems
1. From the root of the application still run `bin/arkana` This will generated
   the needed 'ArkanaKeys' package that is a local swift package dependency.

**Troubleshooting**

- If you run `bin/arkana` and see the following, it can't find a valid `.env`
  file. Make sure you've copied the provided sample correctly and that it is in
  the root of the repo.
  ![TerminalErrorMessage](https://github.com/TheBLVD/mammoth-app/assets/76360/ce645773-4713-460a-bb0f-acc698a180d1)

- If you see this in Xcode. Then Arkana has failed to generate the local
  package. Verify you have a valid `.env` and run `bin/arkana` from the root of
  the repo.
  ![XcodeArkanaBuildError](https://github.com/TheBLVD/mammoth-app/assets/76360/ec0fd8a9-285f-41dd-817d-60fc41d94e54)

- If you run `bin/arckan` and see the following:

```sh
/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/universal-darwin22/rbconfig.rb:21: warning: Insecure world writable dir /usr/local/bin in PATH, mode 040777
You must use Bundler 2 or greater with this lockfile.
```

Ruby 3 is required. Check your ruby version `ruby --version`.

1. install brew [(see web page instructions)](https://brew.sh)
2. install rbenv
   [(brew install rbenv ruby-build)](https://github.com/rbenv/rbenv/blob/master/README.md)
3. run `rbenv init` and follow the printed instructions
4. install current Ruby version `rbenv install 3.2.1`
5. set version to global or local.

```sh
rbenv global 3.2.1   # set the default Ruby version for this machine
# or:
rbenv local 3.2.1    # set the Ruby version for this directory
```

6. verify Ruby is installed `ruby --version` should return something like this.
   Your minor version may differ.

```sh
➜ ruby --version
ruby 3.2.1 (2023-02-08 revision 31819e82c8) [arm64-darwin22]
```

**Adding Private Keys** Steps to adding a new key/value to the project using
Arkana. Upfront there are two options.

1. Global: same key/value for staging and production
2. Environment: one value for staging, and separate value for production. Both
   will reference the same key in the app

3. First Step Add your env name to `.arkana.yml` either under 'global_secrets'
   or 'environment_secrets'

4. Second Step Add the key/value pair to your local `.env` file and key names to
   `sample.env`

_NOTE:_ for global keys, they are added to the top of the file just once like
this:

```
#.env
...
ExampleSecretKey=2903847
```

If you're using 'environment_secrets' you'll need 2 key/value entries with
appended 'Staging' & 'Production':

```
#.env
...
ExampleSecretKeyStaging=03948092348504
ExampleSecretKeyProduction=02398450349
```

3. Finally From the root of the project on the command line run `bin/arkana`.
   This embeds the env values in the Arkana swift package and the are now
   available to call in your code like this

```swift
///randomProjectFile.swift


/// env that is global
ArkanaKeys.Global().exampleSecretKey

/// env var for staging
ArkanaKeys.Staging().exampleSecretKey
```

If `bin/arkan` throws an error, see troublshooting above ☝.

## License

This repository contains the source code for the Mammoth app for iOS, iPadOS and MacOS, released under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html).

See [LICENSE](./LICENSE.md) for details.

All conversations in [Issues](https://github.com/TheBLVD/mammoth/issues) will be licensed under CC-0. https://creativecommons.org/publicdomain/zero/1.0/

Unless otherwise noted, all files © 2023 The BLVD. All rights reserved.
