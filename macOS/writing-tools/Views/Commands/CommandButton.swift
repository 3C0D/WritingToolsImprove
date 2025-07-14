import SwiftUI

struct CommandButton: View {
    let command: CommandModel
    let index: Int?
    let isEditing: Bool
    let isLoading: Bool
    let onTap: () -> Void
    let onEdit: () -> Void
    let onDelete: () -> Void
    let onMove: ((Int, Int) -> Void)?

    @State private var dragOffset = CGSize.zero
    @State private var isDragging = false
    
    var body: some View {
        ZStack {
            // Main button wrapper
            Button(action: {
                if !isEditing && !isLoading && !isDragging {
                    onTap()
                }
            }) {
                HStack {
                    // Leave space for the delete button if in edit mode
                    if isEditing {
                        Color.clear
                            .frame(width: 10, height: 16)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: command.icon)
                        Text(index != nil ? "\(index!). \(command.name)" : command.name)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    // Leave space for the edit button if in edit mode
                    if isEditing {
                        Color.clear
                            .frame(width: 10, height: 16)
                    }
                }
                .frame(maxWidth: 140)
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
            }
            .buttonStyle(LoadingButtonStyle(isLoading: isLoading))
            .disabled(isLoading || isEditing)
            .offset(dragOffset)
            .scaleEffect(isDragging ? 1.05 : 1.0)
            .animation(.spring(response: 0.3), value: isDragging)
            .onTapGesture(count: 2) {
                // Double-tap to enable drag mode
                if !isEditing && !isLoading && onMove != nil {
                    withAnimation(.spring(response: 0.3)) {
                        isDragging = true
                    }
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        if isDragging || !isEditing {
                            dragOffset = value.translation
                            if !isDragging {
                                withAnimation(.spring(response: 0.3)) {
                                    isDragging = true
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        if isDragging {
                            // Calculate drop position based on drag distance
                            let dragDistance = value.translation.x
                            let buttonWidth: CGFloat = 140 + 8 // button width + spacing
                            let positionChange = Int(dragDistance / buttonWidth)

                            if let currentIndex = index, let onMove = onMove, positionChange != 0 {
                                let newIndex = max(1, min(currentIndex + positionChange, currentIndex + positionChange))
                                onMove(currentIndex - 1, newIndex - 1) // Convert to 0-based for array operations
                            }

                            // Reset drag state
                            withAnimation(.spring(response: 0.3)) {
                                isDragging = false
                                dragOffset = .zero
                            }
                        }
                    }
            )
            .contextMenu {
                if !isEditing && !isLoading {
                    Button(action: onEdit) {
                        Label("Edit Command", systemImage: "pencil")
                    }

                    if !command.isBuiltIn {
                        Button(action: onDelete) {
                            Label("Delete Command", systemImage: "trash")
                        }
                    }
                }
            }

            // Overlay edit controls when in edit mode
            if isEditing {
                HStack {
                    Button(action: onDelete) {
                        Image(systemName: "minus.circle")
                            .foregroundColor(.red)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                    
                    Button(action: onEdit) {
                        Image(systemName: "pencil.circle")
                            .foregroundColor(.blue)
                            .padding(8)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: 140)
                .padding(.horizontal, 8)
            }
        }
    }
}

struct LoadingButtonStyle: ButtonStyle {
    var isLoading: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(isLoading ? 0.5 : 1.0)
            .overlay(
                Group {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                    }
                }
            )
    }
}

#Preview {
    VStack {
        CommandButton(
            command: CommandModel.proofread,
            index: 1,
            isEditing: false,
            isLoading: false,
            onTap: {},
            onEdit: {},
            onDelete: {},
            onMove: { _, _ in }
        )

        CommandButton(
            command: CommandModel.proofread,
            index: 2,
            isEditing: true,
            isLoading: false,
            onTap: {},
            onEdit: {},
            onDelete: {},
            onMove: { _, _ in }
        )
    }
}
