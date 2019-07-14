.PHONY: all lint test coverage

BUILD_DIR := ./build
PROFILE_LOG := $(BUILD_DIR)/profile.txt
COVERAGE_OUTPUT := $(BUILD_DIR)/coverage.xml
COVIMERAGE_DATA_FILE := $(BUILD_DIR)/.coverage.covimerage
SHELL := bash -O globstar

all: lint test

lint:
	vimlparser plugin/*.vim autoload/**/*.vim > /dev/null
	vint plugin autoload

test:
	themis

coverage:
	mkdir -p $(BUILD_DIR)
	rm -f $(COVERAGE_OUTPUT) $(PROFILE_LOG) $(COVIMERAGE_DATA_FILE)
	PROFILE_LOG=$(PROFILE_LOG) themis
	covimerage write_coverage $(PROFILE_LOG) --data-file $(COVIMERAGE_DATA_FILE)
	coverage xml -o $(COVERAGE_OUTPUT)
	coverage report
