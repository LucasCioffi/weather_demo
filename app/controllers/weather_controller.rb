class WeatherController < ApplicationController

  def submit_address
    if params[:address].blank?
      @error_message = 'The address was blank'
      return
    end
    set_address_variables

    @current_weather = Rails.cache.fetch("current_weather_#{@cache_key}", expires_in: 30.minutes) do
      @fresh_results = true # we use this to indicate to the user that the results are not cached
      WeatherApiService.new(latitude: @latitude, longitude: @longitude, units: @units).current_weather
    end

    @forecast = Rails.cache.fetch("forecast_#{@cache_key}", expires_in: 30.minutes) do
      WeatherApiService.new(latitude: @latitude, longitude: @longitude, units: @units).forecast
    end

    check_for_api_errors

    respond_to do |format|
      format.turbo_stream
    end
  end

  private

  def set_address_variables
    @geocoded_location = Geocoder.search(params[:address]).first
    if @geocoded_location.nil?
      @error_message = 'There is no match for that address.'
      return
    end
    @latitude = @geocoded_location.coordinates[0]
    @longitude = @geocoded_location.coordinates[1]
    @municipality = @geocoded_location.data["address"]["village"] || @geocoded_location.data["address"]["locality"] || @geocoded_location.data["address"]["town"] || @geocoded_location.data["address"]["city"]
    @postal_code = @geocoded_location.data["address"]["postcode"]
    @county = @geocoded_location.data["address"]["county"]
    @country = @geocoded_location.data["address"]["country"]
    @display_name = @geocoded_location.data["display_name"]
    @time_zone_name = Timezone.lookup(@latitude, @longitude).name
    country_code = @geocoded_location.data["address"]["country_code"]
    @units = if ['us', 'mm', 'lr'].include?(@geocoded_location.data["address"]["country_code"])
               'imperial'
             else
               'metric'
             end
    @cache_key = if @postal_code.present?
                   "#{country_code}_#{@postal_code}"
                 else
                   @display_name.downcase.gsub(/[\s,]/, '_')
                 end
  end

  def check_for_api_errors
    return if @error_message.present?

    if @current_weather["cod"].to_i != 200
      # this code comes back as an integer, but we force it to_i just in case the API changes
      @error_message = 'There was an error retrieving the current weather.'
    elsif @forecast["cod"].to_i != 200
      # this code uses a different API endpoint and instead comes back as a string, so we force it to_i
      @error_message = 'There was an error retrieving the forecast.'
    end
  end
end
