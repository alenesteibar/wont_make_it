require "rails_helper"

RSpec.describe "BusController", type: :request do
  let(:tmb_url) { "https://api.tmb.cat/v1/ibus/stops/822" }

  let(:api_response) do
    {
      status: "success",
      data: {
        ibus: [
          { line: "33", destination: "Verneda",            "t-in-min": 9  },
          { line: "6",  destination: "Poblenou",           "t-in-min": 13 },
          { line: "63", destination: "Pl.Catalunya",       "t-in-min": 15 },
          { line: "6",  destination: "Pg. Manuel Girona",  "t-in-min": 25 }
        ]
      }
    }.to_json
  end

  before do
    stub_request(:get, tmb_url)
      .with(query: hash_including("app_id", "app_key"))
      .to_return(status: 200, body: api_response, headers: { "Content-Type" => "application/json" })
  end

  describe "GET /" do
    it "returns http success" do
      get root_path
      expect(response).to have_http_status(:success)
    end

    it "shows line 6 arrival times" do
      get root_path
      expect(response.body).to include("13")
      expect(response.body).to include("25")
    end

    it "shows line 6 destinations" do
      get root_path
      expect(response.body).to include("Poblenou")
      expect(response.body).to include("Pg. Manuel Girona")
    end

    it "does not show arrivals from other lines" do
      get root_path
      expect(response.body).not_to include("Verneda")
      expect(response.body).not_to include("Pl.Catalunya")
    end

    context "when the API returns no line 6 buses" do
      let(:api_response) do
        { status: "success", data: { ibus: [
          { line: "33", destination: "Verneda", "t-in-min": 5 }
        ] } }.to_json
      end

      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "shows the empty state message" do
        get root_path
        expect(response.body).to include("No arrivals data available")
      end
    end

    context "when the API call raises a network error" do
      before do
        stub_request(:get, tmb_url)
          .with(query: hash_including("app_id", "app_key"))
          .to_raise(StandardError)
      end

      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "shows the empty state message" do
        get root_path
        expect(response.body).to include("No arrivals data available")
      end
    end

    context "when the API returns a non-200 status" do
      before do
        stub_request(:get, tmb_url)
          .with(query: hash_including("app_id", "app_key"))
          .to_return(status: 503, body: "", headers: {})
      end

      it "returns http success" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "shows the empty state message" do
        get root_path
        expect(response.body).to include("No arrivals data available")
      end
    end
  end
end
