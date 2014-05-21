# OASIS_START
# DO NOT EDIT (digest: a3c674b4239234cbbe53afe090018954)

SETUP = ocaml setup.ml

build: setup.data
	$(SETUP) -build $(BUILDFLAGS)

doc: setup.data build
	$(SETUP) -doc $(DOCFLAGS)

test: setup.data build
	$(SETUP) -test $(TESTFLAGS)

all:
	$(SETUP) -all $(ALLFLAGS)

install: setup.data
	$(SETUP) -install $(INSTALLFLAGS)

uninstall: setup.data
	$(SETUP) -uninstall $(UNINSTALLFLAGS)

reinstall: setup.data
	$(SETUP) -reinstall $(REINSTALLFLAGS)

clean:
	$(SETUP) -clean $(CLEANFLAGS)

distclean:
	$(SETUP) -distclean $(DISTCLEANFLAGS)

setup.data:
	$(SETUP) -configure $(CONFIGUREFLAGS)

configure:
	$(SETUP) -configure $(CONFIGUREFLAGS)

.PHONY: build doc test all install uninstall reinstall clean distclean configure

# OASIS_STOP

opam-release:
	oasis setup
	$(eval TEMPLATE_DIR:=opam-template)
	$(eval RELEASE_DIR:=opam-releases)
	$(eval NAME:=$(shell oasis query name))
	$(eval VERSION:=$(shell oasis query version))
	$(eval PACKAGE:=$(NAME).$(VERSION))
	$(eval DIR:=$(RELEASE_DIR)/$(PACKAGE))
	mkdir -p $(DIR)
	tar -cjf $(RELEASE_DIR)/$(PACKAGE).tar.bz2 \
		--transform 's,^\.,$(PACKAGE),' \
		--exclude-from=.gitignore \
		--exclude=.git \
		--exclude=$(RELEASE_DIR) .
	for f in descr opam url; do \
		./oasis-vars "$(TEMPLATE_DIR)/$$f" > $(DIR)/$$f; \
	done
