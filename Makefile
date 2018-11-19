# Makefile from GoInit by @zephinzer (licensed under MIT - ie this line must stay here)
# URL: https://github.com/zephinzer/goinit

# Notes
# - header fonts from http://patorjk.com/software/taag/#p=display&h=2&v=1&f=Slant&t=
#
# Sections
# - bootstrap (init/deinit)
# - development (start)
# - dependencies (dep.*)
# - testing (test.*)
# - compilation (build)
# - containerisation (build.docker.*)
# - publishing (publish.docker.*)
# - versioning (version.*)
# - logging (log.*)
# - data (...files)

## > global variables
# PROJECT_NAME - uses the current directory name, change this if you wish
PROJECT_NAME=$(notdir $(CURDIR))
## / global variables

##     __                __       __                 
##    / /_  ____  ____  / /______/ /__________ _____ 
##   / __ \/ __ \/ __ \/ __/ ___/ __/ ___/ __ `/ __ \
##  / /_/ / /_/ / /_/ / /_(__  ) /_/ /  / /_/ / /_/ /
## /_.___/\____/\____/\__/____/\__/_/   \__,_/ .___/ 
##                                          /_/      
## #bootstrap

# this initialises the project directory
init:
	@$(MAKE) log.info MSG="Creating scripts directory at $(CURDIR)/.scripts..."
	@mkdir -p $(CURDIR)/.scripts
	@$(MAKE) log.info MSG="Creating cache directory at $(CURDIR)/.cache..."
	@mkdir -p $(CURDIR)/.cache
	@echo "*\n!.gitignore" > $(CURDIR)/.cache/.gitignore
	@$(MAKE) log.info MSG="Creating binary directory at $(CURDIR)/bin..."
	@mkdir -p $(CURDIR)/bin
	@echo "*\n!.gitignore" > $(CURDIR)/bin/.gitignore
	@$(MAKE) log.info MSG="Creating vendor directory at $(CURDIR)/vendor..."
	@mkdir -p $(CURDIR)/vendor
	@echo "*\n!.gitignore" > $(CURDIR)/vendor/.gitignore
	@$(MAKE) log.info MSG="Loading Dockerfile for creating images..."
	@if ! [ -e "$(CURDIR)/Dockerfile" ]; then echo "$$DOCKERFILE_CONTENT" > $(CURDIR)/Dockerfile; fi
	@$(MAKE) log.info MSG="Loading .bash_profile for nice shell debugging..."
	@if ! [ -e "$(CURDIR)/.scripts/.bash_profile" ]; then echo "$$BASH_PROFILE_CONTENT" > $(CURDIR)/.scripts/.bash_profile; fi
	@$(MAKE) log.info MSG="Loading auto-run.py for automated test running..."
	@if ! [ -e "$(CURDIR)/.scripts/auto-run.py" ]; then echo "$$AUTO_RUN_TESTS_CONTENT" > $(CURDIR)/.scripts/auto-run.py; fi
	@$(MAKE) log.info MSG="Building development image..."
	@$(MAKE) build.docker.development
	@$(MAKE) log.info MSG="Initialising git repository..."
	@git init
	@git commit --allow-empty -m "initial commit"
# de-initialises the project by removing tooling files related to go init
deinit:
	@$(MAKE) log.warn MSG="Removing ./Dockerfile..."
	@if [ -e "$(CURDIR)/Dockerfile" ]; then rm -rf $(CURDIR)/Dockerfile; fi
	@$(MAKE) log.warn MSG="Removing ./.scripts/.bash_profile..."
	@if [ -e "$(CURDIR)/.scripts/.bash_profile" ]; then rm -rf $(CURDIR)/.scripts/.bash_profile; fi
	@$(MAKE) log.warn MSG="Removing ./.scripts/auto-run.py..."
	@if [ -e "$(CURDIR)/.scripts/auto-run.py" ]; then rm -rf $(CURDIR)/.scripts/auto-run.py; fi

##        __               __                                 __ 
##   ____/ /__ _   _____  / /___  ____  ____ ___  ___  ____  / /_
##  / __  / _ \ | / / _ \/ / __ \/ __ \/ __ `__ \/ _ \/ __ \/ __/
## / /_/ /  __/ |/ /  __/ / /_/ / /_/ / / / / / /  __/ / / / /_  
## \__,_/\___/|___/\___/_/\____/ .___/_/ /_/ /_/\___/_/ /_/\__/  
##                            /_/                                
## #development

start: build.docker.development
	-@docker stop $(PROJECT_NAME)-latest-dev
	-@docker rm $(PROJECT_NAME)-latest-dev
	@$(MAKE) log.info MSG="Creating container \"$(PROJECT_NAME)-latest-dev\" from image \"$(PROJECT_NAME):latest-dev\"..."
	@docker run \
		--network host \
		-v "$(CURDIR):/go/src/app" \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--name $(PROJECT_NAME)-latest-dev \
		$(PROJECT_NAME):latest-dev \
		gin -i main.go

##        __                          __                _          
##   ____/ /__  ____  ___  ____  ____/ /__  ____  _____(_)__  _____
##  / __  / _ \/ __ \/ _ \/ __ \/ __  / _ \/ __ \/ ___/ / _ \/ ___/
## / /_/ /  __/ /_/ /  __/ / / / /_/ /  __/ / / / /__/ /  __(__  ) 
## \__,_/\___/ .___/\___/_/ /_/\__,_/\___/_/ /_/\___/_/\___/____/  
##          /_/                                                    
##
## #dependencies

dep: build.docker.development
	@if [ -z "${ARGS}" ]; then \
		$(MAKE) log.error MSG='"ARGS" parameter not specified.'; \
		exit 1; \
	else \
		docker run \
			--workdir /go/src/app \
			-v $(CURDIR):/go/src/app \
			-v $(CURDIR)/.cache:/.cache \
			-u $$(id -u) \
			--entrypoint=dep \
			$(PROJECT_NAME):latest-dev \
			${ARGS}; \
	fi
	# this hack is for allowing vscode to identify vendor dependencies based on GOPATH so we have intellisense
	-@ln -s vendor src
dep.init:
	$(MAKE) dep ARGS="init"
dep.ensure:
	$(MAKE) dep ARGS="ensure -v"

mod: build.docker.development
	@if [ -z "${ARGS}" ]; then \
		$(MAKE) log.error MSG='"ARGS" parameter not specified.'; \
		exit 1; \
	else \
		docker run \
			--workdir /go/src/app \
			-v $(CURDIR):/go/src/app \
			-v $(CURDIR)/.cache:/.cache \
			--env GO111MODULE=on \
			-u $$(id -u) \
			--entrypoint=go \
			$(PROJECT_NAME):latest-dev \
			mod ${ARGS}; \
	fi
mod.init:
	@if [ -z "${PACKAGE}" ]; then \
		$(MAKE) log.error MSG='"PACKAGE" parameter not specified.'; \
		exit 1; \
	else \
		$(MAKE) mod ARGS="init ${PACKAGE}"; \
	fi
mod.download:
	@$(MAKE) mod ARGS="download"
	@$(MAKE) mod ARGS="vendor"
mod.vendor:
	@$(MAKE) mod ARGS="vendor"

##    __            __  _            
##   / /____  _____/ /_(_)___  ____ _
##  / __/ _ \/ ___/ __/ / __ \/ __ `/
## / /_/  __(__  ) /_/ / / / / /_/ / 
## \__/\___/____/\__/_/_/ /_/\__, /  
##                          /____/   
## #testing

test: build.docker.development
	-@docker stop $(PROJECT_NAME)-latest-test
	-@docker rm $(PROJECT_NAME)-latest-test
	@$(MAKE) log.info MSG="Creating container \"$(PROJECT_NAME)-latest-test\" from image \"$(PROJECT_NAME):latest-dev\"..."
	@docker run \
		--network host \
		-v "$(CURDIR):/go/src/app" \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--name $(PROJECT_NAME)-latest-test \
		$(PROJECT_NAME):latest-dev \
		go test -v -cover -coverprofile=c.out
test.watch: build.docker.development
	-@docker stop $(PROJECT_NAME)-latest-testing
	-@docker rm $(PROJECT_NAME)-latest-testing
	@$(MAKE) log.info MSG="Creating container \"$(PROJECT_NAME)-latest-testing\" from image \"$(PROJECT_NAME):latest-dev\"..."
	@docker run \
		--network host
		-v "$(CURDIR):/go/src/app" \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--name $(PROJECT_NAME)-latest-testing \
		$(PROJECT_NAME):latest-dev \
		autorun-tests

##                               _ __      __  _           
##   _________  ____ ___  ____  (_) /___ _/ /_(_)___  ____ 
##  / ___/ __ \/ __ `__ \/ __ \/ / / __ `/ __/ / __ \/ __ \
## / /__/ /_/ / / / / / / /_/ / / / /_/ / /_/ / /_/ / / / /
## \___/\____/_/ /_/ /_/ .___/_/_/\__,_/\__/_/\____/_/ /_/ 
##                    /_/                                  
## #compilation

# runs `go build` for linux, os x, and windows
build: build.docker.development
	-@$(eval GIT_TAG_VERSION=$(shell docker run -v "$(CURDIR):/app" zephinzer/vtscripts:latest get-latest -q -i))
	-@docker stop $(PROJECT_NAME)-latest-build
	-@docker rm $(PROJECT_NAME)-latest-build
	@mkdir -p bin
	@$(MAKE) log.info MSG="Building Windows binary $(PROJECT_NAME) at version $(GIT_TAG_VERSION)..."
	@docker run \
		--network host
		-v "$$(pwd):/go/src/app" \
		--env "CGO_ENABLED=0" \
		--env "GOOS=windows" \
		--env "GOARCH=386" \
		--name $(PROJECT_NAME)-latest-build \
		$(PROJECT_NAME):latest-dev \
		go build \
			-a \
			-ldflags "-X main.version=$(GIT_TAG_VERSION) -w -extldflags \"static\"" \
			-o bin/$(PROJECT_NAME)-win-386.exe
	@$(MAKE) log.info MSG="Windows binary at $(CURDIR)/bin/$(PROJECT_NAME)-win-386.exe"
	-@docker stop $(PROJECT_NAME)-latest-build
	-@docker rm $(PROJECT_NAME)-latest-build
	@$(MAKE) log.info MSG="Building Linux binary $(PROJECT_NAME) at version $(GIT_TAG_VERSION)..."
	@docker run \
		--network host \
		-v "$$(pwd):/go/src/app" \
		--env "CGO_ENABLED=0" \
		--env "GOOS=linux" \
		--env "GOARCH=amd64" \
		--name $(PROJECT_NAME)-latest-build \
		$(PROJECT_NAME):latest-dev \
		go build \
			-a \
			-ldflags "-X main.version=$(GIT_TAG_VERSION) -w -extldflags \"static\"" \
			-o bin/$(PROJECT_NAME)-linux-amd64
	@$(MAKE) log.info MSG="OS X binary at $(CURDIR)/bin/$(PROJECT_NAME)-linux-amd64"
	-@docker stop $(PROJECT_NAME)-latest-build
	-@docker rm $(PROJECT_NAME)-latest-build
	@$(MAKE) log.info MSG="Building OS X binary $(PROJECT_NAME) at version $(GIT_TAG_VERSION)..."
	@docker run \
		--network host \
		-v "$(CURDIR):/go/src/app" \
		-v $(CURDIR)/.cache:/.cache \
		-u $$(id -u) \
		--env "CGO_ENABLED=0" \
		--env "GOOS=linux" \
		--env "GOARCH=arm" \
		--name $(PROJECT_NAME)-latest-build \
		$(PROJECT_NAME):latest-dev \
		go build \
			-a \
			-ldflags "-X main.version=$(GIT_TAG_VERSION) -w -extldflags \"static\"" \
			-o bin/$(PROJECT_NAME)-linux-arm
	@$(MAKE) log.info MSG="Linux binary at $(CURDIR)/bin/$(PROJECT_NAME)-linux-arm"

##                     __        _                 _            __  _           
##   _________  ____  / /_____ _(_)___  ___  _____(_)________ _/ /_(_)___  ____ 
##  / ___/ __ \/ __ \/ __/ __ `/ / __ \/ _ \/ ___/ / ___/ __ `/ __/ / __ \/ __ \
## / /__/ /_/ / / / / /_/ /_/ / / / / /  __/ /  / (__  ) /_/ / /_/ / /_/ / / / /
## \___/\____/_/ /_/\__/\__,_/_/_/ /_/\___/_/  /_/____/\__,_/\__/_/\____/_/ /_/ 
##                                                                              
## #containerisation

build.docker: init
	@$(MAKE) build.docker.production
build.docker.development:
	@$(MAKE) log.info MSG="Building image \"$(PROJECT_NAME):latest-dev\""
	-@docker build -f ./Dockerfile --target=development -t $(PROJECT_NAME):latest-dev .
	@$(MAKE) log.info MSG="Image \"$(PROJECT_NAME):latest-dev\" successfully built"
build.docker.production:
	@$(MAKE) log.info MSG="Building image \"$(PROJECT_NAME):latest\""
	@docker build -f ./Dockerfile --target=production -t $(PROJECT_NAME):latest .
	@$(MAKE) log.info MSG="Image \"$(PROJECT_NAME):latest\" successfully built"


##                  __    ___      __    _            
##     ____  __  __/ /_  / (_)____/ /_  (_)___  ____ _
##    / __ \/ / / / __ \/ / / ___/ __ \/ / __ \/ __ `/
##   / /_/ / /_/ / /_/ / / (__  ) / / / / / / / /_/ / 
##  / .___/\__,_/_.___/_/_/____/_/ /_/_/_/ /_/\__, /  
## /_/                                       /____/   
##
## #publishing

publish.docker.development:
	-@$(eval GIT_TAG_VERSION=$(shell docker run -v "$(CURDIR):/app" zephinzer/vtscripts:latest get-latest -q -i))
	@if ! [ -z "${REGISTRY}" ] && ! [ -z ${NAMESPACE} ]; then \
			$(MAKE) log.info MSG="Attempting to tag image \"$(PROJECT_NAME):latest-dev\" as \"${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev\""; \
			docker tag $(PROJECT_NAME):latest-dev ${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev; \
			$(MAKE) log.info MSG="Attempting to push image \"${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev\"..."; \
			$(MAKE) log.warn MSG="(hit ctrl+c to stop this)"; \
			sleep 3; \
			docker push ${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev; \
		elif ! [ -z "${NAMESPACE}" ]; then \
			$(MAKE) log.info MSG="Attempting to tag image \"$(PROJECT_NAME):latest-dev\" as \"${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev\""; \
			docker tag $(PROJECT_NAME):latest-dev ${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev; \
			$(MAKE) log.info MSG="Attempting to push image \"${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev\"..."; \
			$(MAKE) log.warn MSG="(hit ctrl+c to stop this)"; \
			sleep 3; \
			docker push ${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}-dev; \
		else \
			$(MAKE) log.info MSG="Attempting to tag image \"$(PROJECT_NAME):latest-dev\" as \"$(PROJECT_NAME):${GIT_TAG_VERSION}-dev\""; \
			docker tag $(PROJECT_NAME):latest-dev $(PROJECT_NAME):${GIT_TAG_VERSION}-dev; \
			$(MAKE) log.info MSG="Attempting to push image \"$(PROJECT_NAME):${GIT_TAG_VERSION}-dev\"..."; \
			$(MAKE) log.warn MSG="(hit ctrl+c to stop this)"; \
			sleep 3; \
			docker push $(PROJECT_NAME):${GIT_TAG_VERSION}-dev; \
		fi
publish.docker.production:
	-@$(eval GIT_TAG_VERSION=$(shell docker run -v "$(CURDIR):/app" zephinzer/vtscripts:latest get-latest -q -i))
	@if ! [ -z "${REGISTRY}" ] && ! [ -z ${NAMESPACE} ]; then \
			$(MAKE) log.info MSG="Attempting to tag image \"$(PROJECT_NAME):latest\" as \"${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}\""; \
			docker tag $(PROJECT_NAME):latest ${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}; \
			$(MAKE) log.info MSG="Attempting to push image \"${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}\"..."; \
			$(MAKE) log.warn MSG="(hit ctrl+c to stop this)"; \
			sleep 3; \
			docker push ${REGISTRY}/${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}; \
		elif ! [ -z ${NAMESPACE} ]; then \
			$(MAKE) log.info MSG="Attempting to tag image \"$(PROJECT_NAME):latest\" as \"${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}\""; \
			docker tag $(PROJECT_NAME):latest ${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}; \
			$(MAKE) log.info MSG="Attempting to push image \"${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}\"..."; \
			$(MAKE) log.warn MSG="(hit ctrl+c to stop this)"; \
			sleep 3; \
			docker push ${NAMESPACE}/$(PROJECT_NAME):${GIT_TAG_VERSION}; \
		else \
			$(MAKE) log.info MSG="Attempting to tag image \"$(PROJECT_NAME):latest\" as \"$(PROJECT_NAME):${GIT_TAG_VERSION}\""; \
			docker tag $(PROJECT_NAME):latest $(PROJECT_NAME):${GIT_TAG_VERSION}; \
			$(MAKE) log.info MSG="Attempting to push image \"$(PROJECT_NAME):${GIT_TAG_VERSION}\"..."; \
			$(MAKE) log.warn MSG="(hit ctrl+c to stop this)"; \
			sleep 3; \
			docker push $(PROJECT_NAME):${GIT_TAG_VERSION}; \
		fi

##                        _             _            
##  _   _____  __________(_)___  ____  (_)___  ____ _
## | | / / _ \/ ___/ ___/ / __ \/ __ \/ / __ \/ __ `/
## | |/ /  __/ /  (__  ) / /_/ / / / / / / / / /_/ / 
## |___/\___/_/  /____/_/\____/_/ /_/_/_/ /_/\__, /  
##                                          /____/   
## #versioning

version.get:
	@docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest get-latest
version.init:
	@docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest init
version.bump:
	docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest iterate patch -i;
version.bump.minor:
	docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest iterate minor -i;
version.bump.major:
	docker run -v "$$(pwd):/app" zephinzer/vtscripts:latest iterate major -i;

##     __                  _            
##    / /___  ____ _____ _(_)___  ____ _
##   / / __ \/ __ `/ __ `/ / __ \/ __ `/
##  / / /_/ / /_/ / /_/ / / / / / /_/ / 
## /_/\____/\__, /\__, /_/_/ /_/\__, /  
##         /____//____/        /____/   
##
## #logging

log.debug:
	-@printf -- "\033[36m\033[1m_ [DEBUG] ${MSG}\033[0m\n"
log.info:
	-@printf -- "\033[32m\033[1m>  [INFO] ${MSG}\033[0m\n"
log.warn:
	-@printf -- "\033[33m\033[1m?  [WARN] ${MSG}\033[0m\n"
log.error:
	-@printf -- "\033[31m\033[1m! [ERROR] ${MSG}\033[0m\n"

##        __      __       
##   ____/ /___ _/ /_____ _
##  / __  / __ `/ __/ __ `/
## / /_/ / /_/ / /_/ /_/ / 
## \__,_/\__,_/\__/\__,_/  
##                         
## #data


define DOCKERFILE_CONTENT
# for use in development
ARG GOLANG_VERSION="1.11"
# this image contains just the source code
FROM golang:$${GOLANG_VERSION}-alpine as development
# defines extra `apk` dependencies if required
ARG APK=""
# due dilligence
RUN apk update --no-cache
# system dependencies for `go get`
RUN apk add --no-cache git curl
# installs gin for server live-reloading
RUN go get -v -d github.com/codegangsta/gin
# installs dep for dependency management
RUN curl https://raw.githubusercontent.com/golang/dep/master/install.sh | sh
# system dependencies for `go test`
RUN apk add --no-cache gcc libc-dev python
# system dependencies for production parity
RUN apk add --no-cache ca-certificates $${APK}
# system dependencies for developer happiness
RUN apk add --no-cache bash jq ncurses
# create the caching directories for golang/dep
RUN mkdir -p /.cache/go-build && chmod 777 -R /.cache
# sets the working directory to a valid GOPATH
WORKDIR /go/src/app
# create autorun-tests script
COPY ./.scripts/auto-run.py /bin/autorun-tests
# assign execution permissions to autorun-tests
RUN chmod +x /bin/autorun-tests
# add convenience scripts
COPY ./.scripts/.bash_profile /root/.bash_profile
# assign execution permissions to the .bash_profile
RUN chmod +x /root/.bash_profile

# for use in the binary generating process
ARG GOLANG_VERSION="1.11"
# this image will contain both the source code and the binaries
FROM golang:$${GOLANG_VERSION}-alpine as compile
# copies everything in this directory 
COPY . /go/src/app
# sets the working directory to a valid GOPATH
WORKDIR /go/src/app
# generate the binary and create a symlink to /bin
RUN go test -coverprofile c.out && go build -o app && ln -s /go/src/app/app /bin/start
# defines the symlink `start` as the entrypoint
ENTRYPOINT [ "start" ]

# for use in the production environment
ARG ALPINE_VERSION="3.8"
# this image contains just the binary
FROM alpine:$${ALPINE_VERSION} as production
# defines any other `apk` dependencies to install
ARG APK=""
# due dilligence
RUN apk update --no-cache
# install system level depnedencies
RUN apk add --no-cache ca-certificates $${APK}
# copies the binary from the `compile` image - no symlink required
COPY --from=compile /go/src/app/app /bin/start
# create app user so we can prevent running as root
RUN adduser -D -H app
# make /bin/start non-writable
RUN chmod 550 /bin/start && chown app:root /bin/start
# allocate a data directory for read/write by app, and also root group for openshift compatibility
RUN mkdir -p /data && chmod 770 /data && chown app:root /data
# sets the primary working directory to the root directory
WORKDIR /
# sets the user to app as a final touch
USER app
# defines the entrypoint to the system `start` command at /bin
ENTRYPOINT [ "start" ]
endef
export DOCKERFILE_CONTENT
define AUTO_RUN_TESTS_CONTENT
#!/usr/bin/env python

"""
This script scans the current working directory for changes to .go files and 
runs `go test` in each folder where *_test.go files are found. It does this 
indefinitely or until a KeyboardInterrupt is raised (<Ctrl+c>). This script 
passes the verbosity command line argument (-v) to `go test`.

Credits: https://gist.github.com/mdwhatcott/9107649
"""


import os
import subprocess
import sys
import time


def main(verbose):
    working = os.path.abspath(os.path.join(os.getcwd()))    
    scanner = WorkspaceScanner(working)
    runner = TestRunner(working, verbose)

    while True:
        if scanner.scan():
            runner.run()


class WorkspaceScanner(object):
    def __init__(self, top):
        self.state = 0
        self.top = top

    def scan(self):
        time.sleep(.75)
        new_state = sum(self._checksums())
        if self.state != new_state:
            self.state = new_state
            return True
        return False

    def _checksums(self):
        for root, dirs, files in os.walk(self.top):
            for f in files:
                if f.endswith('.go'):
                    try:
                        stats = os.stat(os.path.join(root, f))
                        yield stats.st_mtime + stats.st_size
                    except OSError:
                        pass


class TestRunner(object):
    def __init__(self, top, verbosity):
        self.repetitions = 0
        self.top = top
        self.working = self.top
        self.verbosity = verbosity

    def run(self):
        self.repetitions += 1
        self._display_repetitions_banner()
        self._run_tests()

    def _display_repetitions_banner(self):
        number = ' {} '.format(self.repetitions if self.repetitions % 50 else
            'Wow, are you going for a top score? Keep it up!')
        half_delimiter = (EVEN if not self.repetitions % 2 else ODD) * \\
                         ((80 - len(number)) / 2)
        write('\\n{0}{1}{0}\\n'.format(half_delimiter, number))

    def _run_tests(self):
        self._chdir(self.top)
        if self.tests_found():
            self._run_test()
        
        for root, dirs, files in os.walk(self.top):
            self.search_for_tests(root, dirs, files)

    def search_for_tests(self, root, dirs, files):
        for d in dirs:
            if '.git' in d or '.git' in root:
                continue

            self._chdir(os.path.join(root, d))
            if self.tests_found():
                self._run_test()

    def tests_found(self):
        for f in os.listdir(self.working):
            if f.endswith('_test.go'):
                return True

        return False

    def _run_test(self):
        subprocess.call('go test -i', shell=True)
        try:
            output = subprocess.check_output(
                'go test ' + self.verbosity, shell=True)
            self.write_output(output)
        except subprocess.CalledProcessError as error:
            self.write_output(error.output)

        write('\\n')

    def write_output(self, output):
        write(output)

    def _chdir(self, new):
        os.chdir(new)
        self.working = new


def write(value):
    sys.stdout.write(value)
    sys.stdout.flush()


EVEN = '='
ODD  = '-'
RESET_COLOR  = '\\033[0m'
RED_COLOR    = '\\033[31m'
YELLOW_COLOR = '\\033[33m'
GREEN_COLOR  = '\\033[32m'


def parse_bool_arg(name):
    for arg in sys.argv:
        if arg == name:
            return True
    return False


if __name__ == '__main__':
    verbose = '-v' if parse_bool_arg('-v') else ''
    main(verbose)
endef
export AUTO_RUN_TESTS_CONTENT
define BASH_PROFILE_CONTENT
#!/bin/bash

alias ll='ls -al'
export PATH="$${PATH}:/usr/local/go/bin/"

## bash specific stuff
drawline() {
  printf '\e[4m%*s\e[0m\\n' "$${COLUMNS:-$$(tput cols)}" '' | tr ' ' ' ';
}
get_time() {
  printf "$$(date +'%Y-%m-%d %I:%M %p')";
}
get_vcs_branch() {
  vcs_info;
  if [ -n "$$vcs_info_msg_0_" ]; then
    echo "\e[0m\e[32m$$(printf "$$vcs_info_msg_0_" | cut -f 1 -d ']' | cut -f 2 -d '[') \e[0m";
  fi;
}
vcs_info_wrapper() {
  vcs_info;
  if [ -n "$$vcs_info_msg_0_" ]; then
    echo "%{$$fg[grey]%}$$(get_vcs_branch)%{$$reset_color%}$$del";
  fi
}
get_status_bar_vcs_info() {
  vcs_info;
  if [ -n "$$vcs_info_msg_0_" ]; then
    printf "⎸💡  $$(printf "$$vcs_info_msg_0_" | cut -f 2 -d '-') ⎸";
  fi;
}
precmd() {
  echo -ne "\e]1;$${PWD##*/} $$(get_branch)\\a";
}
get_branch() {
  CURRENT_BRANCH=$$(git branch &>/dev/null);
  if [ "$$?" = "0" ]; then
    CURRENT_BRANCH="$$(git branch | grep '*' | cut -f 2 -d '*')";
    printf -- "⎸\e[0m\e[32m$${CURRENT_BRANCH}\e[0m";
  fi;
}
PS1=$$'\[\\a\]\[\\n\]\[\e[90m\]\[\e[37m\]\[\e[1m\]$$(drawline)\\n⎸bash ⎸👤 $$(whoami) ⎸📆 $$(get_time) ⎸ 📂 $$(pwd) $$(get_branch)\\n\[\e[0m\]\[\e[36m\]\[\e[35m\]⢈\[\e[31m\]⢨⢘\[\e[91m\]⢈⢸⠨\[\e[33m\]⠸⢈\[\e[32m\]⢨\[\e[36m\]⢘\[\e[94m\]⢈ \[\e[37m\]$$\[\e[0m\] ';
endef
export BASH_PROFILE_CONTENT
define LICENSE_CONTENT
Copyright __year__ __name__

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
endef
export LICENSE_CONTENT
