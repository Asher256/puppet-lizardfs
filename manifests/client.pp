#
# == Define: lizardfs::client
#
# 'lizardfs::client': install and configure LizardFS Client.
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
#
# URL: https://github.com/Asher256/puppet-lizardfs
#
# === Examples
#
# class {'lizardfs::client':
#   ensure => 'present',
# }
#
# === Parameters
#
# [*ensure*] This parameter is passed to the LizardFS's client package.
#            You can specify: present, absent or the package version.
#

class lizardfs::client($ensure = 'present')
{
  validate_string($ensure)

  include lizardfs

  Package {
    require => Class['lizardfs']
  }

  if $::operatingsystem in ['Debian', 'Ubuntu'] {
    $client_package = 'lizardfs-client'

    package { $client_package:
      ensure  => present,
    }
  }
  else {
    fail()
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
