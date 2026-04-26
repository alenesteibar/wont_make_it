require "net/http"
require "json"

class BusController < ApplicationController
  STOP_ID = "822"
  LINES   = %w[6 33 34 7].freeze
  API_URL = "https://api.tmb.cat/v1/ibus/stops/#{STOP_ID}"

  def index
    @stop = fetch_stop
  end

  private

  def fetch_stop
    buses = fetch_stop_data
    { stop_id: STOP_ID, lines: group_by_line(buses) }
  rescue StandardError
    { stop_id: STOP_ID, lines: group_by_line([]) }
  end

  def group_by_line(buses)
    LINES.map { |line| { line: line, arrivals: arrivals_for_line(buses, line) } }
  end

  def arrivals_for_line(buses, line)
    buses
      .select { |bus| bus["line"] == line }
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
