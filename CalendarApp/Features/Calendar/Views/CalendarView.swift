import SwiftUI
import SwiftData

struct CalendarView: View {
    @StateObject private var viewModel = CalendarViewModel()
    @Query(sort: \Event.date) private var events: [Event]
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingAddEvent = false
    @State private var editingEvent: Event?
    
    private var eventsForMonth: [Event] {
        let startOfMonth = viewModel.currentMonth.startOfMonth
        let endOfMonth = viewModel.currentMonth.endOfMonth
        return events.filter { $0.date >= startOfMonth && $0.date <= endOfMonth }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            MonthHeaderView(
                currentMonth: viewModel.currentMonth,
                onPrevious: viewModel.moveToPreviousMonth,
                onNext: viewModel.moveToNextMonth
            )
            
            WeekdayHeaderView()
            
            MonthView(
                currentMonth: viewModel.currentMonth,
                selectedDate: viewModel.selectedDate,
                events: eventsForMonth,
                onSelectDate: viewModel.selectDate
            )
            .swipeGesture(
                onLeft: viewModel.moveToNextMonth,
                onRight: viewModel.moveToPreviousMonth
            )
            
            if viewModel.selectedDate != nil {
                EventListView(
                    date: viewModel.selectedDate,
                    events: eventsForSelectedDate,
                    onEdit: { event in
                        editingEvent = event
                    },
                    onDelete: { event in
                        deleteEvent(event)
                    }
                )
            }
        }
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(date: viewModel.selectedDate) { title, notes, color in
                addEvent(title: title, notes: notes, color: color)
            }
        }
        .sheet(item: $editingEvent) { event in
            AddEventView(
                date: event.date,
                event: event,
                onSave: { title, notes, color in
                    updateEvent(event, title: title, notes: notes, color: color)
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddEvent = true }) {
                    Image(systemName: "plus")
                }
            }
        }
    }
    
    private var eventsForSelectedDate: [Event] {
        guard let selectedDate = viewModel.selectedDate else { return [] }
        return events.filter { $0.date.isSameDay(as: selectedDate) }
    }
    
    private func addEvent(title: String, notes: String?, color: String) {
        let event = Event(
            date: viewModel.selectedDate ?? Date(),
            title: title,
            notes: notes,
            color: color
        )
        modelContext.insert(event)
    }
    
    private func updateEvent(_ event: Event, title: String, notes: String?, color: String) {
        event.title = title
        event.notes = notes
        event.color = color
    }
    
    private func deleteEvent(_ event: Event) {
        modelContext.delete(event)
    }
}

struct MonthHeaderView: View {
    let currentMonth: Date
    let onPrevious: () -> Void
    let onNext: () -> Void
    
    var body: some View {
        HStack {
            Button(action: onPrevious) {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            Text(currentMonth.formattedMonthYear)
                .font(.system(size: 20, weight: .semibold))
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .glassBackground(cornerRadius: 16)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct WeekdayHeaderView: View {
    private let weekdays = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
    
    var body: some View {
        HStack {
            ForEach(weekdays, id: \.self) { day in
                Text(day)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
    }
}
