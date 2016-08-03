#
# == Define: lizardfs::master
#
# 'lizardfs::master': install and configure LizardFS master.
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
# class {'lizardfs::master':
#   ensure  => 'present',
#   options => {'PERSONALITY' => 'master'},
#   exports => ['*    /    ro'],
#   goals => ['1 1 : _'],
#   manage_service => false,
# }
#
# === Parameters
#
# [*ensure*] this parameter is passed to the LizardFS Master package.
# You can specify: present, absent or the package version.
#
# [*options*] keys/values of the configuration file mfsmaster.cfg:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfsmaster.cfg.5.txt
#
# [*exports*] a list of mfsexports.cfg lines:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfsexports.cfg.5.txt
#
# [*goals*] a list mfsgoals.cfg lines:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfsgoals.cfg.5.txt

# [*topology*] a list mfstopology.cfg lines:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfstopology.cfg.5.txt
#
# [*manage_service*] True to tell Puppet to start or stop the lizardfs-master
# service automatically.
#

class lizardfs::master(
  $ensure = 'present',
  $options = {},
  $exports = [],
  $goals = [],
  $topology = [],
  $manage_service = true)
{
  validate_string($ensure)
  validate_hash($options)
  validate_array($exports)
  validate_array($goals)
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
    $service_name = 'lizardfs-master'
    $master_package = 'lizardfs-master'
    package { $master_package:
      ensure  => present,
    }

    package { 'lizardfs-admin':
      ensure => present,
    }
  }
  else {
    fail()
  }

  file { '/etc/lizardfs/mfsmaster.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfsmaster.cfg.erb'),
    require => [Package[$master_package]],
  }

  -> file { '/etc/lizardfs/mfsexports.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfsexports.cfg.erb'),
    require => [Package[$master_package]],
  }

  -> file { '/etc/lizardfs/mfsgoals.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfsgoals.cfg.erb'),
    require => [Package[$master_package]],
  }

  -> file { '/etc/lizardfs/mfstopology.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfstopology.cfg.erb'),
    require => [Package[$master_package]],
  }

  -> exec { 'cp /var/lib/lizardfs/metadata.mfs.empty /var/lib/lizardfs/metadata.mfs':
    unless => 'test -f /var/lib/lizardfs/metadata.mfs',
    user   => 'lizardfs',
  }

  if $manage_service {
    service { $service_name :
      ensure  => running,
      enable  => true,
      require => Package[$master_package],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
