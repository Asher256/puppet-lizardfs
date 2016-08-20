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
# Contact: asher256@gmail.com
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
# You can specify: present, absent or the package version.
#
# [*options*] Keys/values of the configuration file mfschunkserver.cfg
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfschunkserver.cfg.5.txt
#
# [*hdd*] a list of mount points that will:
#   1. Created automatically by Puppet (with file {})
#   2. Added to /etc/lizardfs/mfshdd.cfg
#
# [*hdd_disabled*] a list of mount points that will be 'marked for removal'.
# Each mount point will be added to /etc/lizardfs/mfshdd.cfg with an asterisk *
# before the point point (example: */mount/point).
# Read this page for more information about this:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfshdd.cfg.5.txt
#
# [*manage_service*] start or stop the lizardfs-chunkserver service
#

class lizardfs::chunkserver(
  $ensure = 'present',
  $hdd = [],
  $hdd_disabled = [],
  $options = {},
  $manage_service = true)
{
  validate_string($ensure)
  validate_hash($options)
  validate_array($hdd)
  validate_array($hdd_disabled)
  validate_bool($manage_service)

  if empty($hdd) and empty($hdd_disabled) {
    fail('You need to add at least one directory to the array \'lizardfs::chunkserver::hdd\' OR \'lizardfs::chunkserver::hdd_disabled\'.')
  }

  include lizardfs
  $working_user = $::lizardfs::user
  $working_group = $::lizardfs::group

  Exec {
    user => 'root',
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Class['lizardfs']
  }

  Package {
    require => Class['lizardfs']
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Class['lizardfs'],
                Package[$::lizardfs::chunkserver_package]],
    notify  => Exec['mfschunkserver reload']
  }

  package { $::lizardfs::chunkserver_package:
    ensure => $ensure,
  }

  file { $hdd:
    ensure => directory,
    mode   => $::lizardfs::secure_dir_permission,
    owner  => $::lizardfs::user,
    group  => $::lizardfs::group,
  }

  file { "${lizardfs::cfgdir}mfschunkserver.cfg":
    content => template('lizardfs/etc/lizardfs/mfschunkserver.cfg.erb'),
  }

  file { "${lizardfs::cfgdir}mfshdd.cfg":
    content => template('lizardfs/etc/lizardfs/mfshdd.cfg.erb'),
  }

  if $manage_service {
    if $::osfamily == 'Debian' {
      file { '/etc/default/lizardfs-chunkserver':
        ensure  => present,
        content => "# MANAGED BY PUPPET\nLIZARDFSCHUNKSERVER_ENABLE=true\nDAEMON_OPTS=\"\"\n",
        before => Service[$::lizardfs::chunkserver_service],
      }
    }

    File[$hdd]
    -> File["${lizardfs::cfgdir}mfschunkserver.cfg"]
    -> File["${lizardfs::cfgdir}mfshdd.cfg"]

    -> service { $::lizardfs::chunkserver_service:
      ensure => running,
      enable => true,
    }

    -> exec { 'mfschunkserver reload':
      command     => 'mfschunkserver reload',
      refreshonly => true,
    }
  }
  else {
    File[$hdd]
    -> File["${lizardfs::cfgdir}mfschunkserver.cfg"]
    -> File["${lizardfs::cfgdir}mfshdd.cfg"]

    -> exec { 'mfschunkserver reload':
      command     => 'true',    # lint:ignore:quoted_booleans
      refreshonly => true,
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
