require 'rails_helper'

RSpec.describe WeatherController, type: :controller do
  describe "POST #submit_address" do
    context "with blank address" do
      it "returns error message" do
        post :submit_address, params: { address: "" }, format: :turbo_stream
        expect(assigns(:error_message)).to eq("The address was blank")
      end
    end

    context "with valid address" do
      let(:valid_address) { { address: 'Scarsdale, NY' } }
      let(:latitude) { 40.7128 }
      let(:longitude) { -74.006 }

      before do
        location_data_file_path = Rails.root.join('spec', 'data', 'geocoded_location.json')
        location_data = File.read(location_data_file_path)
        allow(Geocoder).to receive(:search).and_return([double('GeocoderResult', coordinates: [latitude, longitude], data: location_data)])
        stub_request(:get, "http://api.geonames.org/timezoneJSON?lat=#{latitude}&lng=#{longitude}&username=weather_demo")
          .to_return(status: 200, body: {"sunrise":"2024-05-13 05:37","lng":-74,"countryCode":"US","gmtOffset":-5,"rawOffset":-5,"sunset":"2024-05-13 20:08","timezoneId":"America/New_York","dstOffset":-4,"countryName":"United States","time":"2024-05-13 08:56","lat":42}.to_json, headers: {})
        allow_any_instance_of(WeatherApiService).to receive(:current_weather).and_return('current_weather_mocked_response')
        allow_any_instance_of(WeatherApiService).to receive(:forecast).and_return('forecast_mocked_response')
      end

      it "fetches current weather and forecast" do
        post :submit_address, params: valid_address, format: :turbo_stream
        # weather_api_service_spec.rb tests the contents of these responses
        expect(assigns(:current_weather)).to eq('current_weather_mocked_response')
        expect(assigns(:forecast)).to eq('forecast_mocked_response')
      end

      it "expires cache after specified duration" do
        # first clear any cache from previous testing
        Rails.cache.clear

        # First request should fetch data from API and cache it
        get :submit_address, params: { address: valid_address }, format: :turbo_stream
        expect(assigns(:fresh_results)).to be_truthy  # Indicates fresh data fetched

        # Second request is right after the first, so it should be cached
        get :submit_address, params: { address: valid_address }, format: :turbo_stream
        expect(assigns(:fresh_results)).to be_nil  # Indicates cache is being used

        # Move forward 31 minutes to ensure that the cache is expired
        travel_to(Time.now + 31.minutes) do
          # Subsequent request should fetch data from API again
          get :submit_address, params: { address: valid_address }, format: :turbo_stream
          expect(assigns(:fresh_results)).to be_truthy  # Indicates fresh data fetched again
        end
      end

      it "renders the turbo_stream response" do
        post :submit_address, params: valid_address, format: :turbo_stream
        expect(response).to render_template('weather/submit_address')
      end
    end

    context 'with invalid address' do
      let(:invalid_params) { { address: 'random string' } }

      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it 'sets error message' do
        post :submit_address, params: invalid_params, format: :turbo_stream
        expect(assigns(:error_message)).to eq('There is no match for that address.')
      end
    end
  end
end