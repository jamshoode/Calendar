import Foundation
import SwiftUI

// MARK: - Weather Interpretation Codes (WMO)
public enum WeatherCode: Int, Codable {
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

    public func icon(isDay: Bool) -> String {
        switch self {
        case .clearSky, .mainlyClear: 
            return isDay ? "sun.max.fill" : "moon.stars.fill"
        case .partlyCloudy: 
            return isDay ? "cloud.sun.fill" : "cloud.moon.fill"
        case .fog, .depositingRimeFog: return "cloud.fog.fill"
        case .overcast: return "cloud.fill"
        case .drizzleLight, .drizzleModerate, .drizzleDense: return "cloud.drizzle.fill"
        case .freezingDrizzleLight, .freezingDrizzleDense: return "cloud.hail.fill"
        case .rainSlight, .rainModerate, .rainHeavy: return "cloud.rain.fill"
        case .freezingRainLight, .freezingRainHeavy: return "cloud.heavyrain.fill"
        case .snowSlight, .snowModerate, .snowHeavy, .snowGrains: return "snowflake"
        case .rainShowersSlight, .rainShowersModerate, .rainShowersViolent: 
            return isDay ? "cloud.sun.rain.fill" : "cloud.moon.rain.fill"
        case .snowShowersSlight, .snowShowersHeavy: return "cloud.snow.fill"
        case .thunderstormSlight, .thunderstormSlightHail, .thunderstormHeavyHail: return "cloud.bolt.rain.fill"
        }
    }

    var description: String {
        switch self {
        case .clearSky, .mainlyClear: return Localization.string(.weatherClear)
        case .partlyCloudy: return Localization.string(.weatherPartlyCloudy)
        case .overcast: return Localization.string(.weatherOvercast)
        case .fog, .depositingRimeFog: return Localization.string(.weatherFog)
        case .drizzleLight, .drizzleModerate, .drizzleDense: return Localization.string(.weatherDrizzle)
        case .rainSlight, .rainModerate, .rainHeavy: return Localization.string(.weatherRain)
        case .snowSlight, .snowModerate, .snowHeavy: return Localization.string(.weatherSnow)
        case .thunderstormSlight, .thunderstormSlightHail, .thunderstormHeavyHail: return Localization.string(.weatherThunderstorm)
        default: return Localization.string(.weatherCloudy)
        }
    }
}

// MARK: - Open-Meteo Response Models
public struct WeatherResponse: Codable {
    let latitude: Double
    let longitude: Double
    let timezone: String
    let elevation: Double
    let hourly: HourlyData
    let daily: DailyData
}

public struct HourlyData: Codable {
    let time: [String]
    let temperature_2m: [Double]
    let weathercode: [Int]
    let is_day: [Int]
}

public struct DailyData: Codable {
    let time: [String]
    let weathercode: [Int]
    let temperature_2m_max: [Double]
    let temperature_2m_min: [Double]
}

// MARK: - Processed Models
public struct WeatherData: Codable {
    let city: String
    let lastSyncDate: Date
    let hourlyForecast: [HourlyPoint]
    let dailyForecast: [DailyPoint]

    var current: HourlyPoint? {
        let now = Date()
        return hourlyForecast.first { $0.time > now } ?? hourlyForecast.first
    }
}

public struct HourlyPoint: Codable, Identifiable {
    public var id: String { "\(time.timeIntervalSince1970)" }
    public let time: Date
    public let temperature: Double
    public let code: WeatherCode
    public let isDay: Bool
}

public struct DailyPoint: Codable, Identifiable {
    public var id: String { "\(time.timeIntervalSince1970)" }
    public let time: Date
    public let minTemp: Double
    public let maxTemp: Double
    public let code: WeatherCode
}

// MARK: - Geocoding Models
public struct GeocodingResponse: Codable {
    let results: [GeocodingResult]?
}

public struct GeocodingResult: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let country: String
    let admin1: String?
}
