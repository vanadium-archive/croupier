# Get the packages used by the dart project, according to pubspec.yaml
# Can also use `pub get`, but Sublime occasionally reverts me to an ealier version.
# Only `pub upgrade` can escape such a thing.
get-packages: pubspec.yaml
	pub upgrade

TEST_FILES := $(shell find test -name *.dart ! -name *.part.dart)

check-fmt:
	dartfmt -n lib/main.dart $(TEST_FILES)

lint:
	dartanalyzer lib/main.dart
	dartanalyzer $(TEST_FILES)

start:
	./packages/sky/sky_tool start

install: get-packages
	./packages/sky/sky_tool start --install

# Could use `pub run test` too, but I like seeing every assertion print out.
test:
	dart --checked $(TEST_FILES)

clean:
	rm -rf packages

.PHONY: check-fmt lint start install test clean