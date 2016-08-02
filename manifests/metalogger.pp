#
# == Define: lizardfs::metalogger
#
# 'lizardfs::metalogger': install and configure LizardFS metalogger.
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
# class {'lizardfs::metalogger':
#   ensure  => 'present',
#   options => {'PERSONALITY' => 'metalogger'},
#   exports => ['*    /    ro'],
#   goals => ['1 1 : _'],
#   manage_service => false,
# }
#
# === Parameters
#
# [*ensure*] this parameter is passed to the LizardFS Metalogger package.
# You can specify: present, absent or the package version.
#
# [*options*] keys/values of the configuration file mfsmetalogger.cfg:
# https://github.com/lizardfs/lizardfs/blob/metalogger/doc/mfsmetalogger.cfg.5.txt
#
# [*manage_service*] True to tell Puppet to start or stop the lizardfs-metalogger
# service automatically.
#

class lizardfs::metalogger(
  $ensure = 'present',
  $options = {},
  $manage_service = true)
{
  validate_string($ensure)
  validate_hash($options)
  validate_bool($manage_service)

  include lizardfs

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
    $service_name = 'lizardfs-metalogger'
    $metalogger_package = 'lizardfs-metalogger'
    package { $metalogger_package:
      ensure  => present,
    }
  }
  else {
    fail()
  }

  file { '/etc/lizardfs/mfsmetalogger.cfg' :
    ensure  => present,
    content => template('lizardfs/etc/lizardfs/mfsmetalogger.cfg.erb'),
    require => Package[$metalogger_package],
  }

  if $manage_service {
    service { $service_name :
      ensure  => running,
      enable  => true,
      require => File['/etc/lizardfs/mfsmetalogger.cfg'],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
