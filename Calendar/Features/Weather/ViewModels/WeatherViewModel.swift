import Foundation
import SwiftUI
import Combine
import WidgetKit

public class WeatherViewModel: ObservableObject {
    @Published public var weatherData: WeatherData?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var searchResults: [GeocodingResult] = []
    
    @AppStorage(Constants.Weather.cityKey) private var savedCity: String = ""
    @AppStorage("weatherLat") private var savedLat: Double = 0.0
    @AppStorage("weatherLong") private var savedLong: Double = 0.0
    @AppStorage("weatherDataCache") private var cachedWeatherData: Data = Data()
    @AppStorage("weatherHistoryCache") private var cachedWeatherHistory: Data = Data()
    
    private let weatherService = WeatherService.shared
    private var weatherHistory: WeatherHistory = WeatherHistory(city: "")
    
    public init() {
        loadCachedData()
        loadHistory()
        Task {
            await refreshIfNeeded()
        }
    }
    
    // MARK: - Persistence
    private func loadCachedData() {
        guard !cachedWeatherData.isEmpty else { return }
        do {
            let decoded = try JSONDecoder().decode(WeatherData.self, from: cachedWeatherData)
            self.weatherData = decoded
        } catch {
            print("Failed to decode cached weather: \(error)")
        }
    }
    
    private func saveToCache(_ data: WeatherData) {
        do {
            // Save current weather data
            let encoded = try JSONEncoder().encode(data)
            self.cachedWeatherData = encoded
            
            // Update and save history
            if weatherHistory.city != data.city {
                weatherHistory = WeatherHistory(city: data.city)
            }
            
            // Add each day's forecast to history
            for dailyPoint in data.dailyForecast {
                let entry = WeatherHistoryEntry(
                    date: dailyPoint.time,
                    minTemp: dailyPoint.minTemp,
                    maxTemp: dailyPoint.maxTemp,
                    code: dailyPoint.code
                )
                weatherHistory.addEntry(entry)
            }
            
            let historyEncoded = try JSONEncoder().encode(weatherHistory)
            self.cachedWeatherHistory = historyEncoded
            
            // Share with widget via shared UserDefaults
            if let sharedDefaults = UserDefaults(suiteName: Constants.Storage.appGroupIdentifier) {
                sharedDefaults.set(encoded, forKey: Constants.Widget.weatherDataKey)
                sharedDefaults.set(historyEncoded, forKey: "widgetWeatherHistory")
                sharedDefaults.synchronize()
                WidgetCenter.shared.reloadTimelines(ofKind: "WeatherWidget")
            }
        } catch {
            print("Failed to encode weather for cache: \(error)")
        }
    }
    
    private func loadHistory() {
        guard !cachedWeatherHistory.isEmpty else { return }
        do {
            weatherHistory = try JSONDecoder().decode(WeatherHistory.self, from: cachedWeatherHistory)
        } catch {
            print("Failed to decode weather history: \(error)")
            weatherHistory = WeatherHistory(city: savedCity)
        }
    }
    
    // MARK: - Actions
    public func refreshIfNeeded() async {
        guard !savedCity.isEmpty else { return }
        
        let now = Date()
        if let lastSync = weatherData?.lastSyncDate,
           Calendar.current.isDate(lastSync, inSameDayAs: now) {
            // Already synced today, skip unless data is missing
            return
        }
        
        await fetchWeather(city: savedCity, lat: savedLat, lon: savedLong)
    }
    
    public func search(query: String) async {
        guard query.count > 2 else {
            DispatchQueue.main.async { self.searchResults = [] }
            return
        }
        
        do {
            let results = try await weatherService.searchCity(query)
            DispatchQueue.main.async { self.searchResults = results }
        } catch {
            print("Search error: \(error)")
        }
    }
    
    public func selectCity(_ result: GeocodingResult) async {
        DispatchQueue.main.async {
            self.savedCity = result.name
            self.savedLat = result.latitude
            self.savedLong = result.longitude
            self.searchResults = []
        }
        await fetchWeather(city: result.name, lat: result.latitude, lon: result.longitude)
    }
    
    public func fetchWeather(city: String, lat: Double, lon: Double) async {
        DispatchQueue.main.async { self.isLoading = true; self.errorMessage = nil }
        
        do {
            let (hourly, daily) = try await weatherService.fetchWeather(latitude: lat, longitude: lon)
            let newData = WeatherData(
                city: city,
                lastSyncDate: Date(),
                hourlyForecast: hourly,
                dailyForecast: daily
            )
            
            DispatchQueue.main.async {
                self.weatherData = newData
                self.saveToCache(newData)
                self.isLoading = false
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = "Failed to fetch weather"
                self.isLoading = false
            }
        }
    }
}
