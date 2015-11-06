require 'rubygems'
require 'rest-client'

module VimCloudBuffer
  class Client

    def initialize
      api_key = VIM.evaluate "g:vim_cloud_buffers_api_key"
      url = VIM.evaluate "g:vim_cloud_buffers_url"
      headers = { params: { apiKey: api_key }, accept: :json, content_type: :json }
      @resource = RestClient::Resource.new url, headers: headers
      @data = VIM.evaluate "g:vim_cloud_buffer_data"
    end

    def add data=@data
      yield_to_vim @resource.post data.to_json
    end

    def update id, data=@data
      yield_to_vim @resource[id].put data.to_json
    end

    def get id
      yield_to_vim @resource[id].get
    end

    def list
      yield_to_vim @resource.get
    end

    def find
      raise "Not implemented!"
    end

    def remove id
      yield_to_vim @resource[id].delete
    end

    private

    def yield_to_vim response
      # return response if __FILE__ == $0
      VIM.command "unlet! g:vim_cloud_buffer_data"
      VIM.command "let g:vim_cloud_buffer_data=#{response}"
    end

  end
end

# RestClient.log = Logger.new $stderr
# require 'json'
# if __FILE__ == $0
#   RestClient.log = Logger.new $stderr
#   client = VimCloudBuffer::Client.new
#
#   buffer = JSON.parse client.add content: 'Foo'
#   id = buffer['_id']['$oid']
#
#   buffer['content'] = 'Bar'
#   client.update id, buffer
#   client.get id
#   JSON.parse(client.list).each { |buffer| client.remove buffer['_id']['$oid'] }
#
#   puts JSON.parse(client.list).to_yaml
# end
