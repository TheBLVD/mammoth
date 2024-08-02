[![Crowdin](https://badges.crowdin.net/mammoth-app/localized.svg)](https://crowdin.com/project/mammoth-app)

## Welcome

This repository contains the source code for the [Mammoth app](https://getmammoth.app) for iOS, iPadOS and MacOS, released under the [GNU Affero General Public License](https://www.gnu.org/licenses/agpl-3.0.html).

Feel free to take a look around. We are not yet taking patches as we still have a little bit of tidying up to do. When we do, there will be a contributor license agreement. Also, over the next week or two we'll start having some simple "infrastructure" (think: discord channel, etc.). Stay tuned... Bear with us; it's launch week and weekend!

The Mammoth Team


## Getting Started

### Requirements:

We use [Arkana](https://github.com/rogerluan/arkana) to obfuscate API keys and secrets in Mammoth, which requires the following versions:

- Ruby 3.1+
- Node.js 16+
- Xcode 13+
- Swift 5+

1. Clone the repo

```zsh
% git clone https://github.com/TheBLVD/mammoth.git
```

2. Navigate to the repo, and copy the `sample.env` to `.env`:

```zsh
% cd mammoth
% cp sample.env .env
```

3. Install `rbenv` if not already installed. See [Installing `rbenv`](#installing-rbenv) below for instructions.
4. Install a compatible version of ruby:

```zsh
% rbenv install
```

5. Install ruby dependencies to get the needed gems:

```zsh
% bundle install
```

6. Regenerate the `ArkanaKeys` package for managing API keys and secrets. This step can be repeated as whenever you change your `.env` file's contents:

```zsh
% bin/arkana
```

### Installing `rbenv`

1. Install [Homebrew](https://brew.sh) if you don't already have it:

```zsh
% /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2. Install [rbenv](https://github.com/rbenv/rbenv) using Homebrew:

```zsh
% brew install rbenv ruby-build
```

3. Initialize `rbenv` by installing it in your zsh profile, and reload the profile (this assumes you are using `zsh` by default — if you aren't, please run `rbenv init` instead and follow instructions):

```
% echo "eval \"\$(rbenv init - zsh)\"" >> ~/.zshrc
% exec zsh
```

4. Install a compatible version of ruby, and continue the steps [above](#requirements):

```zsh
% rbenv install
```

5. You can verify the right version of Ruby is installed by running `ruby --version`:

```zsh
% ruby --version
ruby 3.2.1 (2023-02-08 revision 31819e82c8) [arm64-darwin22]
```

6. Install SwiftLint

```zsh
brew install swiftlint
```

### Troubleshooting

- If you run `bin/arkana` and see the following, it can't find a valid `.env`
  file. Make sure you've copied the provided sample correctly and that it is in
  the root of the repo.
  ![TerminalErrorMessage](https://github.com/TheBLVD/mammoth-app/assets/76360/ce645773-4713-460a-bb0f-acc698a180d1)

- If you see this in Xcode. Then Arkana has failed to generate the local
  package. Verify you have a valid `.env` and run `bin/arkana` from the root of
  the repo.
  ![XcodeArkanaBuildError](https://github.com/TheBLVD/mammoth-app/assets/76360/ec0fd8a9-285f-41dd-817d-60fc41d94e54)

- If you run `bin/arkana` and see the following:

```sh
/System/Library/Frameworks/Ruby.framework/Versions/2.6/usr/lib/ruby/2.6.0/universal-darwin22/rbconfig.rb:21: warning: Insecure world writable dir /usr/local/bin in PATH, mode 040777
You must use Bundler 2 or greater with this lockfile.
```

Ruby 3 is required. Check your ruby version `ruby --version`, and check [Installing `rbenv`](#installing-rbenv) above for instructions on installing a new version.

### Adding Private Keys

Steps to adding a new key/value to the project using Arkana. Upfront there are two options.

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
