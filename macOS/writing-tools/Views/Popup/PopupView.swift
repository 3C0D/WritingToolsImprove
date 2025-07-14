import SwiftUI
import ApplicationServices

struct PopupView: View {
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @AppStorage("use_gradient_theme") private var useGradientTheme = false
    @State private var customText: String = ""
    @State private var isCustomLoading: Bool = false
    @State private var processingCommandId: UUID? = nil

    // Make edit mode publicly accessible with property wrapper
    // This allows the window to observe changes to edit mode
    @State public var isEditMode = false

    @State private var showingCommandsView = false
    @State private var editingCommand: CommandModel? = nil

    // Command slash system
    @State private var showingCommandDropdown = false
    @State private var filteredCommands: [CommandModel] = []
    @State private var selectedCommandIndex = 0
    @FocusState private var isTextFieldFocused: Bool

    let closeAction: () -> Void
    
    // Grid layout for two columns
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Top bar with buttons
            HStack {
                Button(action: {
                    if isEditMode {
                        isEditMode = false
                    } else {
                        closeAction()
                    }
                }) {
                    Image(systemName: isEditMode ? "xmark" : "xmark")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isEditMode ? "Exit Edit Mode" : "Close")
                .padding(.top, 8)
                .padding(.leading, 8)
                
                Spacer()
                
                Button(action: {
                    // Toggle edit mode and notify parent window to adjust size
                    isEditMode.toggle()
                    
                    // Use a notification to trigger window size update
                    NotificationCenter.default.post(name: NSNotification.Name("EditModeChanged"), object: nil)
                }) {
                    Image(systemName: isEditMode ? "checkmark" : "square.and.pencil")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .frame(width: 28, height: 28)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .help(isEditMode ? "Save Changes" : "Edit Commands")
                .padding(.top, 8)
                .padding(.trailing, 8)
            }
            
            // Custom input with send button
            if !isEditMode {
                HStack(spacing: 8) {
                    TextField(
                        appState.selectedText.isEmpty ? "Prompt to apply or command list /" : "Prompt to apply or command list /",
                        text: $customText
                    )
                    .textFieldStyle(.plain)
                    .focused($isTextFieldFocused)
                    .onChange(of: customText) { newValue in
                        handleTextChange(newValue)
                    }
                    .onSubmit {
                        if showingCommandDropdown && selectedCommandIndex < filteredCommands.count {
                            selectCommand(filteredCommands[selectedCommandIndex])
                        } else if !customText.isEmpty && !showingCommandDropdown {
                            processCustomChange()
                        }
                    }
                    .appleStyleTextField(
                        text: customText,
                        isLoading: isCustomLoading,
                        onSubmit: {
                            if showingCommandDropdown && selectedCommandIndex < filteredCommands.count {
                                selectCommand(filteredCommands[selectedCommandIndex])
                            } else if !customText.isEmpty && !showingCommandDropdown {
                                processCustomChange()
                            }
                        }
                    )
                }
                .padding(.horizontal)
            }

            // Command dropdown menu
            if showingCommandDropdown && !filteredCommands.isEmpty {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(filteredCommands.enumerated()), id: \.element.id) { index, command in
                        Button(action: {
                            selectCommand(command)
                        }) {
                            HStack {
                                Image(systemName: command.icon)
                                    .foregroundColor(.accentColor)
                                    .frame(width: 20)

                                if let commandIndex = appState.commandManager.getIndex(for: command) {
                                    Text("\(commandIndex). \(command.name)")
                                        .foregroundColor(.primary)
                                } else {
                                    Text(command.name)
                                        .foregroundColor(.primary)
                                }

                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                index == selectedCommandIndex ?
                                Color.accentColor.opacity(0.2) :
                                Color.clear
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color(.separatorColor), lineWidth: 1)
                )
                .padding(.horizontal)
                .animation(.easeInOut(duration: 0.2), value: showingCommandDropdown)
            }

            if !appState.selectedText.isEmpty || !appState.selectedImages.isEmpty {
                // Command buttons grid
                ScrollView {
                    LazyVGrid(columns: columns, spacing: 8) {
                        ForEach(Array(appState.commandManager.commands.enumerated()), id: \.element.id) { index, command in
                            CommandButton(
                                command: command,
                                index: index + 1,
                                isEditing: isEditMode,
                                isLoading: processingCommandId == command.id,
                                onTap: {
                                    processingCommandId = command.id
                                    Task {
                                        // Process the command and only close when complete
                                        await processCommandAndCloseWhenDone(command)
                                    }
                                },
                                onEdit: {
                                    editingCommand = command
                                    showingCommandsView = true
                                },
                                onDelete: {
                                    print("Deleting command: \(command.name)")
                                    appState.commandManager.deleteCommand(command)

                                    // Notify that a command was deleted to adjust window size
                                    NotificationCenter.default.post(name: NSNotification.Name("CommandsChanged"), object: nil)
                                },
                                onMove: { fromIndex, toIndex in
                                    appState.commandManager.moveCommand(fromOffsets: IndexSet(integer: fromIndex), toOffset: toIndex > fromIndex ? toIndex + 1 : toIndex)

                                    // Notify that commands were reordered
                                    NotificationCenter.default.post(name: NSNotification.Name("CommandsChanged"), object: nil)
                                }
                            )
                        }
                    }
                    .padding(.horizontal, 8)
                }
                .padding(.horizontal, 8)
            }
            
            if isEditMode {
                Button(action: { showingCommandsView = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Manage Commands")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
            }
        }
        .padding(.bottom, 8)
        .windowBackground(useGradient: useGradientTheme)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
        )
        .onAppear {
            isTextFieldFocused = true
        }
        .onKeyPress { keyPress in
            if showingCommandDropdown {
                switch keyPress.key {
                case .upArrow:
                    selectedCommandIndex = max(0, selectedCommandIndex - 1)
                    return .handled
                case .downArrow:
                    selectedCommandIndex = min(filteredCommands.count - 1, selectedCommandIndex + 1)
                    return .handled
                case .escape:
                    showingCommandDropdown = false
                    customText = ""
                    return .handled
                default:
                    return .ignored
                }
            } else {
                // Handle escape to clear input even when dropdown is not showing
                if keyPress.key == .escape {
                    customText = ""
                    showingCommandDropdown = false
                    return .handled
                }
            }
            return .ignored
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.black.opacity(0.2), radius: 10, y: 5)
        .sheet(isPresented: $showingCommandsView) {
            CommandsView(commandManager: appState.commandManager)
                .onDisappear {
                    // Trigger window resize when returning from CommandsView
                    // as commands may have been added/removed
                    NotificationCenter.default.post(name: NSNotification.Name("CommandsChanged"), object: nil)
                }
        }
    }
    
    // Process a command asynchronously and only close the popup when done
    private func processCommandAndCloseWhenDone(_ command: CommandModel) async {
        guard !appState.selectedText.isEmpty else {
            processingCommandId = nil
            return
        }
        
        appState.isProcessing = true
        
        do {
            // Get the systemprompt and user text
            let systemPrompt = command.prompt
            let userText = appState.selectedText
            
            // Process the text with the AI provider
            let result = try await appState.activeProvider.processText(
                systemPrompt: systemPrompt,
                userPrompt: userText,
                images: appState.selectedImages,
                streaming: false
            )
            
            // Handle the result on the main thread
            await MainActor.run {
                if command.useResponseWindow {
                    // Create response window
                    let window = ResponseWindow(
                        title: command.name,
                        content: result,
                        selectedText: userText,
                        option: .proofread // Using proofread as default
                    )
                    
                    WindowManager.shared.addResponseWindow(window)
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                } else {
                    // Directly apply the text if no response window
                    appState.replaceSelectedText(with: result)
                }
                
                // Now close the popup after response is received
                closeAction()
                processingCommandId = nil
            }
        } catch {
            print("Error processing command: \(error.localizedDescription)")
            await MainActor.run {
                processingCommandId = nil
            }
        }
        
        await MainActor.run {
            appState.isProcessing = false
        }
    }
    
    private func processCommand(_ command: CommandModel) {
        guard !appState.selectedText.isEmpty else { return }
        
        appState.processCommand(command)
    }
    
    // Process custom text changes
    private func processCustomChange() {
        guard !customText.isEmpty else { return }
        isCustomLoading = true
        processCustomInstruction(customText)
    }
    
    private func processCustomInstruction(_ instruction: String) {
        guard !instruction.isEmpty else { return }
        appState.isProcessing = true
        
        Task {
            do {
                let systemPrompt = """
                You are a writing and coding assistant. Your sole task is to respond to the user's instruction thoughtfully and comprehensively.
                If the instruction is a question, provide a detailed answer. But always return the best and most accurate answer and not different options. 
                If it's a request for help, provide clear guidance and examples where appropriate. Make sure tu use the language used or specified by the user instruction.
                Use Markdown formatting to make your response more readable.
                """
                
                let userPrompt = appState.selectedText.isEmpty ?
                instruction :
                    """
                    User's instruction: \(instruction)
                    
                    Text:
                    \(appState.selectedText)
                    """
                
                let result = try await appState.activeProvider.processText(
                    systemPrompt: systemPrompt,
                    userPrompt: userPrompt,
                    images: appState.selectedImages,
                    streaming: false
                )
                
                // Always show response in a new window
                await MainActor.run {
                    let window = ResponseWindow(
                        title: "AI Response",
                        content: result,
                        selectedText: appState.selectedText.isEmpty ? instruction : appState.selectedText,
                        option: .proofread // Using proofread as default, the response window will adapt based on content
                    )
                    
                    WindowManager.shared.addResponseWindow(window)
                    window.makeKeyAndOrderFront(nil)
                    window.orderFrontRegardless()
                    
                    customText = ""
                    isCustomLoading = false
                    closeAction()
                }
            } catch {
                print("Error processing text: \(error.localizedDescription)")
                isCustomLoading = false
            }
            
            appState.isProcessing = false
        }
    }

    // MARK: - Command Slash System

    private func handleTextChange(_ newText: String) {
        customText = newText

        if newText.starts(with: "/") {
            let query = String(newText.dropFirst()).lowercased()

            if query.isEmpty {
                // Show all commands when just "/" is typed
                filteredCommands = appState.commandManager.commands
            } else if let index = Int(query), index > 0 && index <= appState.commandManager.commands.count {
                // If it's a number, show filtered list but don't execute yet
                if let command = appState.commandManager.getCommand(at: index) {
                    filteredCommands = [command]
                } else {
                    filteredCommands = []
                }
            } else {
                // Fuzzy search: filter commands by name (contains query)
                filteredCommands = appState.commandManager.commands.filter { command in
                    command.name.lowercased().contains(query)
                }
            }

            showingCommandDropdown = !filteredCommands.isEmpty
            selectedCommandIndex = 0
        } else {
            // Normal text, hide dropdown
            showingCommandDropdown = false
        }
    }

    private func executeCommandByIndex(_ index: Int) {
        guard let command = appState.commandManager.getCommand(at: index) else { return }

        customText = ""
        showingCommandDropdown = false

        processingCommandId = command.id
        Task {
            await processCommandAndCloseWhenDone(command)
        }
    }

    private func selectCommand(_ command: CommandModel) {
        customText = ""
        showingCommandDropdown = false

        processingCommandId = command.id
        Task {
            await processCommandAndCloseWhenDone(command)
        }
    }


}
