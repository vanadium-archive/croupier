syncbase_port ?= 4000
id ?= $(shell if test -e tmp/id; then cat tmp/id; else PATH=$(PATH) bin/cuid; fi)
name ?= syncbase

PATH := ./bin/:$(PATH)
go_files := $(shell find ./src -name "*.go")

export GOPATH := $(JIRI_ROOT)/release/projects/croupier/go:$(GOPATH)

bin/principal:
	jiri go build -a -o $@ v.io/x/ref/cmd/principal

bin/syncbased:
	jiri go build -a -o $@ v.io/x/ref/services/syncbase/syncbased

tmp:
	mkdir -p $@

credentials: bin/principal
	bin/principal seekblessings --v23.credentials ./credentials
	touch $@

.PHONY:
delete:
	rm -rf tmp/$(name)

.PHONY:
syncbase: delete bin/syncbased credentials tmp
	$(eval blessing := $(shell bin/principal dump --v23.credentials=./credentials -s=true))
	$(eval email := $(subst dev.v.io:u:,,$(blessing)))
	bin/syncbased \
		--v=5 \
		--alsologtostderr=false \
		--root-dir=tmp/$(name) \
		--name=users/$(email)/croupier/$(name) \
		--v23.credentials=credentials \
		--v23.permissions.literal='{"Admin":{"In":["..."]},"Write":{"In":["..."]},"Read":{"In":["..."]},"Resolve":{"In":["..."]},"Debug":{"In":["..."]}}'

test: src/golang.org/x/mobile/cmd/gomobile vet
	jiri go test hearts/...

fmt: src/golang.org/x/mobile/cmd/gomobile
	jiri go fmt hearts/...

vet: src/golang.org/x/mobile/cmd/gomobile
	jiri go vet hearts/...

# This project depends on gomobile, which is retrieved by `go get`.
# Note: gomobile is gotten to the src/golang.org area because of how this
# Makefile sets its GOPATH, which makes it easier to delete.
src/golang.org/x/mobile/cmd/gomobile:
	go get golang.org/x/mobile/cmd/gomobile

# Builds the Hearts binary.
bin/hearts: $(go_files) src/golang.org/x/mobile/cmd/gomobile | fmt
	jiri go build -a -o $@ hearts

# It seems that gomobile expects assets to be part of the working directory.
# This symlink copies the src/hearts/assets folder down.
assets:
	ln -sf src/hearts/assets assets

.PHONY: hearts
hearts: bin/hearts assets credentials
	bin/hearts \
    --v23.tcp.address=:$(syncbase_port) \
	--v23.credentials=credentials

.PHONY: clean
clean:
	rm -f assets
	rm -rf bin
	rm -rf credentials
	rm -rf pkg
	rm -rf src/golang.org/x/mobile/cmd/gomobile
	rm -rf tmp/syncbase

all: bin/hearts

# Switch mountpoints by replacing the --name flag in syncbase with the following line:
#
#--name=/192.168.86.254:8101/croupier/$(name) \
