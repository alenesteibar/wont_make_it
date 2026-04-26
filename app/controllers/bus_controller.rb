require "net/http"
require "json"

class BusController < ApplicationController
  STOPS = {
    "822"  => %w[6 33 34 7],
    "1099" => %w[H8],
    "136"  => %w[D40],
    "3257" => %w[6]
  }.freeze

  API_BASE_URL = "https://api.tmb.cat/v1/ibus/stops"

  def index
    @stops = fetch_all_stops
  end

  private

  def fetch_all_stops
    STOPS.map { |stop_id, lines| fetch_stop(stop_id, lines) }
  end

  def fetch_stop(stop_id, lines)
    buses = fetch_stop_data(stop_id)
    { stop_id: stop_id, lines: group_by_line(buses, lines) }
  rescue StandardError
    { stop_id: stop_id, lines: group_by_line([], lines) }
  end

  def group_by_line(buses, lines)
    lines.map { |line| { line: line, arrivals: arrivals_for_line(buses, line) } }
  end

  def arrivals_for_line(buses, line)
    buses
      .select { |bus| bus["line"] == line }
      .map { |bus| { minutes: bus["t-in-min"], destination: bus["destination"] } }
  end

  def fetch_stop_data(stop_id)
    uri = stop_uri(stop_id)
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) { |h| h.get(uri.request_uri) }
    JSON.parse(response.body).dig("data", "ibus") || []
  end

  def stop_uri(stop_id)
    uri = URI("#{API_BASE_URL}/#{stop_id}")
    uri.query = URI.encode_www_form(app_id: ENV["TMB_APP_ID"], app_key: ENV["TMB_APP_KEY"])
    uri
  end
end
