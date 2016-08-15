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
# Contact: asher256@gmail.com
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

  package { $::lizardfs::client_package:
    ensure  => present,
    require => Class['lizardfs']
  }

  # fuse is needed to mount the partitions
  package { $::lizardfs::fuse_package:
    ensure  => present,
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
