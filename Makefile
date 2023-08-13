PROJECT_NAME=troll
PROJECT_VERSION=1.0

DOCKER_DEPS_REPO?=${PROJECT_NAME}/
DOCKER_DEPS_IMAGE?=${PROJECT_NAME}_build
DOCKER_DEPS_CONTAINER?=${DOCKER_DEPS_IMAGE}
DOCKER_DEPS_FILE?=Dockerfile

DOCKER_DEPS_IMAGE_BUILD_FLAGS?=--no-cache=true

DOCKER_PREPEND_MAKEFILES?=
DOCKER_APPEND_MAKEFILES?=

DOCKER_CMAKE_FLAGS?=

DOCKER_SHELL?=bash
LOCAL_SOURCE_PATH?=${CURDIR}
DOCKER_SOURCE_PATH?=/${PROJECT_NAME}
DOCKER_BUILD_DIR?=build
DOCKER_APP_PATH?=build/src
DOCKER_CTEST_TIMEOUT?=5000

KF_DOCKER_COMPOSE?=kf-docker-compose.yml

DOCKER_BASIC_RUN_PARAMS?=-it --init --rm \
					  --memory-swap=-1 \
					  --ulimit core=-1 \
					  --name="${DOCKER_DEPS_IMAGE}" \
					  --workdir=${DOCKER_SOURCE_PATH} \
					  --mount type=bind,source=${LOCAL_SOURCE_PATH},target=${DOCKER_SOURCE_PATH} \
					  ${DOCKER_DEPS_IMAGE}:${PROJECT_VERSION}

IF_CONTAINER_RUNS=$(shell docker container inspect -f '{{.State.Running}}' ${DOCKER_DEPS_CONTAINER} 2>/dev/null)

.DEFAULT_GOAL:=build

-include ${DOCKER_PREPEND_MAKEFILES}

.PHONY: help
help: ##
	@cat $(MAKEFILE_LIST) | grep -E '^[a-zA-Z_-]+:.*?## .*$$' | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: gen-cmake
gen-cmake: ## Generate cmake files, used internally
	docker run ${DOCKER_BASIC_RUN_PARAMS} \
		${DOCKER_SHELL} -c \
		"mkdir -p ${DOCKER_SOURCE_PATH}/${DOCKER_BUILD_DIR} && \
		cd ${DOCKER_BUILD_DIR} && \
		cmake ${DOCKER_CMAKE_FLAGS} .."
	@echo
	@echo "CMake finished."

.PHONY: build
build: gen-cmake ## Build source
	docker run ${DOCKER_BASIC_RUN_PARAMS} \
		${DOCKER_SHELL} -c \
		"cd ${DOCKER_BUILD_DIR} && \
		make -j $$(nproc) ${TARGET}"

	@echo
	@echo "Build finished. The binaries are in ${CURDIR}/${DOCKER_BUILD_DIR}"

.PHONY: run-docker
run-docker: ## Connect to docker instance
	docker run ${DOCKER_BASIC_RUN_PARAMS} \
		${DOCKER_SHELL}

.PHONY: run-app
run-app: ## run application
	docker run ${DOCKER_BASIC_RUN_PARAMS} \
		${DOCKER_SHELL} -c \
		"./${DOCKER_APP_PATH}/${PROJECT_NAME}"

.PHONY: test
test: ## Run all tests
	docker run ${DOCKER_BASIC_RUN_PARAMS} \
		${DOCKER_SHELL} -c \
		"mkdir -p ${DOCKER_TEST_CORE_DIR} && \
		cd ${DOCKER_BUILD_DIR} && \
		ctest --timeout ${DOCKER_CTEST_TIMEOUT} --output-on-failure"

.PHONY: login
login: ## Login to the container
	@if [ "${IF_CONTAINER_RUNS}" != "true" ]; then \
		docker run ${DOCKER_BASIC_RUN_PARAMS} \
			${DOCKER_SHELL}; \
	else \
		docker exec -it ${DOCKER_DEPS_CONTAINER} \
			${DOCKER_SHELL}; \
	fi

.PHONY: clean
clean: ## Clean build directory
	docker run ${DOCKER_BASIC_RUN_PARAMS} \
		${DOCKER_SHELL} -c \
		"rm -rf ${DOCKER_BUILD_DIR}"
	


.PHONY: troll-up
kafka-up: ## Start kafka broker
	docker-compose -f ${KF_DOCKER_COMPOSE} up

.PHONY: troll-down
kafka-down: ## Stop kafka broker
	docker-compose -f ${KF_DOCKER_COMPOSE} down

.PHONY: build-docker-image
build-docker-image: ## Build the deps image.
	docker build ${DOCKER_DEPS_IMAGE_BUILD_FLAGS} -t ${DOCKER_DEPS_IMAGE}:${PROJECT_VERSION} \
		-f ./${DOCKER_DEPS_FILE} .
	@echo
	@echo "Build finished. Docker image name: \"${DOCKER_DEPS_IMAGE}:${PROJECT_VERSION}\"."

-include ${DOCKER_APPEND_MAKEFILES}