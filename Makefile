include /usr/share/dpkg/pkg-info.mk
include /usr/share/dpkg/architecture.mk

PACKAGE=criu

SRCDIR=criu
SRCTAR=${SRCDIR}.tgz

GITVERSION:=$(shell cat .git/refs/heads/master)

DEB1=${PACKAGE}_${DEB_VERSION_UPSTREAM_REVISION}_${DEB_BUILD_ARCH}.deb
DEB_DBG=${PACKAGE}-dbgsym_${DEB_VERSION_UPSTREAM_REVISION}_${DEB_BUILD_ARCH}.deb
DEBS=$(DEB1) $(DEB_DBG)

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb $(DEB_DBG): $(DEB1)
$(DEB1): $(SRCTAR)
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	mv ${SRCDIR}/debian/changelog ${SRCDIR}/debian/changelog.org
	cat debian/changelog ${SRCDIR}/debian/changelog.org > ${SRCDIR}/debian/changelog
	echo "git clone git://git.proxmox.com/git/criu.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	cd ${SRCDIR}; dpkg-buildpackage -b -us -uc
	lintian ${DEBS}


.PHONY: download
download:
	rm -rf ${SRCDIR} ${SRCTAR}
	git clone -b debian/3.11-2 https://anonscm.debian.org/git/collab-maint/criu.git ${SRCDIR}
	tar czf ${SRCTAR}.tmp --exclude=.git ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${DEB_BUILD_ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${DEB_BUILD_ARCH}.deb *.changes *.dsc *.buildinfo
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
