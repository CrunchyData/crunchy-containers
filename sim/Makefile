
.PHONY: all build clean docker resolve

RELEASE_VERSION := 0.0.1
PROJECT_DIR := $(shell pwd)
BUILD_DIR := $(PROJECT_DIR)/build
DIST_DIR := $(PROJECT_DIR)/dist
VENDOR_DIR := $(PROJECT_DIR)/vendor

BUILD_TARGET := $(PROJECT_DIR)/main.go

all: clean resolve build

clean:
	@echo "Cleaning project..."
	rm -rf $(VENDOR_DIR) $(BUILD_DIR)
	go clean -i

resolve:
	@echo "Resolving dependencies..."
	@glide install

build:
	@echo "Building project..."
	go build -i -o $(BUILD_DIR)/crunchy-sim

docker:
	docker build -t crunchy-sim -f Dockerfile .
	docker tag crunchy-sim crunchydata/crunchy-sim:centos7-$(RELEASE_VERSION)

