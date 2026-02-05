import SwiftUI
import SwiftData
import UIKit

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
        ZStack {
            VStack(spacing: 0) {
            MonthHeaderView(
                currentMonth: viewModel.currentMonth,
                onPrevious: viewModel.moveToPreviousMonth,
                onNext: viewModel.moveToNextMonth
            )
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Calendar for \(viewModel.currentMonth.formattedMonthYear)")
            
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
            .accessibilityHint("Swipe left or right to change months")
            
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.currentMonth)
        
        // Floating Window Overlay
        if let selectedDate = viewModel.selectedDate {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    viewModel.selectedDate = nil
                }
                .transition(.opacity)
            
            EventListView(
                date: selectedDate,
                events: events.filter { $0.date.isSameDay(as: selectedDate) },
                onEdit: { event in
                    editingEvent = event
                },
                onDelete: { event in
                    deleteEvent(event)
                },
                onAdd: {
                    showingAddEvent = true
                }
            )
            .background(Color(UIColor.systemBackground))
            .cornerRadius(16)
            .shadow(radius: 10)
            .padding()
            .frame(maxWidth: 400, maxHeight: 500) // Floating size constraints
            .transition(.scale.combined(with: .opacity))
            .zIndex(1) // Ensure it stays on top
        }
    } // End ZStack
    .animation(.easeInOut(duration: 0.3), value: viewModel.selectedDate)
        .sheet(isPresented: $showingAddEvent) {
            AddEventView(date: viewModel.selectedDate ?? Date()) { title, notes, color, date, reminderInterval in
                addEvent(title: title, notes: notes, color: color, date: date, reminderInterval: reminderInterval)
            }
        }
        .sheet(item: $editingEvent) { event in
            AddEventView(
                date: event.date,
                event: event,
                onSave: { title, notes, color, date, reminderInterval in
                    updateEvent(event, title: title, notes: notes, color: color, date: date, reminderInterval: reminderInterval)
                },
                onDelete: {
                    deleteEvent(event)
                }
            )
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: { showingAddEvent = true }) {
                    Image(systemName: "plus")
                }
                .accessibilityLabel("Add new event")
            }
        }
        .onAppear {
            eventViewModel.rescheduleAllNotifications(context: modelContext)
        }
    }
    
    private var eventsForSelectedDate: [Event] {
        guard let selectedDate = viewModel.selectedDate else { return [] }
        return events.filter { $0.date.isSameDay(as: selectedDate) }
    }
    
    private func addEvent(title: String, notes: String?, color: String, date: Date, reminderInterval: TimeInterval?) {
        eventViewModel.addEvent(
            date: date,
            title: title,
            notes: notes,
            color: color,
            reminderInterval: reminderInterval,
            context: modelContext
        )
    }
    
    private func updateEvent(_ event: Event, title: String, notes: String?, color: String, date: Date, reminderInterval: TimeInterval?) {
        // Since date might change, we might need a better update flow, but for now we update specific fields
        event.date = date // Update date
        eventViewModel.updateEvent(
            event,
            title: title,
            notes: notes,
            color: color,
            reminderInterval: reminderInterval,
            context: modelContext
        )
    }
    
    private func deleteEvent(_ event: Event) {
        eventViewModel.deleteEvent(event, context: modelContext)
    }
    
    private let eventViewModel = EventViewModel()
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
            .accessibilityLabel(Localization.string(.previousMonth))
            
            Spacer()
            
            Text(currentMonth.formattedMonthYear)
                .font(.system(size: 20, weight: .semibold))
            
            Spacer()
            
            Button(action: onNext) {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundColor(.primary)
            }
            .accessibilityLabel(Localization.string(.nextMonth))
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .glassBackground(cornerRadius: 16)
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

struct WeekdayHeaderView: View {
    private var weekdays: [String] {
        var calendar = Calendar.current
        calendar.locale = Localization.locale
        // Adjust to match "Mon...Sun" order or system order. 
        // Our sample code has Mon-Sun hardcoded effectively. 
        // Let's rely on formatter.shortStandaloneWeekdaySymbols
        let symbols = calendar.shortStandaloneWeekdaySymbols
        // Default symbols usually start Sunday.
        // If we want Mon-Sun:
        // This is complex to get perfectly right for "Mon...Sun" if the UI expects exactly that order.
        // But for simplicity and correctness in UA/EN, UA usually starts Monday. EN/US starts Sunday.
        // However, the previous code hardcoded Mon...Sun.
        // If I switch to locale based, the order might change (Sun..Sat).
        // If the grid (MonthView) expects Mon-Start, I must ensure this array matches Mon-Start.
        // Let's assume Mon-Start for visual consistency with previous design if it was 7 columns fixed.
        // Shifting Sunday to end:
        return Array(symbols.dropFirst()) + [symbols.first!]
    }
    
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
