import SwiftUI

struct SideSheetModifier<SheetContent: View>: ViewModifier {
  @Binding var isPresented: Bool
  let sheetContent: () -> SheetContent

  func body(content: Content) -> some View {
    ZStack {
      content

      if isPresented {
        Color.backgroundScrim
          .ignoresSafeArea()
          .onTapGesture {
            isPresented = false
          }
          .transition(.opacity)
      }

      HStack(spacing: 0) {
        Spacer()

        if isPresented {
          sheetContent()
            .frame(width: 280)
            .frame(maxHeight: .infinity)
            .background(Color.backgroundSecondary)
            .transition(.move(edge: .trailing))
        }
      }
      .ignoresSafeArea(edges: .bottom)
    }
    .animation(.easeInOut(duration: 0.25), value: isPresented)
  }
}

extension View {
  func sideSheet<Content: View>(
    isPresented: Binding<Bool>,
    @ViewBuilder content: @escaping () -> Content
  ) -> some View {
    modifier(SideSheetModifier(isPresented: isPresented, sheetContent: content))
  }
}
