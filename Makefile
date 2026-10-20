WORKSPACE := MassMates.xcworkspace
SCHEME := MassMates
GENERIC_DEST := generic/platform=iOS Simulator
SIMULATOR_ID := $(shell xcrun simctl list devices available | grep -E "Booted" | head -n 1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
ifeq ($(SIMULATOR_ID),)
SIMULATOR_ID := $(shell xcrun simctl list devices available | grep -E "\([0-9A-F-]{36}\)" | head -n 1 | sed -E 's/.*\(([0-9A-F-]+)\).*/\1/')
endif
TEST_DEST := platform=iOS Simulator,id=$(SIMULATOR_ID)

.PHONY: help generate build rebuild test-build test clean

help:
	@printf "Targets:\n"
	@printf "  make generate    Generate Xcode workspace via Tuist (--no-open)\n"
	@printf "  make build       Incremental build (-quiet, zero log bloat)\n"
	@printf "  make rebuild     Generate project + build (-quiet)\n"
	@printf "  make test-build  Compile app and unit tests (-quiet)\n"
	@printf "  make test        Run Swift Testing unit tests (-quiet)\n"
	@printf "  make clean       Clean build artifacts\n"

generate:
	@tuist generate --no-open

build:
	@xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -destination '$(GENERIC_DEST)' build CODE_SIGNING_ALLOWED=NO -quiet

rebuild: generate build

test-build:
	@xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -destination '$(GENERIC_DEST)' build-for-testing CODE_SIGNING_ALLOWED=NO -quiet

test:
	@xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) -destination '$(TEST_DEST)' test CODE_SIGNING_ALLOWED=NO -quiet

clean:
	@xcodebuild -workspace $(WORKSPACE) -scheme $(SCHEME) clean -quiet
