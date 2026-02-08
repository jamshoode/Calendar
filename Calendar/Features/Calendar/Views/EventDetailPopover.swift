import SwiftUI

struct EventDetailPopover: View {
  let event: Event
  let onDismiss: () -> Void
  var onEdit: (() -> Void)?
  var onDelete: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      // Header with color bar
      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 3)
          .fill(Color.eventColor(named: event.color))
          .frame(width: 6, height: 40)

        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 6) {
            Text(event.title)
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.primary)
              .fixedSize(horizontal: false, vertical: true)

            if event.isHoliday {
              Image(systemName: "star.fill")
                .font(.system(size: 12))
                .foregroundColor(.eventTeal)
            }
          }

          Text(
            event.date.formatted(
              .dateTime.weekday(.wide).day().month(.wide).hour().minute()
                .locale(Localization.locale))
          )
          .font(.system(size: 13))
          .foregroundColor(.secondary)
        }

        Spacer()

        Button(action: onDismiss) {
          Image(systemName: "xmark.circle.fill")
            .font(.system(size: 22))
            .foregroundColor(.secondary.opacity(0.6))
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 18)
      .padding(.top, 18)
      .padding(.bottom, 14)

      // Notes
      if let notes = event.notes, !notes.isEmpty {
        Divider()
          .padding(.horizontal, 18)

        ScrollView {
          Text(notes)
            .font(.system(size: 15))
            .foregroundColor(Color.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
        .frame(maxHeight: 200)
      }

      // Action buttons (only for non-holiday events)
      if !event.isHoliday {
        Divider()
          .padding(.horizontal, 18)

        HStack(spacing: 16) {
          if let onEdit = onEdit {
            Button(action: onEdit) {
              HStack(spacing: 6) {
                Image(systemName: "pencil")
                  .font(.system(size: 14, weight: .medium))
                Text(Localization.string(.edit))
                  .font(.system(size: 14, weight: .medium))
              }
              .foregroundColor(.accentColor)
            }
            .buttonStyle(.plain)
          }

          Spacer()

          if let onDelete = onDelete {
            Button(action: onDelete) {
              HStack(spacing: 6) {
                Image(systemName: "trash")
                  .font(.system(size: 14, weight: .medium))
                Text(Localization.string(.delete))
                  .font(.system(size: 14, weight: .medium))
              }
              .foregroundColor(.red)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
      } else {
        // Holiday label
        HStack(spacing: 6) {
          Image(systemName: "star.fill")
            .font(.system(size: 12))
            .foregroundColor(.eventTeal)
          Text(Localization.string(.holiday))
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(.eventTeal)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
      }
    }
    .background(Color.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(Color.border, lineWidth: 0.5)
    )
    .shadow(color: Color.shadowColor, radius: 20, x: 0, y: 8)
    .padding(.horizontal, 24)
    .frame(maxWidth: 400)
  }
}
