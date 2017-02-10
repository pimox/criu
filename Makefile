RELEASE=4.0

PACKAGE=criu
PKGVER=1.6.0
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
download ${SRCTAR}:
	rm -rf ${SRCDIR} ${SRCTAR} ${SRCTAR}.tmp
	git clone https://github.com/xemul/${SRCDIR}
	tar czf ${SRCTAR}.tmp ${SRCDIR}
	mv ${SRCTAR}.tmp ${SRCTAR}

.PHONY: upload
upload: ${DEBS}
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o rw 
	mkdir -p /pve/${RELEASE}/extra
	rm -f /pve/${RELEASE}/extra/${PACKAGE}_*.deb
	rm -f /pve/${RELEASE}/extra/${PACKAGE}-dbg_*.deb
	rm -f /pve/${RELEASE}/extra/Packages*
	cp ${DEBS} /pve/${RELEASE}/extra
	cd /pve/${RELEASE}/extra; dpkg-scanpackages . /dev/null > Packages; gzip -9c Packages > Packages.gz
	umount /pve/${RELEASE}; mount /pve/${RELEASE} -o ro

distclean: clean

.PHONY: clean
clean:
	rm -rf ${SRCDIR} ${SRCDIR}.tmp *_${ARCH}.deb *.changes *.dsc 
	find . -name '*~' -exec rm {} ';'

.PHONY: dinstall
dinstall: ${DEBS}
	dpkg -i ${DEBS}
