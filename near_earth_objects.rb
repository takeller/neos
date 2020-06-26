require 'faraday'
require 'figaro'
require 'pry'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects

  def self.find_neos_by_date(date)
    neo = NearEarthObjects.new
    parsed_asteroids_data = neo.get_data(date)
    neo.format_data(parsed_asteroids_data)
  end

  def get_data(date)
    conn = Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: date, api_key: ENV['nasa_api_key']}
    )
    asteroids_list_data = conn.get('/neo/rest/v1/feed')

    JSON.parse(asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{date}"]
  end

  def format_data(data)
    {
      astroid_list: format_asteroid_list(data),
      biggest_astroid: find_largest_asteroid_diameter(data),
      total_number_of_astroids: data.count
    }
  end

  def find_largest_asteroid_diameter(data)
    data.map do |astroid|
      astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
    end.max { |a,b| a<=> b}
  end

  def format_asteroid_list(data)
    data.map do |astroid|
      {
        name: astroid[:name],
        diameter: "#{astroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i} ft",
        miss_distance: "#{astroid[:close_approach_data][0][:miss_distance][:miles].to_i} miles"
      }
    end
  end

end
