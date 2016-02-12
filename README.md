# Sharetribe

[![Build Status](https://travis-ci.org/sharetribe/sharetribe.svg?branch=master)](https://travis-ci.org/sharetribe/sharetribe) [![Dependency Status](https://gemnasium.com/sharetribe/sharetribe.png)](https://gemnasium.com/sharetribe/sharetribe) [![Code Climate](https://codeclimate.com/github/sharetribe/sharetribe.png)](https://codeclimate.com/github/sharetribe/sharetribe) [![Coverage Status](https://coveralls.io/repos/sharetribe/sharetribe/badge.png)](https://coveralls.io/r/sharetribe/sharetribe)

Sharetribe is an open source platform to create your own peer-to-peer marketplace.

Would you like to set up your marketplace in one minute without touching code? [Head to Sharetribe.com](https://www.sharetribe.com).

Want to get in touch? Email [info@sharetribe.com](mailto:info@sharetribe.com)

### Contents
- [Installation](#installation)
- [Payments](#payments)
- [Updating](#payments)
- [Technical roadmap](#technical-roadmap)
- [Contributing](#contributing)
- [Translation](#translation)
- [Known issues](#known-issues)
- [Developer documentation](#developer-documentation)
- [License](#mit-license)

## Installation

Note: If you encounter problems with the installation, ask for help from the developer community in our [developer chatroom](https://www.flowdock.com/invitations/de227bdbe48d24c31a6b749933d3b4eca82e307c). When you join, please use threads. Instructions for this and other chat-related things can be found at [Flowdock's chat instructions](https://www.flowdock.com/help/chat).

### Requirements

Before you get started, the following needs to be installed:
  * **Ruby**. Version 2.1.2 is currently used and we don't guarantee everything works with other versions. If you need multiple versions of Ruby, [RVM](https://rvm.io//) is recommended.
  * [**RubyGems**](http://rubygems.org/)
  * **Bundler**: `gem install bundler`
  * [**Git**](http://help.github.com/git-installation-redirect)
  * **A database**. Only MySQL has been tested, so we give no guarantees that other databases (e.g. PostgreSQL) work. You can install MySQL Community Server two ways:
    1. If you are on a Mac, use homebrew: `brew install mysql` (*highly* recommended). Also consider installing the [MySQL Preference Pane](https://dev.mysql.com/doc/refman/5.1/en/osx-installation-prefpane.html) to control MySQL startup and shutdown. It is packaged with the MySQL downloadable installer, but can be easily installed as a stand-alone.
    2. Download a [MySQL installer from here](http://dev.mysql.com/downloads/mysql/)
  * [**Sphinx**](http://pat.github.com/ts/en/installing_sphinx.html). Version 2.1.4 has been used successfully, but newer versions should work as well. Make sure to enable MySQL support. If you're using OS X and have Homebrew installed, install it with `brew install sphinx --with-mysql`
  * [**Imagemagick**](http://www.imagemagick.org). If you're using OS X and have Homebrew installed, install it with `brew install imagemagick`

### Setting up the development environment

1. Get the code. Cloning this git repo is probably easiest way:

  ```bash
  git clone git://github.com/sharetribe/sharetribe.git
  ```

1. Navigate to the Sharetribe project root directory.
1. Create a database.yml file by copying the example database configuration:

  ```bash
  cp config/database.example.yml config/database.yml
  ```

1. Create the required databases with [these commands](https://gist.github.com/804314).
1. Add your database configuration details to `config/database.yml`. You will probably only need to fill in the password for the database(s).
1. Install the required gems by running the following command in the project root directory:

  ```bash
  bundle install
  ```

1. Initialize your database:

  ```bash
  bundle exec rake db:schema:load
  ```

1. Run Sphinx index:

  ```bash
  bundle exec rake ts:index
  ```

1. Stat the Sphinx daemon:

  ```bash
  bundle exec rake ts:start
  ```

1. Use [Mailcatcher](http://mailcatcher.me) to receive sent emails locally:
    1. Install Mailcatcher:

        ```bash
        gem install mailcatcher
        ```

    1. Start it:

        ```bash
        mailcatcher
        ```

    1. Create a `config/config.yml` file and add the following lines to it:

        ```yml
        development:
          mail_delivery_method: smtp
          smtp_email_address: "localhost"
          smtp_email_port: 1025
        ```

    1. Open `http://localhost:1080` in your browser
1. Invoke the delayed job worker:

  ```bash
  bundle exec rake jobs:work
  ```

1. In a new console, open the project root folder and start the server. The simplest way is to use the included Webrick server:

  ```bash
  bundle exec rails server
  ```


Congratulations! Sharetribe should now be up and running for development purposes. Open a browser and go to the server URL (e.g. http://lvh.me:3000). Fill in the form to create a new marketplace and admin user. You should be now able to access your marketplace and modify it from the admin area.

### Database migrations

To update your local database schema to the newest version, run database migrations with:

  ```bash
  bundle exec rake db:migrate
  ```

### Running tests

Tests are handled by [RSpec](http://rspec.info/) for unit tests and [Cucumber](https://cucumber.io/) for acceptance tests.

1. Navigate to the root directory of the sharetribe project
1. Initialize your test database:

  ```bash
  bundle exec rake test:prepare
  ```

  This needs to be rerun whenever you make changes to your database schema.
1. If Zeus isn't running, start it:

  ```bash
  zeus start
  ```

1. To run unit tests, open another terminal and run:
  ```bash
  zeus rspec spec
  ```

1. To run acceptance tests, open another terminal and run:

  ```bash
  zeus cucumber
  ```

  Note that running acceptance tests is slow and may take a long time to complete.

To automatically run unit tests when code is changed, start [Guard](https://github.com/guard/guard):

  ```bash
  bundle exec guard
  ```

### Setting up Sharetribe for production

Before starting these steps, perform [steps 1-6 from above](#setting-up-the-development-environment).

1. Initialize your database:

  ```bash
  bundle exec rake RAILS_ENV=production db:schema:load
  ```

1. Run Sphinx index:

  ```bash
  bundle exec rake RAILS_ENV=production ts:index
  ```

1. Start the Sphinx daemon:

  ```bash
  bundle exec rake RAILS_ENV=production ts:start
  ```

1. Precompile the assets:

  ```bash
  bundle exec rake assets:precompile
  ```

1. Invoke the delayed job worker:

  ```bash
  bundle exec rake RAILS_ENV=production jobs:work
  ```

1. In a new console, open the project root folder and start the server:

  ```bash
  bundle exec rails server -e production
  ```


The built-in WEBrick server (which was started in the last step above) should not be used in production due to performance reasons. A dedicated HTTP server such as [unicorn](http://unicorn.bogomips.org/) is recommended.

It is also not recommended to serve static assets from a Rails server in production. Instead, you should serve assets from Amazon S3 or use an Apache/Nginx server. In this case, you'll need to set the value of `serve_static_assets_in_production` to `false` in `config/config.yml`.

#### Setting your domain

1. In your database, change the value of the `domain` column in the `communities` table to match the hostname of your domain. For example, if the URL for your marketplace is http://mymarketplace.myhosting.com, then the domain is `mymarketplace.myhosting.com`.

1. Change the value of the `use_domain` column to `true` (or `1`) in the `communities` table.

### Advanced settings

Default configuration settings are stored in `config/config.default.yml`. If you need to change these, we recommend creating a `config/config.yml` file to override these values. You can also set configuration values to environment variables.

### Unofficial installation instructions

Use these instructions to set up and deploy Sharetribe for production in different environments. They have been put together by the developer community, and are not officially maintained by the Sharetribe core team. The instructions might be somewhat out of date.

If you have installation instructions that you would like to share, don't hesitate to [contact the team](https://www.flowdock.com/invitations/de227bdbe48d24c31a6b749933d3b4eca82e307c).

- [Deploying Sharetribe to Heroku](https://gist.github.com/svallory/d08e9baa88e18d691605) by [svallory](https://github.com/svallory)


## Payments

Sharetribe's open source version supports payments using [Braintree Marketplace](https://www.braintreepayments.com/features/marketplace). To enable payments with Braintree, you need to have a legal business in the United States. You can sign up for Braintree [here](https://signups.braintreepayments.com/). Once that's done, create a new row in the payment gateways table with your Braintree merchant_id, master_merchant_id, public_key, private_key and client_side_encryption_key.

PayPal payments are only available on marketplaces hosted at [Sharetribe.com](https://www.sharetribe.com) due to special permissions needed from PayPal. We hope to add support for PayPal payments to the open source version of Sharetribe in the future.


## Updating

See [release notes](RELEASE_NOTES.md) for information about what has changed and if actions are needed to upgrade.


## Technical roadmap

For a better high-level understanding of what the Sharetribe core team is working on currently and what it plans to work on next, read the [technical roadmap](TECHNICAL_ROADMAP.md).


## Contributing

Would you like to make Sharetribe better? [Follow these steps](CONTRIBUTING.md).


## Translation

Sharetribe uses [WebTranslateIt (WTI)](https://webtranslateit.com/en) for translations. If you'd like to translate Sharetribe to your language or improve existing translations, please ask for a WTI invitation. To get an invite, send an email to [info@sharetribe.com](mailto:info@sharetribe.com) and mention that you would like to become a translator.

All language additions and modifications (except for English) should be done through the WTI tool. We do not accept Pull Requests that add or modify languages (except English).


## Known issues

Browse open issues and submit new ones at http://github.com/sharetribe/sharetribe/issues.


## Developer documentation

* [Testing](docs/testing.md)
* [SCSS coding guidelines](docs/scss-coding-guidelines.md)
* [Delayed job priorities](docs/delayed-job-priorities.md)
* [Cucumber testing Do's and Don'ts](docs/cucumber-do-dont.md)
* [Technical roadmap](TECHNICAL_ROADMAP.md)


## MIT License

Sharetribe is open source under the MIT license. See [LICENSE](LICENSE) for details.
