# Writing Tools for macOS

This is a new, **native macOS port of Writing Tools**, created entirely by @Aryamirsepasi 🎉

Core functionality works well, and it is still an ongoing work in progress.

---

## System Requirements
Due to the accessibility features the app uses (e.g., automatically selecting the window containing the text and pasting the updated version), **the minimum macOS version required is 14.0**. You also have to allow this accessibility access in System Settings. 
> System Settings → Privacy & Security → Accessibility → Press the plus (+) button → Add *writing-tools* and enable access.

---

## How to Build This Project

Since the `.xcodeproj` file is excluded, you can still build the project manually by following these steps:
This guide will help you properly set up the Writing Tools macOS project in Xcode.

## System Requirements
- macOS 14.0 or later
- Xcode 15.0 or later
- Git

## Manual Build Steps

1. **Install Xcode**
   - Download and install Xcode from the App Store
   - Launch Xcode once installed and complete any additional component installations

2. **Clone the Repository**
   - Open Terminal and navigate to the directory where you want to store the project:
   ```bash
   git clone https://github.com/theJayTea/WritingTools.git
   ```

3. **Open in Xcode**
   - Open Xcode
   - Select "Open an existing project..." from the options.
   - Navigate to the macOS folder within the WritingTools directory that you cloned previously, and select "writing-tools.xcodeproj"

4. **Configure Project Settings**
   - In Xcode, select the project in the Navigator pane.
   - Under "Targets", select "writing-tools"
   - Set the following:
     - Deployment Target: macOS 14.0
     - Signing & Capabilities: Add your development team

5. **Build and Run**
   - In Xcode, select "My Mac" as the run destination
   - Click the Play button or press ⌘R to build and run

## Additional Notes
- The project requires macOS 14.0+ due to accessibility features
- Make sure all required permissions are granted when first launching the app
- For development, ensure you have the latest Xcode Command Line Tools installed

---

## Credits

The macOS port is being developed by **Aryamirsepasi**. [GitHub](https://github.com/Aryamirsepasi)

The amazing gemini picture processing functionality was created by **Joaov41**. [GitHub](https://github.com/Joaov41)

Special Thanks to @sindresorhus for developing a great and stable keyboard shortcuts package for Swift. [GitHub](https://github.com/sindresorhus/KeyboardShortcuts)

Huge shoutout to MLX Swift Team, creating local LLM compatibility on Apple silicon Macs. [GitHub](https://github.com/ml-explore/mlx-swift-examples)
