FROM centos:centos6
MAINTAINER Filirom1 Filirom1@gmail.com
RUN yum install -y rpmdevtools yum-utils make gcc tar bash bzip2 coreutils cpio diffutils system-release findutils gawk gcc gcc-c++ grep gzip info make patch redhat-rpm-config rpm-build sed shadow-utils tar unzip util-linux which xz
