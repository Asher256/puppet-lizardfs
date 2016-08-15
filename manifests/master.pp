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
#   exports             => ['*    /    ro'],
#   first_personality   => 'MASTER',
#   options             => {},
#   goals               => ['1 1 : _'],
#   manage_service      => true,
# }
#
# === Parameters
#
# [*ensure*] this parameter is passed to the LizardFS Master package.
# You can specify: present, absent or the package version.
#
# [*first_personality*] possible values MASTER or SHADOW. Once the
# personnality is chosen, it is not going to be overwritten by Puppet again.
# Why? Because the personality is supposed to be changed by a failover
# script started by keepalived or Pacemaker.
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
#
# [*topology*] a list mfstopology.cfg lines:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfstopology.cfg.5.txt
#
# [*globaliolimits*] a list globaliolimits.cfg lines:
# https://github.com/lizardfs/lizardfs/blob/master/doc/globaliolimits.cfg.5.txt
#
# [*manage_service*] True to tell Puppet to start or stop the lizardfs-master
# service automatically.
#

class lizardfs::master(
  $ensure = 'present',
  $first_personality,
  $exports,
  $options = {},
  $goals = [],
  $topology = [],
  $globaliolimits = [],
  $manage_service = true)
{
  validate_string($ensure)
  validate_re($first_personality, '^MASTER$|^SHADOW$')
  validate_array($exports)
  validate_hash($options)
  validate_array($goals)
  validate_array($topology)
  validate_array($globaliolimits)
  validate_bool($manage_service)

  if has_key(upcase($options), 'PERSONALITY') {
    fail('It is forbidden to modify the personality of LizardFS Master with key PERSONALITY in \'lizardfs::master::options\'. Use \'lizardfs::master::first_personality\' to set the first personality.')
  }

  include lizardfs

  Package {
    require => Class['lizardfs']
  }

  Exec {
    user => 'root',
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => Package[$::lizardfs::master_package],
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Package[$::lizardfs::master_package],
  }

  Service {
    require => Package[$::lizardfs::master_package],
  }

  # Packages
  package { $::lizardfs::master_package:
    ensure  => present,
  }

  package { $::lizardfs::adm_package:
    ensure => present,
  }

  # $cfgdir is set because some templates use it (like the script generate-mfsmaster.cfg)
  $cfgdir = $::lizardfs::cfgdir
  $script_generate_mfsmaster = "${lizardfs::cfgdir}generate-mfsmaster-cfg.sh"

  # /etc/lizardfs/mfsmaster.cfg is generated with $script_generate_mfsmaster
  # $script_generate_mfsmaster will do this:
  #   1. cat $mfsmaster_header > /etc/lizardfs/mfsmaster.cfg
  #   2. echo "PERSONALITY=$(cat $mfsmaster_personality)"
  $mfsmaster_header = "${lizardfs::cfgdir}.mfsmaster.header.cfg"
  $mfsmaster_personality = "${lizardfs::cfgdir}.mfsmaster_personality"

  if $::osfamily == 'RedHat' {
    $metadata_file = '/var/lib/mfs/metadata.mfs'
  }
  elsif $::osfamily == 'Debian' {
    $metadata_file = '/var/lib/lizardfs/metadata.mfs'
  }
  else {
    fail("Your operating system ${::operatingsystem} is not supported by the class lizardfs::master")
  }

  exec { $script_generate_mfsmaster:
    refreshonly => true,
    subscribe   => File[$mfsmaster_header],
    require     => File[$script_generate_mfsmaster],
    notify      => Exec['mfsmaster reload']
  }

  exec { "echo '${first_personality}' >'${mfsmaster_personality}'":
    unless  => "test -f '${mfsmaster_personality}'",
  }

  -> file { $mfsmaster_header:
    content => template('lizardfs/etc/lizardfs/mfsmaster.cfg.erb'),
  }

  -> file { $script_generate_mfsmaster:
    mode    => '0755',
    content => template('lizardfs/etc/lizardfs/generate-mfsmaster.cfg.sh.erb'),
  }

  -> file { "${lizardfs::cfgdir}mfsexports.cfg":
    content => template('lizardfs/etc/lizardfs/mfsexports.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${lizardfs::cfgdir}mfsgoals.cfg":
    content => template('lizardfs/etc/lizardfs/mfsgoals.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${lizardfs::cfgdir}mfstopology.cfg":
    content => template('lizardfs/etc/lizardfs/mfstopology.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${lizardfs::cfgdir}globaliolimits.cfg":
    content => template('lizardfs/etc/lizardfs/globaliolimits.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> exec { "cp ${metadata_file}.empty ${metadata_file}":
    unless => "test -f '${metadata_file}'",
    user   => $::lizardfs::user,
  }

  if $manage_service {
    Exec["cp ${metadata_file}.empty ${metadata_file}"]

    -> service { $::lizardfs::master_service:
      ensure => running,
      enable => true,
    }

    -> exec { 'mfsmaster reload':
      command     => 'mfsmaster reload',
      refreshonly => true,
    }
  }
  else {
    Exec["cp ${metadata_file}.empty ${metadata_file}"]

    # will do nothing if we choose to not manage the service
    -> exec { 'mfsmaster reload':
      command     => 'true',
      refreshonly => true,
      require     => Exec['cp /var/lib/lizardfs/metadata.mfs.empty /var/lib/lizardfs/metadata.mfs'],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
