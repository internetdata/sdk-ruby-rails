# frozen_string_literal: true

require_relative 'test_helper'
require 'rails'
require 'action_controller/railtie'
require 'rack/mock_request'
# Loaded here because test_helper required the gem before Rails was defined.
require 'internetdata/rails/railtie'

# The Railtie, booted as an app configures it. Every other test builds the
# middleware by hand, so a key dropped on its way from `config.internetdata`
# passed them all.
class RailtieTest < Minitest::Test
  include TestHelper

  GOOGLEBOT = 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'
  WARNINGS = []

  class App < ::Rails::Application
    config.eager_load = false
    config.logger = Logger.new(nil)
    config.secret_key_base = 'x' * 64
    config.hosts.clear
    config.internetdata = {
      client: InternetData::Client.new(cache: false, retries: 0),
      ip_selector: InternetData::Rails.header_ip_selector('X-Visitor'),
      block_condition: { location: { country: %w[CU IR AT] } },
      allow_bots: true,
      on_warn: ->(message) { WARNINGS << message },
    }
    routes.append { root to: ->(_env) { [200, {}, ['handler ran']] } }
  end
  App.initialize!

  def teardown
    Typhoeus::Expectation.clear
  end

  def test_the_configured_condition_reaches_the_middleware
    calls = stub_lookups(
      '45.83.91.1' => { body: answer('45.83.91.1') },
      '45.83.91.2' => { body: answer('45.83.91.2', 'location' => germany) },
    )
    blocked = Rack::MockRequest.new(App).get('/', 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_X_VISITOR' => '45.83.91.1')
    allowed = Rack::MockRequest.new(App).get('/', 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_X_VISITOR' => '45.83.91.2')

    assert_equal 403, blocked.status
    assert_equal 200, allowed.status
    assert_equal 'handler ran', allowed.body
    assert_equal 2, calls.length
  end

  def germany
    answer('45.83.91.2').fetch('location').merge('country' => 'DE', 'country_name' => 'Germany')
  end

  # `allow_bots` from config.internetdata: the request's own User-Agent reaches
  # the API, and a verified crawler passes the condition it meets.
  def test_allow_bots_reaches_the_middleware
    sent = []
    Typhoeus.stub(%r{\A#{Regexp.escape(BASE_URL)}/}).and_return do |request|
      agent = (request.options[:params] || {}).transform_keys(&:to_s)['user_agent']
      ip = address_of(request)
      sent << [ip, agent]
      verdict = ip == '45.83.91.3' ? 'verified' : 'spoofed'
      json_response(200, answer(ip, 'user_agent' => { 'agent' => 'Googlebot', 'kind' => 'bot', 'verdict' => verdict }))
    end
    headers = { 'REMOTE_ADDR' => '127.0.0.1', 'HTTP_USER_AGENT' => GOOGLEBOT }
    verified = Rack::MockRequest.new(App).get('/', headers.merge('HTTP_X_VISITOR' => '45.83.91.3'))
    spoofed = Rack::MockRequest.new(App).get('/', headers.merge('HTTP_X_VISITOR' => '45.83.91.4'))

    assert_equal [['45.83.91.3', GOOGLEBOT], ['45.83.91.4', GOOGLEBOT]], sent
    assert_equal 200, verified.status
    assert_equal 'handler ran', verified.body
    assert_equal 403, spoofed.status
  end

  # The README's Rails form, `config.internetdata = { api_key: ENV[...] }` and
  # nothing else, with the key set and unset. The tests above hand the Railtie a
  # `client:`, so a key it dropped on the way to the middleware passed them all.
  # The Railtie's own initializer runs against a Rails middleware stack, since a
  # second booted application in this process fails on the first one's frozen
  # load paths. 45.83.91.1 is a public peer: a loopback or documentation address
  # is a bogon, answered locally without a request.
  def test_the_readme_form_sends_its_key_and_without_one_sends_none
    saved = InternetData::Rails::Railtie.config.internetdata
    saved_key = ENV.fetch('INTERNETDATA_API_KEY', nil)
    [['k_readme', 'Bearer k_readme'], [nil, nil]].each do |key, header|
      seen = []
      Typhoeus.stub(%r{\A#{Regexp.escape(BASE_URL)}/}).and_return do |request|
        seen << request.options[:headers]['Authorization']
        json_response(200, answer('45.83.91.1'))
      end
      ENV['INTERNETDATA_API_KEY'] = key
      config = ::Rails::Railtie::Configuration.new
      config.internetdata = { api_key: ENV['INTERNETDATA_API_KEY'] }
      stack = ActionDispatch::MiddlewareStack.new
      stack.use ActionDispatch::RemoteIp
      booting = Struct.new(:config, :middleware).new(config, stack)
      InternetData::Rails::Railtie.instance.initializers.find { |i| i.name == 'internetdata.middleware' }.run(booting)

      response = Rack::MockRequest.new(stack.build(App.routes)).get('/', 'REMOTE_ADDR' => '45.83.91.1')

      assert_equal 'handler ran', response.body, key.inspect
      assert_equal [header], seen, "the one lookup carried #{header.inspect} for #{key.inspect}"
      Typhoeus::Expectation.clear
    end
  ensure
    ENV['INTERNETDATA_API_KEY'] = saved_key
    InternetData::Rails::Railtie.config.internetdata = saved
  end

  def test_it_sits_right_after_rails_own_remote_ip
    stack = App.middleware.map(&:klass)

    assert_equal stack.index(ActionDispatch::RemoteIp) + 1, stack.index(InternetData::Rails::Middleware)
  end
end
