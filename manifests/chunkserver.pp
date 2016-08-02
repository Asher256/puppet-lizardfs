#
# == Define: lizardfs::chunkserver
#
# 'lizardfs::chunkserver': install and configure a LizardFS chunkserver.
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
# class {'lizardfs::chunkserver':
#   ensure => present,
# }
#
# === Parameters
#
# [*ensure*] This parameter is passed to the LizardFS Chunkserver package.
# You can specify: present, absent or the package version
#
# [*options*] Keys/values of the configuration file mfschunkserver.cfg
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfschunkserver.cfg.5.txt
#
# [*hdd*] a list of mount points that will:
#     1. Created automatically by Puppet (thanks to file {})
#     2. Added to /etc/mfshdd.cfg
#
# [*hdd_disabled*] a list of mount points that will be 'marked for removal'.
# Each mount point will be added to /etc/mfshdd.cfg with an asterisk *
# before the point point (example: */mount/point).
# Read this page for more information about this:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfshdd.cfg.5.txt
#
# [*manage_service*]  start or stop the lizardfs-chunkserver service
#

class lizardfs::chunkserver(
  $ensure = 'present',
  $options = {},
  $hdd = [],
  $hdd_disabled = [],
  $manage_service = true)
{
  validate_string($ensure)
  validate_hash($options)
  validate_array($hdd)
  validate_bool($manage_service)

  include lizardfs

  Exec {
    user => 'root',
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Class['lizardfs']
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['lizardfs']
  }

  Package {
    require => Class['lizardfs']
  }

  if $::operatingsystem in ['Debian', 'Ubuntu'] {
    $service_name = 'lizardfs-chunkserver'
    $chunkserver_package = 'lizardfs-chunkserver'

    package { $chunkserver_package:
      ensure  => present,
    }
  }
  else {
    fail()
  }

  file { $hdd:
    ensure  => directory,
    mode    => '0750',
    owner   => 'lizardfs',
    group   => 'lizardfs',
    require => Package[$chunkserver_package],
  }

  ->
  file { '/etc/lizardfs/mfschunkserver.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfschunkserver.cfg.erb'),
    require => Package[$chunkserver_package],
  }

  file { '/etc/lizardfs/mfshdd.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfshdd.cfg.erb'),
    require => Package[$chunkserver_package],
  }

  if $manage_service {
    service { $service_name :
      ensure  => running,
      enable  => true,
      require => [Package[$chunkserver_package],
                  File['/etc/lizardfs/mfschunkserver.cfg'],
                  File['/etc/lizardfs/mfshdd.cfg']],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
