RELEASE_DATE := "20-Jun-2007"
RELEASE_MAJOR := 2
RELEASE_MINOR := 0
RELEASE_SUBLEVEL := 16.2
RELEASE_EXTRALEVEL :=
RELEASE_NAME := dkms
RELEASE_VERSION := $(RELEASE_MAJOR).$(RELEASE_MINOR).$(RELEASE_SUBLEVEL)$(RELEASE_EXTRALEVEL)
RELEASE_STRING := $(RELEASE_NAME)-$(RELEASE_VERSION)

SBIN = $(DESTDIR)/usr/sbin
ETC = $(DESTDIR)/etc/dkms
VAR = $(DESTDIR)/var/lib/dkms
MAN = $(DESTDIR)/usr/share/man/man8
INITD = $(DESTDIR)/etc/init.d
BASHDIR = $(DESTDIR)/etc/bash_completion.d
DOCDIR = $(DESTDIR)/usr/share/doc/dkms
KCONF = $(DESTDIR)/etc/kernel

.PHONY = tarball

all:

clean:
	-rm dkms-*.tar.gz dkms-*.src.rpm dkms-*.noarch.rpm *~

clean-dpkg: clean
	rm -f debian/dkms_autoinstaller.init
	rm -f debian/conffiles

copy-init:
	install -m 755 dkms_autoinstaller debian/dkms_autoinstaller.init
	(cd $(DESTDIR); find etc/dkms -type f) > debian/conffiles

install:
	mkdir -m 0755 -p $(VAR) $(SBIN) $(MAN) $(INITD) $(ETC) $(BASHDIR)
	install -p -m 0755 dkms $(SBIN)
	install -p -m 0755 dkms_autoinstaller $(INITD)
	install -p -m 0644 dkms_framework.conf $(ETC)/framework.conf
	install -p -m 0644 template-dkms-mkrpm.spec $(ETC)
	install -p -m 0644 dkms_dbversion $(VAR)
	install -p -m 0644 dkms.bash-completion $(BASHDIR)/dkms
	# install compressed manpage with proper timestamp and permissions
	gzip -c -9 dkms.8 > $(MAN)/dkms.8.gz
	chmod 0644 $(MAN)/dkms.8.gz
	touch --reference=dkms.8 $(MAN)/dkms.8.gz


DOCFILES=sample.spec sample.conf AUTHORS COPYING README.dkms sample-suse-9-mkkmp.spec sample-suse-10-mkkmp.spec

doc-perms:
	# ensure doc file permissions ok
	chmod 0644 $(DOCFILES)

install-redhat: install doc-perms
	install -p -m 0755 dkms_mkkerneldoth $(SBIN)

install-doc:
	mkdir -m 0755 -p $(DOCDIR)
	install -p -m 0644 $(DOCFILES) $(DOCDIR)

install-ubuntu: install copy-init install-doc
	mkdir -m 0755 -p $(KCONF)/preinst.d $(KCONF)/postinst.d
	install -p -m 0755 debian/kernel_preinst.d_dkms  $(KCONF)/preinst.d/dkms
	install -p -m 0755 debian/kernel_postinst.d_dkms $(KCONF)/postinst.d/dkms
	mkdir -m 0755 -p $(ETC)/template-dkms-mkdeb/debian
	install -p -m 0664 template-dkms-mkdeb/Makefile $(ETC)/template-dkms-mkdeb/
	install -p -m 0664 template-dkms-mkdeb/debian/* $(ETC)/template-dkms-mkdeb/debian/


tarball:
	tmp_dir=`mktemp -d /tmp/dkms.XXXXXXXX` ; \
	cp -a ../$(RELEASE_NAME) $${tmp_dir}/$(RELEASE_STRING) ; \
	sed -e "s/\[INSERT_VERSION_HERE\]/$(RELEASE_VERSION)/" dkms > $${tmp_dir}/$(RELEASE_STRING)/dkms ; \
	sed -e "s/\[INSERT_VERSION_HERE\]/$(RELEASE_VERSION)/" dkms.spec > $${tmp_dir}/$(RELEASE_STRING)/dkms.spec ; \
	find $${tmp_dir}/$(RELEASE_STRING) -depth -name .git -type d -exec rm -rf \{\} \; ; \
	find $${tmp_dir}/$(RELEASE_STRING) -depth -name \*~ -type f -exec rm -f \{\} \; ; \
	find $${tmp_dir}/$(RELEASE_STRING) -depth -name dkms\*.rpm -type f -exec rm -f \{\} \; ; \
	find $${tmp_dir}/$(RELEASE_STRING) -depth -name dkms\*.tar.gz -type f -exec rm -f \{\} \; ; \
	sync ; sync ; sync ; \
	tar cvzf $(RELEASE_STRING).tar.gz -C $${tmp_dir} $(RELEASE_STRING) ; \
	rm -rf $${tmp_dir} ;


rpm: tarball dkms.spec
	tmp_dir=`mktemp -d /tmp/dkms.XXXXXXXX` ; \
	mkdir -p $${tmp_dir}/{BUILD,RPMS,SRPMS,SPECS,SOURCES} ; \
	cp $(RELEASE_STRING).tar.gz $${tmp_dir}/SOURCES ; \
	sed "s/\[INSERT_VERSION_HERE\]/$(RELEASE_VERSION)/" dkms.spec > $${tmp_dir}/SPECS/dkms.spec ; \
	pushd $${tmp_dir} > /dev/null 2>&1; \
	rpmbuild -ba --define "_topdir $${tmp_dir}" SPECS/dkms.spec ; \
	popd > /dev/null 2>&1; \
	cp $${tmp_dir}/RPMS/noarch/* $${tmp_dir}/SRPMS/* . ; \
	rm -rf $${tmp_dir}

deb: tarball
	pdebuild --buildresult $(shell pwd)/..
