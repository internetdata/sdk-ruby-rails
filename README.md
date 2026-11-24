# [<img src="https://s3.internetdata.io/internetdata-public/brand/mark.svg" alt="InternetData" height="28"/>](https://internetdata.io/) InternetData Rails Middleware

[![Gem](https://img.shields.io/gem/v/internetdata-rails.svg)](https://rubygems.org/gems/internetdata-rails)
[![license](https://img.shields.io/github/license/internetdata/sdk-ruby-rails.svg)](LICENSE)

The official [Rails](https://rubyonrails.org) middleware for the [InternetData](https://internetdata.io) API.

It looks up the visitor behind each request, where they are, which network they come from and whether it's a VPN, a proxy, Tor or a hosting server, and hands the answer to your controllers. Blocking is opt-in.

It is Rack middleware, so it works in Sinatra, Hanami, Roda or a bare Rack app too; the Railtie is only what saves a Rails user from inserting it by hand.

## Getting Started

```bash
bundle add internetdata-rails
```

Requires Ruby 3.3 or newer, and libcurl at runtime, which the `curl` package brings on Debian and Alpine. The Dockerfile Rails generates already installs it.

Without an API key a lookup is on Unlimited, the free plan: the country, the network and the company behind the address, Tor, relay, bot, anycast, carrier and satellite space and the service flags, with no daily or monthly cap. Every lookup your app makes comes from your server's one address, though, so a busy site will see bursts refused. A paid plan answers every field, VPN, the proxy flags, hosting, CDN and the city among them; create a key in the [console](https://app.internetdata.io). A free account tries every field.

```ruby
# config/application.rb
config.internetdata = { api_key: ENV["INTERNETDATA_API_KEY"] }
```

```ruby
class HomeController < ApplicationController
  def index
    result = InternetData::Rails.lookup(request)&.result
    render plain: "Hello, visitor from #{result&.location&.fetch("country_name") || "somewhere"}"
  end
end
```

In a non-Rails Rack app, insert it yourself:

```ruby
use InternetData::Rails::Middleware, api_key: ENV["INTERNETDATA_API_KEY"]
```

By default nothing is blocked. Every request gets an answer and your own code decides what it means: a currency to show, a sign-up to review, a page to keep from some countries.

## Blocking

Set a `block_condition` and a matching request is answered with `403` and never reaches your controllers.

```ruby
config.internetdata = {
  api_key: ENV["INTERNETDATA_API_KEY"],
  block_condition: { location: { country: %w[CU IR KP] } },
}
```

A condition is written in the shape of an answer, keyed by the same names the API uses, and only the members you name are considered, so it can refuse on anything in the answer. The country works on every plan, and so do the first three of these:

```ruby
{ asn: { type: "hosting" } }                                 # the network's type
[{ is_anycast: true }, { is_satellite: true }]               # anycast and satellite space
{ is_bot: true }                                             # crawlers, monitors and scanners
[{ is_hosting: true }, { is_cdn: true }]                     # traffic from servers, not people
[{ is_vpn: true }, { is_tor: true }, { is_resproxy: true }]  # anonymity: a list is OR
{ is_vpn: true, vpn: { provider: "nordvpn" } }               # one provider
{ resproxy: { hits: { gte: 5 } } }                           # a numeric threshold
```

Symbol and string keys both work. Values are matched by equality, strings without regard to case. An Array means any-of. A Hash of `gte`/`gt`/`lte`/`lt` compares numbers, and every bound you give must hold, so two of them are a range. A member the answer holds as a list, such as `pubproxy.protocols` or the `web` rows, matches when any element does, and a nested condition on one matches when every member of it matches the same element (`{ web: { port: 443 } }`). Members set to `false` or `nil` are ignored, so a condition states the signals you act on; one that constrains nothing would match every request, and is refused when the middleware is built rather than silently blocking all your traffic.

Replace the refusal with `on_blocked`, which returns a Rack triplet:

```ruby
on_blocked: ->(request, lookup) { [303, { "location" => "/unavailable" }, []] }
```

## Where the client address comes from

This is the setting that decides whether any of the above works, and it is the one thing only you can get right.

**In Rails**, the default reads `env["action_dispatch.remote_ip"]`, the answer `ActionDispatch::RemoteIp` computed from `X-Forwarded-For` minus your `config.action_dispatch.trusted_proxies`. That is the right fix behind a load balancer: tell Rails which proxies are yours and it resolves the visitor for you. Without it, and behind one, every visitor gets your proxy's country and network, and if it is a hosting address, a hosting rule blocks everyone. `Rack::Request#ip` does *not* read that entry, so reading Rails' own is what makes your `trusted_proxies` mean anything here. **With nothing in front of the app server, that default can be forged**: `RemoteIp` believes `X-Forwarded-For` without checking that the connection came from a proxy, so any visitor picks the address that gets looked up. There, pass `ip_selector: ->(request) { request.ip }`. The middleware warns once when it sees that setup: a request carrying `X-Forwarded-For`, `Client-IP` or `Forwarded` from a public address outside `trusted_proxies`.

**In a bare Rack app** there is no such entry and the default falls back to `Rack::Request#ip`. Rack's `ip` returns the connecting address, `REMOTE_ADDR`, unless that is a trusted proxy, which by default means a loopback or private address. Only then does it read the forwarding headers, and it takes the right-most entry that is not a trusted proxy. The test suite pins both. Behind an edge on a public address, or one that appends rather than overwrites, name your edge's header instead:

```ruby
ip_selector: InternetData::Rails.header_ip_selector("CF-Connecting-IP")
```

`InternetData::Rails.xff_ip_selector` reads `X-Forwarded-For` directly, and `xff_ip_selector(1)` counts one trusted hop from the right. Anything else, pass your own callable: it receives the Rack request and returns an address.

**Behind a proxy that writes only `X-Forwarded-For`, a visitor's own `Forwarded` header names the address.** Rack 3 reads `Forwarded` first, for `Rack::Request#ip` and Rails' `remote_ip` alike, and nginx passes a visitor's copy through untouched, so a request sending `Forwarded: for=1.1.1.1` is looked up as `1.1.1.1`. Clear the header at the proxy, `proxy_set_header Forwarded "";` in nginx, or tell Rack to read `X-Forwarded-For` alone at the top of `config.ru`:

```ruby
Rack::Request.forwarded_priority = [:x_forwarded]
```

The middleware warns once when a request through a proxy carries both headers. From Rails 8.1.4.1, `RemoteIp` itself refuses a request whose `Forwarded` and `X-Forwarded-For` name different visitors, raising `ActionDispatch::RemoteIp::IpSpoofAttackError`, a 400, and the middleware leaves that to Rails, as your own `remote_ip` call would.

If the address resolves to a private one, the middleware says so once. That is expected locally and is the signal to fix your configuration anywhere else.

## When a lookup fails

The request is let through, and the reason is on `lookup.error`. Our outage should not become yours, so a network failure, a rate limit or a rejected key all fail open. Pass `fail_closed: true` to block instead. Private addresses are answered locally and never fail, so this will not lock you out in development.

## Cost and latency

Answers are cached for an hour, so a returning visitor costs nothing, and private addresses never leave the process. A cache miss is one request to our API, bounded at 2.5 seconds by default and not retried: on a request path, failing open quickly beats holding a visitor while we try again.

Files in `public/`, compiled assets included, never reach the middleware: `ActionDispatch::Static` answers them first, so they cost no lookup. Skip the routes you do not care about:

```ruby
skip: ->(request) { request.path == "/up" || request.path.start_with?("/webhooks") }
```

Beyond a few million distinct visitors a day, stop calling the API per request: look addresses up locally in [our databases](https://internetdata.io/databases) instead.

## Absent is not false

Unlimited, with a key or without one, leaves out `is_vpn`, `is_hosting`, `is_cdn` and the four proxy flags, the detail behind them and `bot`, and the paid members inside `location`, `asn`, `company` and `abuse`, such as `location["city"]`. A member your plan does not include is `nil`, which means "not in your plan" rather than "checked, and no", and Ruby makes that easy to lose, since `nil` and `false` are both falsy.

```ruby
lookup.result.vpn?            # true or false, never nil
lookup.result.is_vpn          # nil when your plan does not include it
lookup.result.included?(:is_vpn)
```

A `block_condition` naming a member your plan does not serve, `location.city` on Unlimited included, can never match, so the middleware warns once instead of failing silently. Pass `on_missing_field: :raise` to make it an error.

## Other Libraries

There are official InternetData client libraries available for many languages including PHP, Python, Go, Java, and Ruby. See our GitHub at https://github.com/internetdata for more.

## About InternetData

Geolocation, anonymity, ownership, network, service and domain data for any IP address, AS or domain, by API or as databases you download.

[<picture><source media="(prefers-color-scheme: dark)" srcset="https://s3.internetdata.io/internetdata-public/brand/logo-dark.svg"><img src="https://s3.internetdata.io/internetdata-public/brand/logo.svg" alt="InternetData" height="40"/></picture>](https://internetdata.io/)

## License

This project is licensed under the [MIT License](LICENSE).
