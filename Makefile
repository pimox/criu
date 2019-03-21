RELEASE=5.0

PACKAGE=criu
PKGVER=3.11
DEBREL=2~bpo90

SRCDIR=criu
SRCTAR=${SRCDIR}.tgz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB1=${PACKAGE}_${PKGVER}-${DEBREL}_$(ARCH).deb
DEB_DBG=${PACKAGE}-dbgsym_${PKGVER}-${DEBREL}_$(ARCH).deb
DEBS=$(DEB1) $(DEB_DBG)

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb $(DEB_DBG): $(DEB1)
$(DEB1): $(SRCTAR)
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	mv ${SRCDIR}/debian/changelog ${SRCDIR}/debian/changelog.org
	cat changelog.Debian ${SRCDIR}/debian/changelog.org > ${SRCDIR}/debian/changelog
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
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc *.buildinfo
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
