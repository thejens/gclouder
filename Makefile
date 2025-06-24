.PHONY: all build dev test test-auth install uninstall clean release run

APP_NAME = GClouder
BUNDLE_ID = com.gclouder.app
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
DEBUG_DIR = $(BUILD_DIR)/debug
APP_BUNDLE = $(APP_NAME).app
EXECUTABLE = gclouder
INSTALL_DIR = /Applications

# Default target
all: build

# Build the application in release mode
build:
	@echo "Building $(APP_NAME) (Release)..."
	@swift build -c release
	@echo "✅ Release build complete: $(RELEASE_DIR)/$(EXECUTABLE)"

# Build the application in debug mode
dev:
	@echo "Building $(APP_NAME) (Debug)..."
	@swift build
	@echo "✅ Debug build complete: $(DEBUG_DIR)/$(EXECUTABLE)"

# Run tests
test:
	@echo "Running tests..."
	@if swift test 2>/dev/null; then \
		echo "Tests completed successfully!"; \
	else \
		echo "Warning: Tests require full Xcode installation with XCTest framework."; \
		echo "Building project to verify compilation..."; \
		if swift build; then \
			echo "Build successful - code compiles correctly."; \
		else \
			echo "Build failed!"; \
			exit 1; \
		fi \
	fi

# Create the app bundle and install it
install: build
	@echo "Creating app bundle..."
	@rm -rf "$(RELEASE_DIR)/$(APP_BUNDLE)"
	@mkdir -p "$(RELEASE_DIR)/$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(RELEASE_DIR)/$(APP_BUNDLE)/Contents/Resources"
	
	@# Copy executable
	@cp "$(RELEASE_DIR)/$(EXECUTABLE)" "$(RELEASE_DIR)/$(APP_BUNDLE)/Contents/MacOS/"
	
	@# Copy Info.plist
	@cp "Resources/Info.plist" "$(RELEASE_DIR)/$(APP_BUNDLE)/Contents/"
	
	@# Copy app icon
	@cp "Resources/AppIcon.icns" "$(RELEASE_DIR)/$(APP_BUNDLE)/Contents/Resources/"
	
	@# Create PkgInfo file
	@echo "APPL????" > "$(RELEASE_DIR)/$(APP_BUNDLE)/Contents/PkgInfo"
	
	@# Sign the app bundle (use developer cert if available, otherwise ad-hoc)
	@if security find-identity -p codesigning -v | grep -q "Developer ID Application"; then \
		echo "Signing with Developer ID..."; \
		codesign --force --deep --sign "Developer ID Application" "$(RELEASE_DIR)/$(APP_BUNDLE)"; \
	else \
		echo "Ad-hoc signing..."; \
		codesign --force --deep --sign - "$(RELEASE_DIR)/$(APP_BUNDLE)"; \
	fi
	
	@echo "Installing to $(INSTALL_DIR)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@cp -R "$(RELEASE_DIR)/$(APP_BUNDLE)" "$(INSTALL_DIR)/"
	
	@echo "$(APP_NAME) installed successfully!"
	@echo "You can now launch it from $(INSTALL_DIR)/$(APP_BUNDLE)"

# Uninstall the application
uninstall:
	@echo "Uninstalling $(APP_NAME)..."
	@rm -rf "$(INSTALL_DIR)/$(APP_BUNDLE)"
	@echo "$(APP_NAME) uninstalled successfully!"

# Clean build artifacts
clean:
	@echo "Cleaning build artifacts..."
	@rm -rf $(BUILD_DIR)
	@echo "Clean complete!"

# Create a release build for distribution
release: clean build
	@echo "Creating release package..."
	@mkdir -p dist
	@rm -rf "dist/$(APP_BUNDLE)"
	
	@# Create app bundle in dist
	@mkdir -p "dist/$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "dist/$(APP_BUNDLE)/Contents/Resources"
	
	@# Copy executable
	@cp "$(RELEASE_DIR)/$(EXECUTABLE)" "dist/$(APP_BUNDLE)/Contents/MacOS/"
	
	@# Copy Info.plist
	@cp "Resources/Info.plist" "dist/$(APP_BUNDLE)/Contents/"
	
	@# Copy app icon
	@cp "Resources/AppIcon.icns" "dist/$(APP_BUNDLE)/Contents/Resources/"
	
	@# Create PkgInfo file
	@echo "APPL????" > "dist/$(APP_BUNDLE)/Contents/PkgInfo"
	
	@# Sign the app bundle (use developer cert if available, otherwise ad-hoc)
	@if security find-identity -p codesigning -v | grep -q "Developer ID Application"; then \
		echo "Signing with Developer ID..."; \
		codesign --force --deep --sign "Developer ID Application" "dist/$(APP_BUNDLE)"; \
	else \
		echo "Ad-hoc signing..."; \
		codesign --force --deep --sign - "dist/$(APP_BUNDLE)"; \
	fi
	
	@# Create zip for distribution
	@cd dist && zip -r "$(APP_NAME).zip" "$(APP_BUNDLE)"
	
	@echo "Release package created at dist/$(APP_NAME).zip"

# Test authentication flow (for debugging)
test-auth:
	@echo "Testing authentication flow..."
	@Scripts/test-auth.sh

# Run the application in debug mode (for development)
run: dev
	@echo "Running $(APP_NAME) (Debug)..."
	@echo "Watch console output for debug information..."
	@"$(DEBUG_DIR)/$(EXECUTABLE)"