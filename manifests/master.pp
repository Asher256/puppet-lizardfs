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
#   ensure              => 'present',
#   first_personality => 'MASTER',
#   options             => {'PERSONALITY' => 'master'},
#   exports             => ['*    /    ro'],
#   goals               => ['1 1 : _'],
#   manage_service      => false,
# }
#
# === Parameters
#
# [*ensure*] this parameter is passed to the LizardFS Master package.
# You can specify: present, absent or the package version.
#
# [*first_personality*] possible values MASTER or SHADOW. Once the
# personnality is chosen, it is not going to be overwritten by Puppet.
# It is the of the high availability tool like Keepalived or Pacemaker.
#
# [*options*] keys/values of the configuration file mfsmaster.cfg:
# All options are permitted EXCEPT the option 'PERSONALITY' because
# you need to put it on $first_personality
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
  $first_personality,
  $options = {},
  $exports = [],
  $goals = [],
  $topology = [],
  $manage_service = true)
{
  validate_string($ensure)
  validate_re($first_personality, '^MASTER$|^SHADOW$')
  validate_hash($options)
  validate_array($exports)
  validate_array($goals)
  validate_array($topology)
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

    package { 'lizardfs-adm':
      ensure => present,
    }
  }
  else {
    fail()
  }

  Package[$master_package]

  ->
  exec { "echo '${first_personality}' >/etc/lizardfs/.mfsmaster_personality.cfg":
    unless => 'test -f /etc/lizardfs/.mfsmaster_personality.cfg',
  }

  ->
  file { '/etc/lizardfs/mfsmaster.cfg' :
    content => template('lizardfs/etc/lizardfs/mfsmaster.cfg.erb'),
  }

  -> file { '/etc/lizardfs/mfsexports.cfg' :
    content => template('lizardfs/etc/lizardfs/mfsexports.cfg.erb'),
  }

  -> file { '/etc/lizardfs/mfsgoals.cfg' :
    content => template('lizardfs/etc/lizardfs/mfsgoals.cfg.erb'),
  }

  -> file { '/etc/lizardfs/mfstopology.cfg' :
    content => template('lizardfs/etc/lizardfs/mfstopology.cfg.erb'),
  }

  -> exec { 'cp /var/lib/lizardfs/metadata.mfs.empty /var/lib/lizardfs/metadata.mfs':
    unless => 'test -f /var/lib/lizardfs/metadata.mfs',
    user   => 'lizardfs',
  }

  if $manage_service {
    service { $service_name :
      ensure  => running,
      enable  => true,
      require => [Package[$master_package],
                  Exec['cp /var/lib/lizardfs/metadata.mfs.empty /var/lib/lizardfs/metadata.mfs']]
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
