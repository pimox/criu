RELEASE=5.0

PACKAGE=criu
PKGVER=2.10
DEBREL=1

SRCDIR=criu
SRCTAR=${SRCDIR}.tgz

ARCH:=$(shell dpkg-architecture -qDEB_BUILD_ARCH)
GITVERSION:=$(shell cat .git/refs/heads/master)

DEB1=${PACKAGE}_${PKGVER}-${DEBREL}_$(ARCH).deb
DEB_DBG=${PACKAGE}-dbg_${PKGVER}-${DEBREL}_$(ARCH).deb
DEBS=$(DEB1) $(DEB_DBG)

all: ${DEBS}
	echo ${DEBS}

.PHONY: deb
deb $(DEB_DBG): $(DEB1)
$(DEB1): $(SRCTAR)
	rm -rf ${SRCDIR}
	tar xf ${SRCTAR}
	cp -a debian ${SRCDIR}/debian
	echo "git clone git://git.proxmox.com/git/criu.git\\ngit checkout ${GITVERSION}" >  ${SRCDIR}/debian/SOURCE
	cd ${SRCDIR}; dpkg-buildpackage -rfakeroot -b -us -uc
	lintian ${DEBS}


.PHONY: download
download:
	rm -rf ${SRCDIR} ${SRCTAR}
	git clone -b v$(PKGVER) git://github.com/xemul/$(PACKAGE).git
	tar czf ${SRCTAR}.tmp --exclude=.git ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

.PHONY: upload
upload: ${DEBS}
	tar cf - ${DEBS} | ssh repoman@repo.proxmox.com -- upload --product pve --dist stretch --arch ${ARCH}

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc 
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
