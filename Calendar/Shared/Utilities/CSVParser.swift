import Foundation

/// Utility class for parsing Monobank and PUMB CSV files
class CSVParser {
  
  /// Parse CSV string into array of transactions
  static func parse(csvString: String, encoding: String.Encoding = .utf8) -> [CSVTransaction] {
    var transactions: [CSVTransaction] = []
    
    // Split by lines
    let lines = csvString.components(separatedBy: .newlines)
    guard lines.count > 1 else { return [] }
    
    // Parse header
    let headerLine = lines[0]
    let headers = parseCSVLine(headerLine)
    
    // Find column indices
    let dateIndex = headers.firstIndex { $0.contains("Дата") } ?? 0
    let merchantIndex = headers.firstIndex { $0.contains("Деталі") } ?? 1
    let amountIndex = headers.firstIndex { $0.contains("Сума в валюті картки") } ?? 4
    
    // Parse data rows
    for (lineIndex, line) in lines.enumerated() {
      guard lineIndex > 0, !line.isEmpty else { continue }
      
      let columns = parseCSVLine(line)
      guard columns.count > max(dateIndex, merchantIndex, amountIndex) else { continue }
      
      // Parse date
      let dateString = columns[dateIndex].trimmingCharacters(in: .whitespacesAndNewlines)
      guard let date = parseDate(dateString) else { continue }
      
      // Parse merchant
      let merchant = columns[merchantIndex].trimmingCharacters(in: .whitespacesAndNewlines)
      guard !merchant.isEmpty else { continue }
      
      // Parse amount
      let amountString = columns[amountIndex].trimmingCharacters(in: .whitespacesAndNewlines)
      guard let amount = parseAmount(amountString) else { continue }
      
      // Skip zero amounts
      guard amount != 0 else { continue }
      
      // Build raw data dictionary
      var rawData: [String: String] = [:]
      for (index, header) in headers.enumerated() {
        if index < columns.count {
          rawData[header] = columns[index]
        }
      }
      
      let transaction = CSVTransaction(
        date: date,
        merchant: merchant,
        amount: amount,
        currency: .uah, // Monobank exports in UAH by default
        rawData: rawData
      )
      
      transactions.append(transaction)
    }
    
    return transactions
  }
  
  /// Parse a single CSV line respecting quotes
  private static func parseCSVLine(_ line: String) -> [String] {
    var columns: [String] = []
    var currentColumn = ""
    var insideQuotes = false
    
    for char in line {
      if char == "\"" {
        insideQuotes.toggle()
      } else if char == "," && !insideQuotes {
        columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
        currentColumn = ""
      } else {
        currentColumn.append(char)
      }
    }
    
    // Add last column
    columns.append(currentColumn.trimmingCharacters(in: .whitespacesAndNewlines))
    
    return columns
  }
  
  /// Parse date string in format "DD.MM.YYYY HH:MM:SS"
  private static func parseDate(_ dateString: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "dd.MM.yyyy HH:mm:ss"
    formatter.locale = Locale(identifier: "uk_UA")
    return formatter.date(from: dateString)
  }
  
  /// Parse amount string
  private static func parseAmount(_ amountString: String) -> Double? {
    // Remove any formatting and parse
    let cleaned = amountString
      .replacingOccurrences(of: ",", with: ".")
      .replacingOccurrences(of: " ", with: "")
      .replacingOccurrences(of: "₴", with: "")
      .replacingOccurrences(of: "$", with: "")
      .replacingOccurrences(of: "€", with: "")
    
    return Double(cleaned)
  }
}
