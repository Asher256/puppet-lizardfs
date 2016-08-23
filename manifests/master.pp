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
# You can specify: present, absent or the package version
# (for example if the package is lizardfs-master-3.10.0-0el7.x86_64.rpm,
# then: ensure => '3.10.0-0el7').
#
# [*first_personality*] possible values HA-CLUSTER-MANAGED, MASTER or SHADOW. Once the
# personnality is chosen, it is not going to be overwritten by Puppet again.
# Why? Because the personality is supposed to be changed by a failover
# script started by keepalived or Pacemaker.
#
# [*options*] keys/values of the configuration file mfsmaster.cfg:
# ALL options need to be in the UPPER CASE.
# All options are permitted EXCEPT:
#   1. The option 'PERSONALITY' because you need to put it in
#        the argument $first_personality
#   2. The option 'DATA_PATH' (you can change it with the argument "$data_path".
#
# Documentation about the options of mfsmaster.cfg:
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
  $manage_service = true,
)
{
  validate_string($ensure)
  validate_re($first_personality, '^MASTER$|^SHADOW$|^HA-CLUSTER-MANAGED$')
  validate_array($exports)
  validate_hash($options)
  validate_array($goals)
  validate_array($topology)
  validate_array($globaliolimits)
  validate_bool($manage_service)

  $options_keys = upcase(keys($options))
  if 'PERSONALITY' in $options_keys {
    fail('It is forbidden to modify the personality of the LizardFS Master with "lizardfs::master::options[\'PERSONALITY\']". Use \'lizardfs::master::first_personality\' to set the first personality.')
  }

  if 'DATA_PATH' in $options_keys {
    fail('To modify DATA_PATH use the argument "lizardfs::data_path" instead of "lizardfs::master::options[\'DATA_PATH\']".')
  }

  include lizardfs
  $working_user = $::lizardfs::user
  $working_group = $::lizardfs::group

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
    ensure  => $ensure,
  }

  package { $::lizardfs::adm_package:
    ensure => $ensure,
  }

  # $cfgdir is set because some templates use it (like the script generate-mfsmaster.cfg)
  $cfgdir = $::lizardfs::cfgdir
  $script_generate_mfsmaster = "${lizardfs::cfgdir}generate-mfsmaster-cfg.sh"

  # /etc/lizardfs/mfsmaster.cfg is generated with $script_generate_mfsmaster
  # $script_generate_mfsmaster will do this:
  #   1. cat $mfsmaster_header > /etc/lizardfs/mfsmaster.cfg
  #   2. echo "PERSONALITY=$(cat $mfsmaster_personality)"
  $mfsmaster_cfg = "${lizardfs::cfgdir}mfsmaster.cfg"
  $mfsmaster_header = "${lizardfs::cfgdir}.mfsmaster.header.cfg"
  $mfsmaster_personality = "${lizardfs::cfgdir}.mfsmaster_personality"

  $metadata_dir = $::lizardfs::metadata_dir
  $metadata_file = "${metadata_dir}/metadata.mfs"

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

  # we create this legacy link because the vendor packages
  # (hosted on packages.lizardfs.org) continue to use the legacy
  # directory /etc/mfs/
  -> file { "${::lizardfs::legacy_cfgdir}mfsmaster.cfg":
    ensure  => 'link',
    target  => "${::lizardfs::cfgdir}mfsmaster.cfg",
    require => File[$::lizardfs::legacy_cfgdir],
  }

  -> file { "${lizardfs::cfgdir}mfsexports.cfg":
    content => template('lizardfs/etc/lizardfs/mfsexports.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${::lizardfs::legacy_cfgdir}mfsexports.cfg":
    ensure  => 'link',
    target  => "${::lizardfs::cfgdir}mfsexports.cfg",
    require => File[$::lizardfs::legacy_cfgdir],
  }

  -> file { "${lizardfs::cfgdir}mfsgoals.cfg":
    content => template('lizardfs/etc/lizardfs/mfsgoals.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${::lizardfs::legacy_cfgdir}mfsgoals.cfg":
    ensure  => 'link',
    target  => "${::lizardfs::cfgdir}mfsgoals.cfg",
    require => File[$::lizardfs::legacy_cfgdir],
  }

  -> file { "${lizardfs::cfgdir}mfstopology.cfg":
    content => template('lizardfs/etc/lizardfs/mfstopology.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${::lizardfs::legacy_cfgdir}mfstopology.cfg":
    ensure  => 'link',
    target  => "${::lizardfs::cfgdir}mfstopology.cfg",
    require => File[$::lizardfs::legacy_cfgdir],
  }

  -> file { "${lizardfs::cfgdir}globaliolimits.cfg":
    content => template('lizardfs/etc/lizardfs/globaliolimits.cfg.erb'),
    notify  => Exec['mfsmaster reload']
  }

  -> file { "${::lizardfs::legacy_cfgdir}globaliolimits.cfg":
    ensure  => 'link',
    target  => "${::lizardfs::cfgdir}globaliolimits.cfg",
    require => File[$::lizardfs::legacy_cfgdir],
  }

  -> exec { "echo 'MFSM NEW' > '${metadata_file}'":
    unless  => "test -f '${metadata_file}'",
    user    => $::lizardfs::user,
    require => File[$lizardfs::metadata_dir],
  }

  if $manage_service {
    if $::osfamily == 'Debian' {
      file { '/etc/default/lizardfs-master':
        ensure  => present,
        content => "# MANAGED BY PUPPET\nLIZARDFSMASTER_ENABLE=true\nDAEMON_OPTS=\"-c '${mfsmaster_cfg}'\"\n",
        before  => Service[$::lizardfs::master_service],
      }
    }

    Exec["echo 'MFSM NEW' > '${metadata_file}'"]

    -> service { $::lizardfs::master_service:
      ensure => running,
      enable => true,
    }

    -> exec { 'mfsmaster reload':
      refreshonly => true,
    }
  }
  else {
    Exec["echo 'MFSM NEW' > '${metadata_file}'"]

    # will do nothing if we choose to not manage the service
    -> exec { 'mfsmaster reload':
      command     => 'true', # lint:ignore:quoted_booleans
      refreshonly => true,
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
