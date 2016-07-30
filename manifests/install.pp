#
# == Define: lizardfs
#
# 'lizardfs::install' install the packages and create some directories/files
#
# This class follows the recommendations of the "Puppet Labs Style Guide":
# http://docs.puppetlabs.com/guides/style_guide.html . If you want to
# contribute, please check your code with puppet-lint.
#
# === Authors
#
# Copyright (c) Asher256
#
# License: Apache 2.0
# Contact: asher256@gmail.com
# URL: https://github.com/Asher256/puppet-lizardfs
#
# === Examples
#
# include lizardfs::install
#
class lizardfs::install() {
  file { '/etc/mfs':
    ensure => directory,
    mode   => '0755',
    owner  => 'root',
    group  => 'root',
  }
}
# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
