import Foundation

enum WeatherError: Error {
    case invalidURL
    case noResults
    case requestFailed
    case decodingError
}

public class WeatherService {
    public static let shared = WeatherService()
    private let session = URLSession.shared
    
    public init() {}
    
    // MARK: - Geocoding
    public func searchCity(_ query: String) async throws -> [GeocodingResult] {
        let escapedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? ""
        let urlString = "https://geocoding-api.open-meteo.com/v1/search?name=\(escapedQuery)&count=10&language=en&format=json"
        
        guard let url = URL(string: urlString) else { throw WeatherError.invalidURL }
        
        let (data, _) = try await session.data(from: url)
        
        do {
            let response = try JSONDecoder().decode(GeocodingResponse.self, from: data)
            return response.results ?? []
        } catch {
            throw WeatherError.decodingError
        }
    }
    
    // MARK: - Forecast
    public func fetchWeather(latitude: Double, longitude: Double) async throws -> (hourly: [HourlyPoint], daily: [DailyPoint]) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(latitude)&longitude=\(longitude)&hourly=temperature_2m,weathercode,is_day&daily=weathercode,temperature_2m_max,temperature_2m_min&timezone=auto"
        
        guard let url = URL(string: urlString) else { throw WeatherError.invalidURL }
        
        let (data, _) = try await session.data(from: url)
        
        let decoder = JSONDecoder()
        let response = try decoder.decode(WeatherResponse.self, from: data)
        
        // Process Hourly
        var hourlyPoints: [HourlyPoint] = []
        let isoFormatter = DateFormatter()
        isoFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm"
        
        for i in 0..<response.hourly.time.count {
            if let date = isoFormatter.date(from: response.hourly.time[i]) {
                let point = HourlyPoint(
                    time: date,
                    temperature: response.hourly.temperature_2m[i],
                    code: WeatherCode(rawValue: response.hourly.weathercode[i]) ?? .partlyCloudy,
                    isDay: response.hourly.is_day[i] == 1
                )
                hourlyPoints.append(point)
            }
        }
        
        // Process Daily
        var dailyPoints: [DailyPoint] = []
        let dailyFormatter = DateFormatter()
        dailyFormatter.dateFormat = "yyyy-MM-dd"
        
        for i in 0..<response.daily.time.count {
            if let date = dailyFormatter.date(from: response.daily.time[i]) {
                let point = DailyPoint(
                    time: date,
                    minTemp: response.daily.temperature_2m_min[i],
                    maxTemp: response.daily.temperature_2m_max[i],
                    code: WeatherCode(rawValue: response.daily.weathercode[i]) ?? .partlyCloudy
                )
                dailyPoints.append(point)
            }
        }
        
        return (hourlyPoints, dailyPoints)
    }
}
