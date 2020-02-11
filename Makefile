.PHONY: clean svhotspot create-conda-channel update-conda-channel

SHELL := /bin/bash

BUILD_DIR := /build
SVHOTSPOT_ENV := $(BUILD_DIR)/svhotspot-env
MINICONDA_URL := https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
MINICONDA_INSTALLER := $(BUILD_DIR)/Miniconda3-latest-Linux-x86_64.sh
MINICONDA_INSTALL_PREFIX := /opt/mini
CONDA := $(MINICONDA_INSTALL_PREFIX)/bin/conda
CONDA_ACTIVATE := $(MINICONDA_INSTALL_PREFIX)/bin/activate
CONDA_PROFILE := $(MINICONDA_INSTALL_PREFIX)/etc/profile.d/conda.sh
CONDA_BUILD_PATH := $(MINICONDA_INSTALL_PREFIX)/conda-bld/linux-64

SV_HOTSPOT_URL := https://github.com/eteleeb/SV-HotSpot
SV_HOTSPOT_LOCAL := $(BUILD_DIR)/SV-HotSpot-conda-builder

all: svhotspot

svhotspot: $(CONDA)
	$(CONDA) create --yes --prefix $(SVHOTSPOT_ENV)
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) 'perl>=5.10'
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) 'perl-list-moreutils'
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) bedtools
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) 'r-base>=3.1.0'
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) r-ggplot2
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) conda-build
	$(CONDA) install -v --yes --prefix $(SVHOTSPOT_ENV) conda-verify
	git clone $(SV_HOTSPOT_URL) $(SV_HOTSPOT_LOCAL)
	cd $(SV_HOTSPOT_LOCAL) && git checkout -b docker-conda origin/docker-conda
	cd $(SV_HOTSPOT_LOCAL) && $(CONDA) build sv-hotspot
	cd $(SV_HOTSPOT_LOCAL) && cp $(CONDA_BUILD_PATH)/sv-hotspot-*.tar.bz2 ..
#	source $(CONDA_PROFILE) && $(CONDA) activate $(SVHOTSPOT_ENV)

$(CONDA): $(MINICONDA_INSTALLER)
	/bin/bash $(MINICONDA_INSTALLER) -u -b -p $(MINICONDA_INSTALL_PREFIX)
	$(CONDA) init bash
	$(CONDA) update -y -n base -c defaults conda
	$(CONDA) config --set env_prompt '({name}) '
	$(CONDA) config --add channels defaults
	$(CONDA) config --add channels bioconda
	$(CONDA) config --add channels conda-forge
	$(CONDA) install -v --yes conda-build
	$(CONDA) install -v --yes conda-verify

$(MINICONDA_INSTALLER):
	curl -k -L -O $(MINICONDA_URL)

define input-arg-error-msg
missing required inputpkg argument, please run:

	make update-conda-channel inputpkg=/path/to/yourpkg.version.tar.bz2


endef

update-conda-channel::
    ifdef inputpkg
	    @echo 'got a value for input-pkg ' $(inputpkg)
    else
	    echo "inputpkg: " $(inputpkg)
	    $(error $(input-arg-error-msg))
    endif
	
	# https://stackoverflow.com/questions/5553352/how-do-i-check-if-file-exists-in-makefile-so-i-can-delete-it
    ifeq ("$(wildcard $(inputpkg))", "")
	    $(error [err] Did not file $(inputpkg) on file system!)
    endif

update-conda-channel::
	echo "inputpkg is: " $(inputpkg)
	git checkout -B conda-channel origin/conda-channel
	cp -v sv-hotspot-*.tar.bz2 channel/linux-64
	cp -v sv-hotspot-*.tar.bz2 channel/linux-32
	cp -v sv-hotspot-*.tar.bz2 channel/osx-64
	cp -v sv-hotspot-*.tar.bz2 channel/win-64
	cp -v sv-hotspot-*.tar.bz2 channel/win-32
	$(CONDA) index channel/
	git add channel
	git commit -m "updated conda package $$(date)"
	git push origin conda-channel
	git checkout -B docker-conda origin/docker-conda

create-conda-channel:
	git checkout --orphan conda-channel
	git rm -rf .
	mkdir -p channel/{linux-64,linux-32,osx-64,win-64,win-32}
	cp -v sv-hotspot-*.tar.bz2 channel/linux-64
	cp -v sv-hotspot-*.tar.bz2 channel/linux-32
	cp -v sv-hotspot-*.tar.bz2 channel/osx-64
	cp -v sv-hotspot-*.tar.bz2 channel/win-64
	cp -v sv-hotspot-*.tar.bz2 channel/win-32
	git add channel
	git commit -m 'initialize conda-channel'
	git push origin conda-channel:conda-channel
	git branch --set-upstream-to origin/conda-channel
	git push origin conda-channel
	git checkout -B docker-conda origin/docker-conda

clean:
	if [ -d $(SV_HOTSPOT_LOCAL) ]; then rm -rfv $(SV_HOTSPOT_LOCAL); fi
	if [ -d $(SVHOTSPOT_ENV) ]; then rm -rfv $(SVHOTSPOT_ENV); fi
	if [ -d $(MINICONDA_INSTALL_PREFIX) ]; then rm -rfv $(MINICONDA_INSTALL_PREFIX); fi
	if [ -e $(MINICONDA_INSTALLER) ]; then rm -rfv $(MINICONDA_INSTALLER); fi
	if ls sv-hotspot-*.tar.bz2 1>/dev/null /dev/null 2>&1; then rm -rfv sv-hotspot-*.tar.bz2; fi
	if [ -d channel ]; then rm -rfv channel; fi

# references
# https://github.com/conda/conda/issues/7980
# https://stackoverflow.com/questions/53382383/makefile-cant-use-conda-activate/55696820#55696820
# https://towardsdatascience.com/a-guide-to-conda-environments-bc6180fc533
# http://mlg.eng.cam.ac.uk/hoffmanm/blog/2016-02-25-conda-build/
# https://www.youtube.com/watch?v=HSK-6dCnYVQ
# https://towardsdatascience.com/a-guide-to-conda-environments-bc6180fc533
# https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/create-custom-channels.html
