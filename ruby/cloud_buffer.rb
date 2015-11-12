# coding: UTF-8
require 'rubygems'
require 'rest-client'
require "delegate"
require 'logger'
require 'json'

module VimCloudBuffer

  class Gateway

    def initialize url, api_key, options = {}
      RestClient.log = Logger.new $stderr if options[:debug]
      headers   = { params: { apiKey: api_key }, accept: :json, content_type: :json }
      @resource = RestClient::Resource.new url, headers: headers, timeout: 5
    end

    def add data
      @resource.post data.to_json
    end

    def update id, data
      @resource[id].put data.to_json
    end

    def get id
      @resource[id].get
    end

    def list
      @resource.get
    end

    def find
      raise "Not implemented!"
    end

    def remove id
      @resource[id].delete
    end

  end

  class VimGateway < DelegateClass(Gateway)

    def initialize
      url     = ENV.fetch('CLOUD_BUFFER_URL')     { VIM.evaluate "g:vim_cloud_buffer_url" }
      api_key = ENV.fetch('CLOUD_BUFFER_API_KEY') { VIM.evaluate "g:vim_cloud_buffer_api_key" }
      super Gateway.new url, api_key
    end

    def add
      send_data super get_data
    end

    def update id
      send_data super id, get_data
    end

    def get id
      send_data super
    end

    def list
      send_data super
    end

    def find
      raise "Not implemented!"
    end

    def remove id
      send_data super
    end

    private

    def send_data response
      VIM.command "unlet! g:vim_cloud_buffer_data"
      VIM.command "let g:vim_cloud_buffer_data=#{response}"
      response
    end

    def get_data
      data = VIM.evaluate "g:vim_cloud_buffer_data"
      data['content'].force_encoding 'UTF-8'
      data
    end

  end

  class SafeProxy < BasicObject

    def initialize &loader
      @loader = loader
      @object = nil
    end

    def method_missing name, *args, &block
      begin
        @object ||= @loader.call
        @object.public_send name, *args, &block
      rescue ::RestClient::Exception => e
        message = ::JSON.parse(e.response)['message'] || e.message
        ::VIM.command "let v:errmsg='#{message}'"
        ::Kernel.raise e
      rescue ::Exception => e
        ::VIM.command "let v:errmsg='#{e.message}'"
        ::Kernel.raise e
      end
    end

    def inspect
      "SafeProxy(#{@object.inspect})"
    end

    def __object__
      @object
    end

  end

  def self.gw
    @gw ||= SafeProxy.new { VimGateway.new }
  end

  if __FILE__ == $0
    require 'yaml'

    url     = ENV.fetch('CLOUD_BUFFER_URL')     { fail "Set CLOUD_BUFFER_URL on your environment" }
    api_key = ENV.fetch('CLOUD_BUFFER_API_KEY') { fail "Set CLOUD_BUFFER_API_KEY on your environment" }
    client  = Gateway.new url, api_key, debug: true

    buffer = JSON.parse client.add content: 'Foo ñ'
    id     = buffer['_id']['$oid']

    buffer['content'] = 'こんにちは 世界'
    client.update id, buffer
    client.get id
    JSON.parse(client.list).each { |buffer| client.remove buffer['_id']['$oid'] }

    puts JSON.parse(client.list).to_yaml
  end

end
