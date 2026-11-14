# frozen_string_literal: true

module InternetData
  module Rails
    # Inserts the middleware for a Rails app, configured from
    # `config.internetdata`.
    #
    # Placed right after Rails' own RemoteIp, so `request.ip` already means
    # what your `trusted_proxies` say it means, and before the router, so a
    # refusal costs no controller work.
    class Railtie < ::Rails::Railtie
      config.internetdata = ActiveSupport::OrderedOptions.new

      initializer 'internetdata.middleware' do |app|
        options = app.config.internetdata.to_h
        next if options.delete(:enabled) == false

        app.middleware.insert_after(
          ActionDispatch::RemoteIp, InternetData::Rails::Middleware, **options
        )
      end
    end
  end
end
