DART_LIB_FILES_ALL := $(shell find lib -name *.dart)
DART_TEST_FILES_ALL := $(shell find test -name *.dart)
DART_TEST_FILES := $(shell find test -name *.dart ! -name *.part.dart)

# This section is used to setup the environment for running with mojo_shell.
CROUPIER_DIR := $(shell pwd)
DISCOVERY_DIR := $(JIRI_ROOT)/release/mojo/discovery
SHELL := /bin/bash -euo pipefail

# Flags for Syncbase service running as Mojo service.
SYNCBASE_FLAGS := --v=0

ifdef ANDROID
	# Parse the adb devices output to obtain the correct device id.
	# sed takes out the ANDROID_PLUS_ONE'th row of the output
	# awk takes just the first bit of the line (before whitespace).
	ANDROID_PLUS_ONE := $(shell echo $(ANDROID) \+ 1 | bc)
	DEVICE_ID := $(shell adb devices | sed -n $(ANDROID_PLUS_ONE)p | awk '{ print $$1; }')
endif

ifdef ANDROID
	MOJO_ANDROID_FLAGS := --android
	SYNCBASE_MOJO_BIN_DIR := packages/syncbase/mojo_services/android
	DISCOVERY_MOJO_BIN_DIR := $(DISCOVERY_DIR)/gen/mojo/android

	# Location of mounttable on syncslides-alpha network.
	MOUNTTABLE := /192.168.86.254:8101
	# Name to mount under.
	NAME := croupier

	APP_HOME_DIR = /data/data/org.chromium.mojo.shell/app_home
	ANDROID_CREDS_DIR := /sdcard/v23creds

	SYNCBASE_FLAGS += --logtostderr=true \
		--root-dir=$(APP_HOME_DIR)/syncbase_data \
		--v23.credentials=$(ANDROID_CREDS_DIR) \
		--v23.namespace.root=$(MOUNTTABLE)

ifeq ($(ANDROID), 1)
	# If ANDROID is set to 1 exactly, then treat it like the first device.
	# TODO(alexfandrianto): If we can do a better job of this, we won't have to
	# special-case the first device.
	SYNCBASE_FLAGS += --name=$(NAME)
else
	# It turns out that the other syncbases need to be mounted too.
	# If not, it looks like they won't sync values to each other.
	SYNCBASE_FLAGS += --name=foo$(ANDROID)
endif

else
	SYNCBASE_MOJO_BIN_DIR := packages/syncbase/mojo_services/linux_amd64
	DISCOVERY_MOJO_BIN_DIR := $(DISCOVERY_DIR)/gen/mojo/linux_amd64
	SYNCBASE_FLAGS += --root-dir=$(PWD)/tmp/syncbase_data --v23.credentials=$(PWD)/creds
endif

# We should consider combining these URLs and hosting our *.mojo files.
# https://github.com/vanadium/issues/issues/834
export SYNCBASE_SERVER_URL := https://mojo.v.io/syncbase_server.mojo
export DISCOVERY_SERVER_URL := https://mojo2.v.io/discovery.mojo
MOJO_SHELL_FLAGS := --enable-multiprocess \
	--map-origin="https://mojo2.v.io=$(DISCOVERY_MOJO_BIN_DIR)" --args-for="$(DISCOVERY_SERVER_URL) host$(ANDROID) mdns" \
	--map-origin="https://mojo.v.io=$(SYNCBASE_MOJO_BIN_DIR)" --args-for="$(SYNCBASE_SERVER_URL) $(SYNCBASE_FLAGS)"

ifdef ANDROID
	MOJO_SHELL_FLAGS +=  --target-device $(DEVICE_ID)
endif

# Runs a sky app.
# $1 is location of flx file.
define RUN_SKY_APP
	pub run sky_tools -v --very-verbose run_mojo \
	--app $1 \
	$(MOJO_ANDROID_FLAGS) \
	--mojo-path $(MOJO_DIR)/src \
	--checked \
	--mojo-debug \
	-- $(MOJO_SHELL_FLAGS) \
	--no-config-file \
	--free-host-ports
endef

.DELETE_ON_ERROR:

# Get the packages used by the dart project, according to pubspec.yaml
# Can also use `pub get`, but Sublime occasionally reverts me to an ealier version.
# Only `pub upgrade` can escape such a thing.
packages: pubspec.yaml
	pub upgrade

# Builds mounttabled and principal.
bin: | env-check
	jiri go build -a -o $@/mounttabled v.io/x/ref/services/mounttable/mounttabled
	jiri go build -a -o $@/principal v.io/x/ref/cmd/principal
	touch $@

.PHONY: creds
creds: | bin
	./bin/principal seekblessings --v23.credentials creds
	touch $@

.PHONY: dartfmt
dartfmt:
	dartfmt -w $(DART_LIB_FILES_ALL) $(DART_TEST_FILES_ALL)

.PHONY: lint
lint: packages
	dartanalyzer lib/main.dart | grep -v "\[warning\] The imported libraries"
	dartanalyzer $(DART_TEST_FILES) | grep -v "\[warning\] The imported libraries"

.PHONY: build
build: croupier.flx

croupier.flx: packages $(DART_LIB_FILES_ALL)
	pub run sky_tools -v build --manifest manifest.yaml --output-file $@

# Starts the app on the specified ANDROID device.
# Don't forget to make creds first if they are not present.
.PHONY: start
start: croupier.flx env-check packages
ifdef ANDROID
	# Make creds dir if it does not exist.
	mkdir -p creds
	adb -s $(DEVICE_ID) push -p $(PWD)/creds $(ANDROID_CREDS_DIR)
endif
	$(call RUN_SKY_APP,$<)

.PHONY: mock
mock:
	mv lib/src/syncbase/log_writer.dart lib/src/syncbase/log_writer.dart.backup
	mv lib/src/syncbase/settings_manager.dart lib/src/syncbase/settings_manager.dart.backup
	cp lib/src/mocks/log_writer.dart lib/src/syncbase/
	cp lib/src/mocks/settings_manager.dart lib/src/syncbase/

.PHONY: unmock
unmock:
	mv lib/src/syncbase/log_writer.dart.backup lib/src/syncbase/log_writer.dart
	mv lib/src/syncbase/settings_manager.dart.backup lib/src/syncbase/settings_manager.dart

.PHONY: env-check
env-check:
ifndef MOJO_DIR
	$(error MOJO_DIR is not set)
endif
ifndef JIRI_ROOT
	$(error JIRI_ROOT is not set)
endif

# TODO(alexfandrianto): I split off the syncbase logic from game.dart because it
# would not run in a stand-alone VM. We will need to add mojo_test eventually.
.PHONY: test
test: packages
	# Mock the syncbase implementations and unmock regardless of the test outcome.
	$(MAKE) mock
	pub run test -r expanded $(DART_TEST_FILES) || ($(MAKE) unmock && exit 1)
	$(MAKE) unmock

.PHONY: clean
clean:
ifdef ANDROID
	# Clean syncbase data dir.
	adb -s $(DEVICE_ID) shell rm -rf $(APP_HOME_DIR)/syncbase_data
endif
	rm -f croupier.flx snapshot_blob.bin
	rm -rf bin tmp

.PHONY: clean-creds
clean-creds:
ifdef ANDROID
	# Clean syncbase creds dir.
	adb -s $(DEVICE_ID) shell rm -rf $(ANDROID_CREDS_DIR)
endif
	rm -rf creds

.PHONY: veryclean
veryclean: clean clean-creds
	rm -rf .packages .pub packages pubspec.lock
