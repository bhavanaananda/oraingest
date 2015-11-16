require 'uri'

module Qa::Authorities
  class WebService

    def get_json(url)
      r = RestClient.get url, {accept: :json}
      JSON.parse(r)
    end

  end

end