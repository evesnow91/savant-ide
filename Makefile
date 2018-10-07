# This really just adds some conveniences.
# Mostly, this is so you don't have to care about creating directories or
# building the Scilla binaries by hand.
.PHONY: default all bootstrap clean ocaml-dep scilla-bin scilla-src scilla-dep docker

SCILLA_BRANCH ?= master
MACHINE = $(shell uname -s)

default: all

all: bootstrap build-js scilla-bin

build-js:
	yarn build:client
	yarn build:server

bootstrap: clean
	mkdir temp
	yarn install

clean:
	rm -rf temp
	rm -rf scilla
	rm -rf node_modules

# Only Ubuntu and MacOS are supported.
ocaml-dep:
ifeq ($(MACHINE),Darwin)
	brew install ocaml opam pkg-config libffi openssl boost
else
	sudo apt-get update
	sudo apt-get install -y curl build-essential m4 ocaml opam pkg-config zlib1g-dev libgmp-dev libffi-dev libssl-dev libboost-system-dev
endif

scilla-src:
	git clone https://github.com/Zilliqa/scilla.git
	git -C scilla fetch --all
	git -C scilla checkout $(SCILLA_BRANCH)
	git -C scilla pull

# Installs the necessary OCaml packages via OPAM.
scilla-dep:
	opam init -y
	opam switch -y 4.06.1
ifeq ($(MACHINE),Darwin)
	opam install angstrom batteries core cryptokit fileutils hex num oUnit ppx_deriving ppx_deriving_yojson ppx_let ppx_sexp_conv stdint yojson menhir dune ctypes ctypes-foreign
else
	opam install -y ocaml-migrate-parsetree core cryptokit ppx_sexp_conv yojson batteries angstrom hex ppx_deriving ppx_deriving_yojson menhir oUnit dune stdint fileutils ctypes ctypes-foreign
endif
	eval `opam config env`

# Installs everything and compiles the Scilla binaries.
scilla-bin: ocaml-dep scilla-src scilla-dep
	$(MAKE) -C scilla all

# Builds a Docker container for running the scilla-runner API.
docker: clean bootstrap scilla-bin
	docker build . -t scilla-runner-api:$(shell git rev-parse --short=7 HEAD)
