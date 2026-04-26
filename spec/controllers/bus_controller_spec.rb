require "rails_helper"

RSpec.describe "BusController", type: :request do
  let(:stop_822_url)  { "https://api.tmb.cat/v1/ibus/stops/822" }
  let(:stop_1099_url) { "https://api.tmb.cat/v1/ibus/stops/1099" }
  let(:stop_136_url)  { "https://api.tmb.cat/v1/ibus/stops/136" }
  let(:stop_3257_url) { "https://api.tmb.cat/v1/ibus/stops/3257" }

  let(:stop_822_response) do
    { status: "success", data: { ibus: [
      { line: "6",   destination: "Poblenou",          "t-in-min": 13 },
      { line: "6",   destination: "Pg. Manuel Girona", "t-in-min": 25 },
      { line: "33",  destination: "Verneda",           "t-in-min": 9  },
      { line: "34",  destination: "Pl.Catalunya",      "t-in-min": 6  },
      { line: "7",   destination: "La Pau",            "t-in-min": 3  },
      { line: "63",  destination: "Diagonal",          "t-in-min": 15 }
    ] } }.to_json
  end

  let(:stop_1099_response) do
    { status: "success", data: { ibus: [
      { line: "H8", destination: "Aeroport T1", "t-in-min": 8 }
    ] } }.to_json
  end

  let(:stop_136_response) do
    { status: "success", data: { ibus: [
      { line: "D40", destination: "Can Cuiàs", "t-in-min": 4 }
    ] } }.to_json
  end

  let(:stop_3257_response) do
    { status: "success", data: { ibus: [
      { line: "6", destination: "Poblenou", "t-in-min": 7 }
    ] } }.to_json
  end

  before do
    stub_request(:get, stop_822_url)
      .with(query: hash_including("app_id", "app_key"))
      .to_return(status: 200, body: stop_822_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, stop_1099_url)
      .with(query: hash_including("app_id", "app_key"))
      .to_return(status: 200, body: stop_1099_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, stop_136_url)
      .with(query: hash_including("app_id", "app_key"))
      .to_return(status: 200, body: stop_136_response, headers: { "Content-Type" => "application/json" })

    stub_request(:get, stop_3257_url)
      .with(query: hash_including("app_id", "app_key"))
      .to_return(status: 200, body: stop_3257_response, headers: { "Content-Type" => "application/json" })
  end

  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "shows all configured stop numbers" do
      get root_path
      expect(response.body).to include("Stop 822")
      expect(response.body).to include("Stop 1099")
      expect(response.body).to include("Stop 136")
      expect(response.body).to include("Stop 3257")
    end

    it "shows arrivals for line 6 at stop 822" do
      get root_path
      expect(response.body).to include("Poblenou")
      expect(response.body).to include("13")
    end

    it "shows arrivals for line 33 at stop 822" do
      get root_path
      expect(response.body).to include("Verneda")
      expect(response.body).to include("9")
    end

    it "shows arrivals for H8 at stop 1099" do
      get root_path
      expect(response.body).to include("Aeroport T1")
      expect(response.body).to include("8")
    end

    it "shows arrivals for D40 at stop 136" do
      get root_path
      expect(response.body).to include("Can Cuiàs")
      expect(response.body).to include("4")
    end

    it "does not show arrivals from unconfigured lines" do
      get root_path
      expect(response.body).not_to include("Diagonal")
    end

    context "when one stop API call fails" do
      before do
        stub_request(:get, stop_1099_url)
          .with(query: hash_including("app_id", "app_key"))
          .to_raise(StandardError)
      end

      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "still shows data for other stops" do
        get root_path
        expect(response.body).to include("Stop 822")
        expect(response.body).to include("Poblenou")
      end

      it "shows the empty state for the failed stop" do
        get root_path
        expect(response.body).to include("No arrivals data available")
      end
    end

    context "when a stop returns no buses for a configured line" do
      let(:stop_822_response) do
        { status: "success", data: { ibus: [
          { line: "33", destination: "Verneda", "t-in-min": 5 }
        ] } }.to_json
      end

      it "shows the empty state for that line" do
        get root_path
        expect(response.body).to include("No arrivals data available")
      end

      it "still shows arrivals for lines that have data" do
        get root_path
        expect(response.body).to include("Verneda")
      end
    end
  end
end
