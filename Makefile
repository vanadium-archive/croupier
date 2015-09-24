# This beginning section is used to setup the environment for running with mojo_shell.
ETHER_DIR := $(JIRI_ROOT)/release/mojo/syncbase
CROUPIER_DIR := $(shell pwd)
SHELL := /bin/bash -euo pipefail

ifdef ANDROID
	MOJO_ANDROID_FLAGS := --android

	MOJO_BUILD_DIR := $(MOJO_DIR)/src/out/android_Debug
	ETHER_BUILD_DIR := $(ETHER_DIR)/gen/mojo/android

	SYNCBASE_DATA_DIR := /data/data/org.chromium.mojo.shell/app_home/syncbase_data
else
	MOJO_BUILD_DIR := $(MOJO_DIR)/src/out/Debug
	ETHER_BUILD_DIR := $(ETHER_DIR)/gen/mojo/linux_amd64

	SYNCBASE_DATA_DIR := /tmp/syncbase_data
endif

# NOTE(nlacasse): Running Go Mojo services requires passing the
# --enable-multiprocess flag to mojo_shell.  This is because the Go runtime is
# very large, and can interfere with C++ memory if they are in the same
# process.
MOJO_SHELL_FLAGS := -v --enable-multiprocess \
	--config-alias ETHER_DIR=$(ETHER_DIR) \
	--config-alias ETHER_BUILD_DIR=$(ETHER_BUILD_DIR) \
	--config-alias CROUPIER_DIR=$(CROUPIER_DIR)


.DELETE_ON_ERROR:

# Get the packages used by the dart project, according to pubspec.yaml
# Can also use `pub get`, but Sublime occasionally reverts me to an ealier version.
# Only `pub upgrade` can escape such a thing.
packages: pubspec.yaml
	pub upgrade

DART_LIB_FILES := $(shell find lib -name *.dart ! -name *.part.dart)
DART_TEST_FILES := $(shell find test -name *.dart ! -name *.part.dart)

.PHONY: dartfmt
dartfmt:
	dartfmt -w $(DART_LIB_FILES) $(DART_TEST_FILES)

.PHONY: lint
lint: packages
	dartanalyzer lib/main.dart | grep -v "\[warning\] The imported libraries"
	dartanalyzer $(DART_TEST_FILES) | grep -v "\[warning\] The imported libraries"

.PHONY: build
build: croupier.flx

croupier.flx: packages
	pub run sky_tools -v build --manifest manifest.yaml --output-file $@

.PHONY: start
start: croupier.flx env-check packages
	pub run sky_tools -v --very-verbose run_mojo --mojo-path $(MOJO_DIR)/src --app $< $(MOJO_ANDROID_FLAGS)

.PHONY: mock
mock:
	mv lib/src/syncbase/log_writer.dart lib/src/syncbase/log_writer.dart.backup
	cp lib/src/mocks/log_writer.dart lib/src/syncbase/

.PHONY: unmock
unmock:
	mv lib/src/syncbase/log_writer.dart.backup lib/src/syncbase/log_writer.dart

.PHONY: install
install: packages
	./packages/sky/sky_tool start --install --checked

.PHONY: env-check
env-check:
ifndef MOJO_DIR
	$(error MOJO_DIR is not set)
endif
ifndef JIRI_ROOT
	$(error JIRI_ROOT is not set)
endif
ifeq ($(wildcard $(MOJO_BUILD_DIR)),)
	$(error ERROR: $(MOJO_BUILD_DIR) does not exist.  Please see README.md for instructions on compiling Mojo resources.)
endif

# TODO(alexfandrianto): I split off the syncbase logic from game.dart because it
# would not run in a stand-alone VM. We will need to add mojo_test eventually.
.PHONY: test
test: packages
	# Protect src/syncbase/log_writer.dart
	mv lib/src/syncbase/log_writer.dart lib/src/syncbase/log_writer.dart.backup
	cp lib/src/mocks/log_writer.dart lib/src/syncbase/
	pub run test -r expanded $(DART_TEST_FILES) || (mv lib/src/syncbase/log_writer.dart.backup lib/src/syncbase/log_writer.dart && exit 1)
	mv lib/src/syncbase/log_writer.dart.backup lib/src/syncbase/log_writer.dart

.PHONY: clean
clean:
	rm -f croupier.flx snapshot_blob.bin

.PHONY: veryclean
veryclean: clean
	rm -rf .packages .pub packages pubspec.lock
