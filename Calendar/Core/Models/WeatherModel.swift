import Foundation
import SwiftUI

// MARK: - Weather Interpretation Codes (WMO)
enum WeatherCode: Int, Codable {
    case clearSky = 0
    case mainlyClear = 1
    case partlyCloudy = 2
    case overcast = 3
    case fog = 45
    case depositingRimeFog = 48
    case drizzleLight = 51
    case drizzleModerate = 53
    case drizzleDense = 55
    case freezingDrizzleLight = 56
    case freezingDrizzleDense = 57
    case rainSlight = 61
    case rainModerate = 63
    case rainHeavy = 65
    case freezingRainLight = 66
    case freezingRainHeavy = 67
    case snowSlight = 71
    case snowModerate = 73
    case snowHeavy = 75
    case snowGrains = 77
    case rainShowersSlight = 80
    case rainShowersModerate = 81
    case rainShowersViolent = 82
    case snowShowersSlight = 85
    case snowShowersHeavy = 86
    case thunderstormSlight = 95
    case thunderstormSlightHail = 96
    case thunderstormHeavyHail = 99

    var icon: String {
        switch self {
        case .clearSky: return "sun.max.fill"
        case .mainlyClear: return "sun.max.fill"
        case .partlyCloudy: return "cloud.sun.fill"
        case .overcast: return "cloud.fill"
        case .fog, .depositingRimeFog: return "cloud.fog.fill"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "cloud.drizzle.fill"
        case .freezingDrizzleLight, .freezingDrizzleDense: return "cloud.hail.fill"
        case .rainSlight, .rainModerate, .rainHeavy: return "cloud.rain.fill"
        case .freezingRainLight, .freezingRainHeavy: return "cloud.heavyrain.fill"
        case .snowSlight, .snowModerate, .snowHeavy, .snowGrains: return "snowflake"
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent: return "cloud.sun.rain.fill"
        case .snowShowersSlight, .snowShowersHeavy: return "cloud.snow.fill"
        case .thunderstormSlight, .thunderstormSlightHail, .thunderstormHeavyHail: return "cloud.bolt.rain.fill"
        }
    }

    var description: String {
        // We'll use localized strings later if needed, but for now English/UA mapping
        switch self {
        case .clearSky, .mainlyClear: return "Clear"
        case .partlyCloudy: return "Partly Cloudy"
        case .overcast: return "Overcast"
        case .fog, .depositingRimeFog: return "Fog"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "Drizzle"
        case .rainSlight, .rainModerate, .rainHeavy: return "Rain"
        case .snowSlight, .snowModerate, .snowHeavy: return "Snow"
        case .thunderstormSlight, .thunderstormSlightHail, .thunderstormHeavyHail: return "Thunderstorm"
        default: return "Cloudy"
        }
    }
}

// MARK: - Open-Meteo Response Models
struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let elevation: Double
    let hourly: HourlyData
    let daily: DailyData
}

struct HourlyData: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let weathercode: [Int]
}

struct DailyData: Codable {
    let time: [String]
    let weathercode: [Int]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
}

// MARK: - Processed Models
struct WeatherData: Codable {
    let city: String
    let lastSyncDate: Date
    let hourlyForecast: [HourlyPoint]
    let dailyForecast: [DailyPoint]

    var current: HourlyPoint? {
        let now = Date()
        return hourlyForecast.first { $0.time > now } ?? hourlyForecast.first
    }
}

struct HourlyPoint: Codable, Identifiable {
    var id: String { "\(time.timeIntervalSince1970)" }
    let time: Date
    let temperature: Double
    let code: WeatherCode
}

struct DailyPoint: Codable, Identifiable {
    var id: String { "\(time.timeIntervalSince1970)" }
    let time: Date
    let minTemp: Double
    let maxTemp: Double
    let code: WeatherCode
}

// MARK: - Geocoding Models
struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

struct GeocodingResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
}
