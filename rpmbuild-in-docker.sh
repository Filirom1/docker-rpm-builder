#!/bin/bash
set -ex
echo "starting $0"

# allow the user to overwrite our yum.conf if he likes, otherwise use .repo files.
cp /src/yum.conf /etc/ || echo ""

cp /src/*.repo /etc/yum.repos.d/ || echo ""

SPEC=$(find /src -maxdepth 1 -name '*.spec' -print -quit)
mkdir -p /docker-rpm-build-root/{BUILD,RPMS,SOURCES,SPECS,SRPMS}

cp /src/*.src.rpm /docker-rpm-build-root/SRPMS/ || echo ""

if test -n "$SPEC"; then
  chown -R root. /src
  cp /src/* /docker-rpm-build-root/SOURCES
  spectool --directory /docker-rpm-build-root/SOURCES -g "$SPEC"
  rpmbuild -bs --define="_topdir /docker-rpm-build-root" "$SPEC"
  cp -r /docker-rpm-build-root/SRPMS /src
fi

SRPM=$(find /docker-rpm-build-root/SRPMS/ -maxdepth 1 -name '*.src.rpm' -print -quit)

ls -lh $SRPM
yum-builddep "$SRPM" -y --nogpgcheck
rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" "$SRPM"
cp -r /docker-rpm-build-root/RPMS /src
echo "Done"
