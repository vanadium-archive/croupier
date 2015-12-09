syncbase_port ?= 4000

PATH := ./bin/:$(PATH)

bin/principal:
	jiri go build -a -o $@ v.io/x/ref/cmd/principal

credentials: bin/principal
	bin/principal seekblessings --v23.credentials credentials
	touch $@

.PHONY:
hearts: fmt credentials
	jiri go build hearts
	./hearts \
    --v23.tcp.address=:$(syncbase_port) \
	--v23.credentials=credentials

test:
	jiri go test hearts/...

fmt:
	jiri go fmt hearts/...

vet:
	jiri go vet hearts/...