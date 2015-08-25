# Get the packages used by the dart project, according to pubspec.yaml
# I don't know why but pub get reverts me... Or perhaps Sublime does?
get-packages:
	pub upgrade

TEST_FILES := $(shell find test -name *.dart ! -name *.part.dart)

check-fmt:
	dartfmt -n lib/main.dart $(TEST_FILES)

lint: get-packages
	dartanalyzer lib/main.dart
	dartanalyzer $(TEST_FILES)

start: get-packages
	./packages/sky/sky_tool start

install: get-packages
	./packages/sky/sky_tool start --install

test: get-packages
	pub run test

clean:
	rm -rf packages
