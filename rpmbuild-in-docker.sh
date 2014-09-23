#!/bin/bash
set -ex
echo "starting $0"

# allow the user to overwrite our yum.conf if he likes, otherwise use .repo files.
cp /src/yum.conf /etc/ || echo ""

cp /src/*.repo /etc/yum.repos.d/ || echo ""

cat > /etc/yum.repos.d/local.repo << EOF
[local]
name=local
baseurl=file:///src/RPMS
enabled=1
gpgcheck=0
protect=1
priority=1
EOF

createrepo /src/RPMS
yum install yum-plugin-priorities -y
yum update -y

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

if [[ $SRPM == *nodejs010* ]]; then
  yum install -y nodejs010-build nodejs010-scldevel v8314-build v8314-scldevel
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" --define="scl nodejs010" "$SRPM"
elif [[ $SRPM == *ruby193* ]]; then
  yum install -y ruby193-build ruby193-scldevel nodejs ruby193-v8-devel
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" --define="scl ruby193" "$SRPM"
elif [[ $SRPM == *postgresql92* ]]; then
  yum install -y postgresql92-build postgresql92-scldevel
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" --define="scl postgresql92" "$SRPM"
elif [[ $SRPM == *python27* ]]; then
  yum install -y python27-build python27-scldevel
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" --define="scl python27" "$SRPM"
elif [[ $SRPM == *python33* ]]; then
  yum install -y python33-build python33-scldevel
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" --define="scl python33" "$SRPM"
elif [[ $SRPM == *php54* ]]; then
  yum install -y php54-build php54-scldevel
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" --define="scl php54" "$SRPM"
else
  rpmbuild --rebuild --define="_topdir /docker-rpm-build-root" "$SRPM"
fi

cp -r /docker-rpm-build-root/RPMS /src
echo "Done"
