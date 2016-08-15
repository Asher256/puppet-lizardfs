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

  Exec {
    user => 'root',
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Class['lizardfs']
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Class['lizardfs'],
                Package[$lizardfs::metalogger_package]],
    notify  => Exec['mfschunkserver reload']
  }

  package { $lizardfs::metalogger_package:
    ensure  => present,
    require => Class['lizardfs']
  }

  file { "${lizardfs::cfgdir}/mfsmetalogger.cfg":
    content => template('lizardfs/etc/lizardfs/mfsmetalogger.cfg.erb'),
    require => Package[$lizardfs::metalogger_package],
    notify  => Exec['mfsmetalogger reload']
  }

  if $manage_service {
    service { $lizardfs::metalogger_service:
      ensure  => running,
      enable  => true,
      require => File["${lizardfs::cfgdir}/mfsmetalogger.cfg"],
    }

    -> exec { 'mfsmetalogger reload':
      command     => 'mfsmetalogger reload',
      refreshonly => true,
    }
  }
  else {
    exec { 'mfsmetalogger reload':
      command     => 'true',
      refreshonly => true,
      require     => File["${lizardfs::cfgdir}/mfsmetalogger.cfg"],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
