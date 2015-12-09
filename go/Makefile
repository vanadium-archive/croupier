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

test:
	jiri go test hearts/...

fmt:
	jiri go fmt hearts/...

vet:
	jiri go vet hearts/...

all: fmt 

# Switch mountpoints by replacing the --name flag in syncbase with the following line:
# 
#--name=/192.168.86.254:8101/croupier/$(name) \