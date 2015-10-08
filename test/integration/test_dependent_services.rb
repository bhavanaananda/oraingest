require "test/unit"
require_relative '../test_helper'
require "net/http"
require 'open3'


class TestDependentServices < Test::Unit::TestCase

  def setup

    case Rails.env

    when "development"
      @port = 8080
    when "test"
      @port = ENV['JETTY_PORT']
    end

  end

  # def test_java_is_installed

  #   stdin, stdout, stderr = Open3.popen3('java -version')
  #   refute(stderr.read.empty?)
  # end

  # def test_apache_is_running
  #   stdin, stdout, stderr = Open3.popen3('sudo service apache2 status')
  #   assert_not_nil(stdout.read.match /apache2 is running/)
  # end

  # def test_tomcat_is_running
  #   stdin, stdout, stderr = Open3.popen3('sudo service tomcat7 status')
  #   assert_not_nil(stdout.read.match /Tomcat servlet engine is running/)
  # end

  # def test_solr_is_running
  #   uri = URI.parse("http://127.0.0.1:#{@port}/solr/#/#{Rails.env}")
  #   res = Net::HTTP.get_response(uri)
  #   assert(res.is_a? Net::HTTPOK)
  # end

  # def test_fedora_is_running
  #   uri = URI.parse("http://127.0.0.1:#{@port}/solr/#/#{Rails.env}")
  #   res = Net::HTTP.get_response(uri)
  #   assert(res.is_a? Net::HTTPOK)
  # end

  def test_rails_is_running
    uri = URI.parse("http://127.0.0.1:3000")
    res = Net::HTTP.get_response(uri)
    assert(res.is_a? Net::HTTPOK)
  end


  def teardown
  end
end
