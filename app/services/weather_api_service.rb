require 'net/http'

class WeatherApiService
  attr_reader :latitude, :longitude, :units
  BASE_URL = 'https://api.openweathermap.org/data/2.5/'

  def initialize(latitude:, longitude:, units:)
    @latitude = latitude
    @longitude = longitude
    @units = units
  end

  def current_weather
    return if missing_parameters?
    response = Net::HTTP.get_response(uri('weather'))
    JSON.parse(response.body)
  end

  def forecast
    return if missing_parameters?
    response = Net::HTTP.get_response(uri('forecast'))
    JSON.parse(response.body)
  end

  private

  def uri(custom_path)
    return @uri if defined?(@uri)
    @uri = URI(BASE_URL + custom_path)
    params = { lat: @latitude, lon: @longitude, units: @units, appid: ENV['OPEN_WEATHER_MAP_API_KEY']}
    @uri.query = URI.encode_www_form(params)
    @uri
  end

  def missing_parameters?
    return true if !@latitude || !@longitude || !@units
  end
end