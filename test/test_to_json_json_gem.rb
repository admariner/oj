#!/usr/bin/env ruby
# frozen_string_literal: true

# The json gem is loaded before Oj on purpose. Time, Date, Symbol, and the
# other core classes then answer to_json with the json gem's generator, which
# is what Oj.dump calls in compat mode with use_to_json. That generator raises
# ArgumentError on options it does not know as of json 3.0, so the Oj options
# that Oj.dump was given must not reach it. Kept in its own file because
# loading the json gem changes what every other compat test would dump.

$LOAD_PATH << __dir__
@oj_dir = File.dirname(File.expand_path(__dir__))
%w(lib ext).each do |dir|
  $LOAD_PATH << File.join(@oj_dir, dir)
end

require 'minitest'
require 'minitest/autorun'
require 'json'
require 'oj'

class ToJsonJsonGemJuice < Minitest::Test

  def setup
    @default_options = Oj.default_options
  end

  def teardown
    Oj.default_options = @default_options
  end

  def test_dump_time_compat_use_to_json
    t = Time.at(1_355_218_745).utc
    json = Oj.dump(t, :mode => :compat, :use_to_json => true, :time_format => :ruby)
    assert_equal('"2012-12-11 09:39:05 UTC"', json)
  end

  def test_dump_time_compat_use_to_json_with_json_gem_options
    t = Time.at(1_355_218_745).utc
    json = Oj.dump(t, :mode => :compat, :use_to_json => true, :indent => '  ', :allow_nan => true, :max_nesting => 10)
    assert_equal('"2012-12-11 09:39:05 UTC"', json)
  end

  def test_dump_nested_time_compat_use_to_json
    t = Time.at(1_355_218_745).utc
    json = Oj.dump({ 'at' => t, 'sym' => :abc }, :mode => :compat, :use_to_json => true, :time_format => :ruby)
    assert_equal('{"at":"2012-12-11 09:39:05 UTC","sym":"abc"}', json)
  end

  # use_to_json only gates the top level value. Nested values always reach
  # to_json, so a Time inside an Array raised even without the option.
  def test_dump_nested_time_compat_without_use_to_json
    t = Time.at(1_355_218_745).utc
    json = Oj.dump([t], :mode => :compat, :time_format => :ruby)
    assert_equal('["2012-12-11 09:39:05 UTC"]', json)
  end

  def test_dump_time_custom_use_to_json
    t = Time.at(1_355_218_745).utc
    json = Oj.dump(t, :mode => :custom, :use_to_json => true, :omit_nil => true)
    assert_equal('"2012-12-11 09:39:05 UTC"', json)
  end

  def test_dump_time_default_options_use_to_json
    Oj.default_options = { :mode => :compat, :use_to_json => true, :time_format => :ruby }
    t = Time.at(1_355_218_745).utc
    assert_equal('"2012-12-11 09:39:05 UTC"', Oj.dump(t))
    assert_equal('"2012-12-11 09:39:05 UTC"', Oj.dump(t, :allow_nan => true))
  end
end
