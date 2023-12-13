REPO_URL = https://github.com/apple/swift-openapi-generator
VERSION = 1.0.0
TMP_DIR = /tmp
REPO_DIR = $(TMP_DIR)/swift-openapi-generator
CLI_EXECUTABLE = $(REPO_DIR)/.build/release/swift-openapi-generator

$(REPO_DIR):
	git clone --branch $(VERSION) --depth 1 $(REPO_URL) $(REPO_DIR)

$(CLI_EXECUTABLE): $(REPO_DIR)
	cd $(REPO_DIR) && swift build -c release --package-path $(REPO_DIR)

all: $(CLI_EXECUTABLE)

generate: $(CLI_EXECUTABLE)
	$(CLI_EXECUTABLE) generate ./openapi.yaml \
		--output-directory ./Sources/ManualGeneratorInvocationClient/Generated \
		--config ./openapi-generator-config.yaml

clean-generator:
	rm -rf $(REPO_DIR)
