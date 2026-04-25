require "net/http"
require "json"

class BusController < ApplicationController
  def index
    @arrivals = fetch_arrivals
  end

  private

  def fetch_arrivals
    uri = URI("https://api.tmb.cat/v1/transit/linies/bus/6/parades/822/temps-espera")
    uri.query = URI.encode_www_form(app_id: ENV["TMB_APP_ID"], app_key: ENV["TMB_APP_KEY"])

    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.get(uri.request_uri) }
    data = JSON.parse(response.body)

    data.dig("data", "atur", "linies", "linia")&.flat_map do |linia|
      Array(linia["vehicles"]).map { |v| v["temps"].to_i }
    end || []
  rescue StandardError
    []
  end
end
