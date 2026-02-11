import SwiftUI

public struct WeatherView: View {
    @StateObject public var viewModel = WeatherViewModel()
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
    public init() {}
    
    public var body: some View {
        ZStack {
            Color.backgroundPrimary.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // City Search / Header
                    VStack(spacing: 16) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.textTertiary)
                            TextField(Localization.string(.searchCity), text: $searchText)
                                .textFieldStyle(.plain)
                                .onChange(of: searchText) { newValue in
                                    Task { await viewModel.search(query: newValue) }
                                }
                        }
                        .padding(12)
                        .background(Color.backgroundSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        
                        if !viewModel.searchResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                ForEach(viewModel.searchResults, id: \.latitude) { result in
                                    Button {
                                        Task {
                                            await viewModel.selectCity(result)
                                            searchText = ""
                                            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                                        }
                                    } label: {
                                        HStack {
                                            VStack(alignment: .leading) {
                                                Text(result.name)
                                                    .font(Typography.headline)
                                                Text("\(result.admin1 ?? ""), \(result.country)")
                                                    .font(Typography.caption)
                                                    .foregroundColor(.textTertiary)
                                            }
                                            Spacer()
                                            Image(systemName: "chevron.right")
                                                .font(.system(size: 12))
                                                .foregroundColor(.textTertiary)
                                        }
                                        .padding(.vertical, 12)
                                        .padding(.horizontal, 8)
                                    }
                                    .buttonStyle(.plain)
                                    Divider()
                                }
                            }
                            .background(Color.backgroundSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                    .padding(.horizontal)
                    
                    if let weather = viewModel.weatherData {
                        // Current Weather Card
                        currentWeatherCard(weather)
                        
                        // Hourly Forecast (Minimalistic Timeline)
                        hourlyForecastSection(weather)
                        
                        // Weekly Forecast
                        weeklyForecastSection(weather)
                    } else if viewModel.isLoading {
                        ProgressView()
                            .padding(.top, 40)
                    } else {
                        Text(Localization.string(.weatherSearchPrompt))
                            .font(Typography.subheadline)
                            .foregroundColor(.textTertiary)
                            .padding(.top, 40)
                    }
                }
                .padding(.vertical)
            }
            .scrollDismissesKeyboard(.immediately)
        }
        .navigationTitle(viewModel.weatherData?.city ?? Localization.string(.weather))
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Components
    
    @ViewBuilder
    private func currentWeatherCard(_ weather: WeatherData) -> some View {
        if let current = weather.current {
            VStack(spacing: 8) {
                Text(Date().formatted(.dateTime.weekday(.wide).locale(Localization.locale)).capitalized)
                    .font(Typography.headline)
                    .foregroundColor(.textTertiary)
                
                Image(systemName: current.code.icon(isDay: current.isDay))
                    .font(.system(size: 64))
                    .symbolRenderingMode(.multicolor)
                
                Text("\(Int(current.temperature))°")
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                
                Text(current.code.description)
                    .font(Typography.title)
                    .foregroundColor(.textSecondary)
                
                if let today = weather.dailyForecast.first {
                    HStack(spacing: 16) {
                        Label("\(Int(today.maxTemp))°", systemImage: "arrow.up")
                        Label("\(Int(today.minTemp))°", systemImage: "arrow.down")
                    }
                    .font(Typography.subheadline)
                    .foregroundColor(.textTertiary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        }
    }
    
    @ViewBuilder
    private func hourlyForecastSection(_ weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string(.hourlyForecast))
                .font(Typography.headline)
                .padding(.horizontal)
            
            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 20) {
                        let today = Calendar.current.startOfDay(for: Date())
                        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
                        
                        let dayForecast = weather.hourlyForecast.filter { 
                            $0.time >= today && $0.time < tomorrow 
                        }
                        
                        ForEach(dayForecast) { point in
                            VStack(spacing: 8) {
                                Text(point.time.formatted(date: .omitted, time: .shortened))
                                    .font(.system(size: 10))
                                    .foregroundColor(.textTertiary)
                                
                                Image(systemName: smoothedIcon(for: point, in: dayForecast))
                                    .font(.system(size: 20))
                                    .symbolRenderingMode(.multicolor)
                                
                                Text("\(Int(point.temperature))°")
                                    .font(Typography.subheadline)
                                    .fontWeight(.semibold)
                            }
                            .frame(width: 50)
                            .id(Calendar.current.component(.hour, from: point.time))
                        }
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    scrollToCurrentHour(proxy: proxy)
                }
                .onChange(of: weather.city) { _ in
                    scrollToCurrentHour(proxy: proxy)
                }
            }
        }
    }
    
    private func smoothedIcon(for point: HourlyPoint, in forecast: [HourlyPoint]) -> String {
        guard let index = forecast.firstIndex(where: { $0.id == point.id }) else {
            return point.code.icon(isDay: point.isDay)
        }
        
        let currentCode = point.code.rawValue
        
        // Heuristic: If Clear (0) or Mainly Clear (1) is isolated between cloudy states (>= 2), 
        // use Partly Cloudy (2) icon to avoid jarring "flicker".
        if currentCode <= 1 && index > 0 && index < forecast.count - 1 {
            let prevCode = forecast[index - 1].code.rawValue
            let nextCode = forecast[index + 1].code.rawValue
            
            if prevCode >= 2 && nextCode >= 2 {
                return WeatherCode.partlyCloudy.icon(isDay: point.isDay)
            }
        }
        
        return point.code.icon(isDay: point.isDay)
    }
    
    private func scrollToCurrentHour(proxy: ScrollViewProxy) {
        let currentHour = Calendar.current.component(.hour, from: Date())
        withAnimation {
            proxy.scrollTo(currentHour, anchor: .center)
        }
    }
    
    @ViewBuilder
    private func weeklyForecastSection(_ weather: WeatherData) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(Localization.string(.dailyForecast))
                .font(Typography.headline)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                let futureDays = weather.dailyForecast.dropFirst().prefix(7)
                ForEach(futureDays) { day in
                    HStack {
                        Text(day.time.formatted(Date.FormatStyle(locale: Localization.locale).weekday(.wide)).capitalized)
                            .font(Typography.body)
                            .frame(width: 100, alignment: .leading)
                        
                        Spacer()
                        
                        Image(systemName: day.code.icon(isDay: true))
                            .font(.system(size: 20))
                            .symbolRenderingMode(.multicolor)
                            .frame(width: 40)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Text("\(Int(day.maxTemp))°")
                                .font(Typography.body)
                                .fontWeight(.semibold)
                                .frame(width: 35, alignment: .trailing)
                            
                            Text("\(Int(day.minTemp))°")
                                .font(Typography.body)
                                .foregroundColor(.textTertiary)
                                .frame(width: 35, alignment: .trailing)
                        }
                    }
                    .padding(.vertical, 12)
                    .padding(.horizontal)
                    
                    if day.id != futureDays.last?.id {
                        Divider().padding(.leading, 16)
                    }
                }
            }
            .background(Color.backgroundSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }
}
