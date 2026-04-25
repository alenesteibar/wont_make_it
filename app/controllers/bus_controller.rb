require "net/http"
require "json"

class BusController < ApplicationController
  STOP_ID = "822"
  LINE    = "6"
  API_URL = "https://api.tmb.cat/v1/ibus/stops/#{STOP_ID}"

  def index
    @arrivals = fetch_arrivals
  end

  private

  def fetch_arrivals
    filter_and_format(fetch_stop_data)
  rescue StandardError
    []
  end

  def filter_and_format(buses)
    buses
      .select { |bus| bus["line"] == LINE }
      .map { |bus| { minutes: bus["t-in-min"], destination: bus["destination"] } }
  end

  def fetch_stop_data
    response = Net::HTTP.start(api_uri.host, api_uri.port, use_ssl: true) { |h| h.get(api_uri.request_uri) }
    JSON.parse(response.body).dig("data", "ibus") || []
  end

  def api_uri
    uri = URI(API_URL)
    uri.query = URI.encode_www_form(app_id: ENV["TMB_APP_ID"], app_key: ENV["TMB_APP_KEY"])
    uri
  end
end
