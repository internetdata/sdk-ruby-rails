# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff.

## 1.1.2 - 2026-11-28

### Features

- Require internetdata 2.20.0: allow_bots sends only a crawler's User-Agent, at most four an address ([`d0b1356`](https://github.com/internetdata/sdk-ruby-rails/commit/d0b1356d7198a0301568469518acc3ef7da45850))

## 1.1.1 - 2026-11-26

### Features

- Require internetdata 2.19.0: a keyless answer is read without the bot, carrier, satellite and service flags ([`398b508`](https://github.com/internetdata/sdk-ruby-rails/commit/398b5088060a9dabd7d16de8dbc4fe1b93ed6fce))

## 1.1.0 - 2026-11-25

### Features

- Require internetdata 2.18.0: a lookup can send the request's user agent ([`f248ae0`](https://github.com/internetdata/sdk-ruby-rails/commit/f248ae018751a05b1ea2a33aa271fb6d3f4dbd6f))
- allow_bots: let a crawler its operator vouches for through ([`147e812`](https://github.com/internetdata/sdk-ruby-rails/commit/147e812c31688f760b2a5f8c16bd489e1a8614c1))

## 1.0.7 - 2026-11-24

### Features

- Require internetdata 2.17.0: a condition on a list member matches when any element does ([`f078f6a`](https://github.com/internetdata/sdk-ruby-rails/commit/f078f6a7de06d3274a240dfcea8a72a79168be02))

## 1.0.6 - 2026-11-23

### Fixes

- Require internetdata 2.16.1, on spec 2026.11.22 ([`433ca64`](https://github.com/internetdata/sdk-ruby-rails/commit/433ca64f85e9cad016a56dc5de008c222a60f73e))

## 1.0.5 - 2026-11-22

### Features

- Require internetdata 2.16.0: whether a bot uses an address, and whose ([`c1a8535`](https://github.com/internetdata/sdk-ruby-rails/commit/c1a85353cf6d2f50e66579cc15db8ff6b0ba3a4e))

## 1.0.4 - 2026-11-20

### Features

- Require internetdata 2.15.0: a paid domain answer's hosting, co-hosted domains, home page, redirects and backlinks ([`44e3c68`](https://github.com/internetdata/sdk-ruby-rails/commit/44e3c6813a8f5ffe0d8abd8a4999c38abd657f8d))

## 1.0.3 - 2026-11-20

### Fixes

- Require internetdata 2.14.3: its docs no longer give the trial a count ([`5d1cdfa`](https://github.com/internetdata/sdk-ruby-rails/commit/5d1cdfafc6c33fd5f2774cf3d4b0681edbe0335b))

## 1.0.2 - 2026-11-19

### Fixes

- README: the gem needs libcurl at runtime ([`e9d7868`](https://github.com/internetdata/sdk-ruby-rails/commit/e9d7868db87b0e9d2e97ce7dc70d8ddcc7031077))
- Require internetdata 2.14.2: a reduced answer is cached a minute at most ([`9339e38`](https://github.com/internetdata/sdk-ruby-rails/commit/9339e38d880f72e69be2ab8c16be6200cbe4697d))

## 1.0.1 - 2026-11-14

### Fixes

- Require internetdata 2.11.1: a 403 can mean the key lacks the ip.lookup scope ([`9641381`](https://github.com/internetdata/sdk-ruby-rails/commit/9641381a97e9d015377041e769a73448ccbb827a))

## 1.0.0 - 2026-11-14

### Features

- Attach the visitor's InternetData record to every request, read with `InternetData::Rails.lookup(request)`: the location, the network and the company behind the address, and the anonymity and hosting flags your plan serves ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Refuse a request with a `block_condition` in `config.internetdata`, written in the shape of the answer, by country, network type, anonymity or any other member, with 403 or an `on_blocked` of your own ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Insert it after Rails' own `RemoteIp` with the Railtie, or as Rack middleware in Sinatra, Hanami or Roda ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Choose where the client address comes from: Rails' `remote_ip` by default and Rack's `ip` outside Rails, `xff_ip_selector`, `header_ip_selector` for a header your edge writes, or a callable of your own, with a warning once when the default can be forged ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Fail open on any lookup failure unless `fail_closed` is set, with a 2.5 s bound, no retry and a cache by default ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
