BINARY_NAME=planner
SCALEOUT_PLUGIN=scale_out
RMPOD_PLUGIN=rm_pod
RDT_PLUGIN=rdt
CPU_PLUGIN=cpu_scale
GO_CILINT_CHECKERS=errcheck,goimports,gosec,gosimple,govet,ineffassign,nilerr,revive,staticcheck,unused
DOCKER_IMAGE_VERSION=0.2.0

api:
	hack/generate_code.sh

golangci-lint:
	golangci-lint run --color always -E ${GO_CILINT_CHECKERS} --timeout=5m -v ./...

proto:
	hack/generate_protobuf.sh

gen_code: api proto

build:
	CGO_ENABLED=0 go build -o bin/${BINARY_NAME} cmd/main.go

build-plugin-scaleout:
	CGO_ENABLED=0 go build -o bin/plugins/${SCALEOUT_PLUGIN} plugins/${SCALEOUT_PLUGIN}/cmd/${SCALEOUT_PLUGIN}.go

build-plugin-rmpod:
	CGO_ENABLED=0 go build -o bin/plugins/${RMPOD_PLUGIN} plugins/${RMPOD_PLUGIN}/cmd/${RMPOD_PLUGIN}.go

build-plugin-rdt:
	CGO_ENABLED=0 go build -o bin/plugins/${RDT_PLUGIN} plugins/${RDT_PLUGIN}/cmd/${RDT_PLUGIN}.go

build-plugin-cpu:
	CGO_ENABLED=0 go build -o bin/plugins/${CPU_PLUGIN} plugins/${CPU_PLUGIN}/cmd/${CPU_PLUGIN}.go

build-plugins: build-plugin-scaleout build-plugin-rmpod build-plugin-rdt build-plugin-cpu

# controller-images:
# 	docker build -t planner:${DOCKER_IMAGE_VERSION} . --no-cache --pull

giannispetsis-controller-images:
	docker build -t giannispetsis/planner:${DOCKER_IMAGE_VERSION} . --no-cache --pull

	docker push giannispetsis/planner:${DOCKER_IMAGE_VERSION}

# plugin-images:
# 	docker build -t scaleout:${DOCKER_IMAGE_VERSION} -f plugins/scale_out/Dockerfile . --no-cache --pull
# 	docker build -t rmpod:${DOCKER_IMAGE_VERSION} -f plugins/rm_pod/Dockerfile . --no-cache --pull
# 	docker build -t rdt:${DOCKER_IMAGE_VERSION} -f plugins/rdt/Dockerfile . --no-cache --pull
# 	docker build -t cpuscale:${DOCKER_IMAGE_VERSION} -f plugins/cpu_scale/Dockerfile . --no-cache --pull

giannispetsis-plugin-images:
	docker build -t giannispetsis/scale_out:${DOCKER_IMAGE_VERSION} -f plugins/scale_out/Dockerfile . --no-cache --pull
	docker build -t giannispetsis/rmpod:${DOCKER_IMAGE_VERSION} -f plugins/rm_pod/Dockerfile . --no-cache --pull
	docker build -t giannispetsis/rdt:${DOCKER_IMAGE_VERSION} -f plugins/rdt/Dockerfile . --no-cache --pull
	docker build -t giannispetsis/cpuscale:${DOCKER_IMAGE_VERSION} -f plugins/cpu_scale/Dockerfile . --no-cache --pull

	docker push giannispetsis/scale_out:${DOCKER_IMAGE_VERSION}
	docker push giannispetsis/rmpod:${DOCKER_IMAGE_VERSION}
	docker push giannispetsis/rdt:${DOCKER_IMAGE_VERSION}
	docker push giannispetsis/cpuscale:${DOCKER_IMAGE_VERSION}

giannispetsis-apply-plugins:
	kubectl apply -f plugins/cpu_scale/cpu-scale-actuator-plugin.yaml
	kubectl apply -f plugins/rdt/rdt-actuator-plugin.yaml
	kubectl apply -f plugins/rm_pod/rmpod-actuator-plugin.yaml
	kubectl apply -f plugins/scale_out/scaleout-actuator-plugin.yaml
	
giannispetsis-delete-plugins:
	kubectl delete -f plugins/cpu_scale/cpu-scale-actuator-plugin.yaml
	kubectl delete -f plugins/rdt/rdt-actuator-plugin.yaml
	kubectl delete -f plugins/rm_pod/rmpod-actuator-plugin.yaml
	kubectl delete -f plugins/scale_out/scaleout-actuator-plugin.yaml

giannispetsis-delete-planner:
	kubectl delete -n ido -f artefacts/deploy/manifest.yaml


giannispetsis-delete-all: giannispetsis-delete-plugins giannispetsis-delete-planner

all-images: controller-images plugin-images

all: gen_code build build-plugins

run:
	./bin/${BINARY_NAME}

build_and_run: build run

prepare-build:
	go mod download
	go mod tidy

utest:
	go test -count=1 -v ./...

test:
	hack/run_test.sh

benchmark:
	go test -bench=. ./... -run=^$

clean:
	go clean --cache
	rm -rf bin/*
