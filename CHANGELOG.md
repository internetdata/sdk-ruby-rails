# Changelog

What each release changed for you, newest first. Each line is a commit's summary, linked to its full description and diff.

## 1.0.0 - 2026-11-14

### Features

- Attach the visitor's InternetData record to every request, read with `InternetData::Rails.lookup(request)`: the location, the network and the company behind the address, and the anonymity and hosting flags your plan serves ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Refuse a request with a `block_condition` in `config.internetdata`, written in the shape of the answer, by country, network type, anonymity or any other member, with 403 or an `on_blocked` of your own ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Insert it after Rails' own `RemoteIp` with the Railtie, or as Rack middleware in Sinatra, Hanami or Roda ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Choose where the client address comes from: Rails' `remote_ip` by default and Rack's `ip` outside Rails, `xff_ip_selector`, `header_ip_selector` for a header your edge writes, or a callable of your own, with a warning once when the default can be forged ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
- Fail open on any lookup failure unless `fail_closed` is set, with a 2.5 s bound, no retry and a cache by default ([`d76e466`](https://github.com/internetdata/sdk-ruby-rails/commit/d76e4661bc40a69abc2ac600a0ad0792a17836dd))
