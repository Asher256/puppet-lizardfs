#
# == Define: lizardfs
#
# 'lizardfs::*' classes will help you to configure LizardFS:
#
# This class follows the recommendations of the "Puppet Labs Style Guide":
# http://docs.puppetlabs.com/guides/style_guide.html . If you want to
# contribute, please check your code with puppet-lint.
#
# === Authors
#
# Copyright (c) Achraf Cherti (aka Asher256)
#
# License: Apache 2.0
# Contact: asher256@gmail.com
# URL: https://github.com/Asher256/puppet-lizardfs
#

class lizardfs::init::dirs() {
  # create the cfgdir (/etc/lizardfs on Debian, /etc/mfs/ on RedHat/CentOS)
  file { $::lizardfs::cfgdir:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0755',
  }

  if $::lizardfs::create_legacy {
    file { $::lizardfs::legacy_cfgdir:
      ensure  => directory,
      owner   => 'root',
      group   => 'root',
      mode    => '0755',
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
