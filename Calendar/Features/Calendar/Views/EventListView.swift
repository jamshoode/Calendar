import SwiftUI

struct EventListView: View {
    let date: Date?
    let events: [Event]
    let onEdit: (Event) -> Void
    let onDelete: (Event) -> Void
    let onAdd: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let date = date {
                    Text(date.formattedDate)
                        .font(.system(size: 18, weight: .semibold))
                } else {
                    Text("Select a date")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.accentColor)
                }
                .accessibilityLabel("Add event")
            }
            
            if events.isEmpty {
                Button(action: onAdd) {
                    VStack(spacing: 8) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No events")
                            .foregroundColor(.secondary)
                        Text("Tap to add")
                            .font(.caption)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            } else {
                HStack {
                    Spacer()
                    Text("\(events.count) events")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, -8)
                
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(events) { event in
                            EventRow(event: event)
                                .onTapGesture {
                                    onEdit(event)
                                }
                                .swipeActions(edge: .trailing) {
                                    Button(role: .destructive) {
                                        onDelete(event)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                }
            }
        }
        .padding()
        .glassBackground(cornerRadius: 20)
        .padding(.horizontal)
        .padding(.top, 12)
    }
}

struct EventRow: View {
    let event: Event
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.eventColor(named: event.color))
                .frame(width: 12, height: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.system(size: 16, weight: .medium))
                
                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
