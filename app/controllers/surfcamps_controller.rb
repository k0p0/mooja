require 'json'
require 'open-uri'

class SurfcampsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  before_action :set_surfcamp, only: [:show]

  def index
    if params[:maxprice].blank? && params[:address].blank?
      @surfcamps = Surfcamp.all.where.not(latitude: nil, longitude: nil)
    else
      # @surfcamps = Surfcamp.where("price_per_night_per_person <= ?", params[:maxprice]).or(Surfcamp.near(params[:address], 500))
      @surfcamps_location = Surfcamp.near(params[:address], 500)
      if params[:maxprice].blank?
        @surfcamps = @surfcamps_location
      elsif params[:address].blank?
        @discounted_surfcamps = Surfcamp.joins(:discounts).where("discounted_price <= ?", params[:maxprice])
        @normal_price_surfcamps = Surfcamp.where("price_per_night_per_person <= ?", params[:maxprice])
        @matching_surfcamps = @discounted_surfcamps + @normal_price_surfcamps
        @surfcamps = @matching_surfcamps.uniq
      else
        @discounted_surfcamps = @surfcamps_location.joins(:discounts).where("discounted_price <= ?", params[:maxprice])
        @normal_price_surfcamps = @surfcamps_location.where("price_per_night_per_person <= ?", params[:maxprice])
        @matching_surfcamps = @discounted_surfcamps + @normal_price_surfcamps
        @surfcamps = @matching_surfcamps.uniq
      end
    end

    @hash = Gmaps4rails.build_markers(@surfcamps) do |surfcamp, marker|
      marker.lat surfcamp.latitude
      marker.lng surfcamp.longitude
      marker.infowindow render_to_string(partial: "/surfcamps/map_box", locals: { surfcamp: surfcamp })
      marker.picture({
        :url => "http://maps.google.com/mapfiles/ms/icons/#{marker_color(surfcamp)}.png",
        :width   => 40,
        :height  => 40
      })
    end

    # # Parsing weather conditions for all surfcamps - FULL
    # all_weekly_weathers = []
    # @surfcamps.each do |surfcamp|
    #   url = "http://api.worldweatheronline.com/premium/v1/marine.ashx?key=#{ENV['WEATHER_API']}&format=json&q=#{surfcamp.latitude},#{surfcamp.longitude}"
    #   weather_serialized = open(url).read
    #   weather = JSON.parse(weather_serialized)
    #   weekly_weather_datas = []
    #   weekly_weather_datas << surfcamp.id
    #   weather['data']['weather'].each do |element|
    #     date_weather_data = {}
    #     date_weather_data[:date] = element['date']
    #     date_weather_data[:max_temp] = element['maxtempC']
    #     date_weather_data[:wind_speed] = element['hourly'][4]['windspeedKmph']
    #     date_weather_data[:weather_description] = element['hourly'][4]['weatherDesc'].first['value']
    #     date_weather_data[:wave] = element['hourly'][4]['swellPeriod_secs']
    #     weekly_weather_datas << date_weather_data
    #   end
    #   weekly_weather = weekly_weather_datas
    #   all_weekly_weathers << weekly_weather
    # end
    # @all_weathers = all_weekly_weathers
  end

  def show
    @booking = Booking.new
    @errors = {}
  end

  private

  def set_surfcamp
    @surfcamp = Surfcamp.find(params[:id])
  end

  def set_params
    params.require(:surfcamp).permit(:name, :description, :rating, :address, :photo)
  end

  def percentage_of_savings(surfcamp)
    discounted_price = surfcamp.discounts.first.discounted_price
    original_price = surfcamp.price_per_night_per_person
    percentage_of_saving = 1 - (discounted_price).fdiv(original_price)
    # multiply by 100 and round it for display
    (percentage_of_saving * 100).round
  end

  def marker_color(surfcamp)
    # ['green', 'red'].sample
    # check si on a des infos météo pour ce surf camp
    unless surfcamp.waves_period.blank?
      # check si la période est inférieure à 10s >> red
      if surfcamp.waves_period >= 10
        return 'green'
      else
        return 'red'
      end
    else
      return 'grey'
    end
  end

  helper_method :percentage_of_savings
end
