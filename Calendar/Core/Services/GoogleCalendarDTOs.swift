import Foundation

struct GoogleCalendarListResponse: Decodable {
  let items: [GoogleCalendarListEntryDTO]
  let nextPageToken: String?

  private enum CodingKeys: String, CodingKey {
    case items
    case nextPageToken
  }
}

struct GoogleCalendarListEntryDTO: Decodable {
  let id: String
  let summary: String?
  let description: String?
  let accessRole: String?
  let primary: Bool?
  let selected: Bool?
  let timeZone: String?
}

struct GoogleEventListResponse: Decodable {
  let items: [GoogleEventDTO]
  let nextPageToken: String?
  let nextSyncToken: String?

  private enum CodingKeys: String, CodingKey {
    case items
    case nextPageToken
    case nextSyncToken
  }
}

struct GoogleEventDateTimeDTO: Decodable {
  let date: String?
  let dateTime: String?
  let timeZone: String?
}

struct GoogleEventDTO: Decodable {
  let id: String
  let status: String?
  let summary: String?
  let description: String?
  let start: GoogleEventDateTimeDTO?
  let end: GoogleEventDateTimeDTO?
  let updated: String?
  let recurringEventId: String?

  private enum CodingKeys: String, CodingKey {
    case id
    case status
    case summary
    case description
    case start
    case end
    case updated
    case recurringEventId
  }

  var isDeleted: Bool {
    status == "cancelled"
  }
}

struct GoogleEventUpsertRequest: Encodable {
  let summary: String
  let description: String?
  let start: GoogleEventRequestDateTime
  let end: GoogleEventRequestDateTime

  struct GoogleEventRequestDateTime: Encodable {
    let date: String?
    let dateTime: String?
    let timeZone: String?
  }
}
