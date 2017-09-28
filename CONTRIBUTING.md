# Contributing

## Overview

1. Fork it.
2. Checkout master branch.
3. Create a topic branch where you work on.
4. Write RSpec test what tests your feature and confirm that it fails.
5. Implement your feature.
6. Make `rubocop` quiet.
7. Run tests with `rake spec` and confirm that it passes.
8. Create a new pull request.

## Preparing for contribution

After [preparing for development](docs/DEVELOP_TEST_SUITES.md#prepare-for-development), setup a database for tests.

```bash
$ rake db:setup DB_ENV=test
```

In case you want to run tests on docker, execute command below.

```bash
$ docker-compose run --rm app bundle exec rake db:setup DB_ENV=test
```

## rubocop

We strictly follow [the Ruby Style Guide](https://github.com/bbatsov/ruby-style-guide), so we appreciate if you run `rubocop` before pull requests.

If you develop with RubyMine, [RuboCop inspection](https://www.jetbrains.com/help/ruby/rubocop.html) is useful.

## Running tests

It should be straightforward for Ruby developers.

```bash
$ rake spec
```

Or, run particular tests.

```bash
$ rspec spec/commands/new_feature_commands_spec.rb#123
```

If you want to run tests on docker, execute following commands.

```bash
$ docker-compose build && docker-compose run --rm app bundle exec rake spec
```
