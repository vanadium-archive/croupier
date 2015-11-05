syncbase_port ?= 4000
id ?= $(shell if test -e tmp/id; then cat tmp/id; else PATH=$(PATH) bin/cuid; fi)
name ?= syncbase

PATH := ./bin/:$(PATH)
go_files := $(shell find ./src -name "*.go")

.PHONY:
start: all
	st --port $(port) --host $(host) --dir public --no-cache --index index.html

bin/principal:
	jiri go build -a -o $@ v.io/x/ref/cmd/principal

bin/syncbased:
	jiri go build -a -o $@ v.io/x/ref/services/syncbase/syncbased

tmp:
	mkdir -p $@

credentials: bin/principal
	principal seekblessings --v23.credentials ./credentials
	touch $@

.PHONY:
delete:
	rm -rf tmp/syncbase_

# Naming collisions for different instances of syncbase for the same user?
# Easy way to make --v23.permissions.literal?
.PHONY:
syncbase: delete bin/syncbased credentials tmp
	$(eval blessing := $(shell bin/principal dump --v23.credentials=./credentials -s=true))
	$(eval email := $(subst dev.v.io/u/,,$(blessing)))
	syncbased \
		--v=5 \
		--alsologtostderr=false \
		--root-dir=tmp/syncbase_$(id) \
		--name=users/$(email)/croupier/$(name) \
		--v23.proxy=proxy \
		--v23.credentials=credentials \
		--v23.permissions.literal='{"Admin":{"In":["..."]},"Write":{"In":["..."]},"Read":{"In":["..."]},"Resolve":{"In":["..."]},"Debug":{"In":["..."]}}'

test:
	jiri go test hearts/...

fmt:
	jiri go fmt hearts/...

vet:
	jiri go vet hearts/...

all: fmt 