require 'rails_helper'
require_relative '../../app/services/weather_api_service'

RSpec.describe WeatherApiService do
  describe '#current_weather' do
    context 'with valid data submitted' do
      let(:latitude) { 40.7128 }
      let(:longitude) { -74.0060 }
      let(:units) { 'imperial' }

      before do
        allow(ENV).to receive(:[]).with('OPEN_WEATHER_MAP_API_KEY').and_return('test_api_key')
        current_weather_file_path = Rails.root.join('spec', 'data', 'current_weather.json')
        current_weather = File.read(current_weather_file_path)
        stub_request(:get, "https://api.openweathermap.org/data/2.5/weather?appid=test_api_key&lat=40.7128&lon=-74.006&units=imperial")
          .to_return(status: 200, body: current_weather, headers: {})
      end

      it 'returns current weather data' do
        weather_service = WeatherApiService.new(latitude: latitude, longitude: longitude, units: units)
        expect(weather_service.current_weather["weather"][0]["description"]).to eq("light rain")
        expect(weather_service.current_weather["main"]["temp"]).to eq(47.66)
      end
    end

    context 'with invalid data submitted' do
      let(:latitude) { 40.7128 }
      let(:longitude) { -74.0060 }
      let(:units) { 'imperial' }

      it 'returns nil if latitude is missing' do
        weather_service = WeatherApiService.new(latitude: nil, longitude: longitude, units: units)
        expect(weather_service.current_weather).to eq(nil)
      end

      it 'returns nil if longitude is missing' do
        weather_service = WeatherApiService.new(latitude: latitude, longitude: nil, units: units)
        expect(weather_service.current_weather).to eq(nil)
      end

      it 'returns nil if units are missing' do
        weather_service = WeatherApiService.new(latitude: latitude, longitude: longitude, units: nil)
        expect(weather_service.current_weather).to eq(nil)
      end
    end
  end

  describe '#forecast' do
    context 'with valid data submitted' do
      let(:latitude) { 40.7128 }
      let(:longitude) { -74.0060 }
      let(:units) { 'imperial' }

      before do
        allow(ENV).to receive(:[]).with('OPEN_WEATHER_MAP_API_KEY').and_return('test_api_key')
        forecast_file_path = Rails.root.join('spec', 'data', 'forecast.json')
        forecast = File.read(forecast_file_path)
        stub_request(:get, "https://api.openweathermap.org/data/2.5/forecast?appid=test_api_key&lat=40.7128&lon=-74.006&units=imperial")
          .to_return(status: 200, body: forecast, headers: {})
      end

      it 'returns forecast data' do
        weather_service = WeatherApiService.new(latitude: latitude, longitude: longitude, units: units)
        expect(weather_service.forecast["list"].count).to eq(40)
      end
    end

    context 'with invalid data submitted' do
      let(:latitude) { 40.7128 }
      let(:longitude) { -74.0060 }
      let(:units) { 'imperial' }

      it 'returns nil if latitude is missing' do
        weather_service = WeatherApiService.new(latitude: nil, longitude: longitude, units: units)
        expect(weather_service.forecast).to eq(nil)
      end

      it 'returns nil if longitude is missing' do
        weather_service = WeatherApiService.new(latitude: latitude, longitude: nil, units: units)
        expect(weather_service.forecast).to eq(nil)
      end

      it 'returns nil if units are missing' do
        weather_service = WeatherApiService.new(latitude: latitude, longitude: longitude, units: nil)
        expect(weather_service.forecast).to eq(nil)
      end
    end
  end
end
