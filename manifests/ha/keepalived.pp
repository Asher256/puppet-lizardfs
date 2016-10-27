# == Class: lizardfs::keepalived
#
# Configure the high availability of LizardFS with keepalived.
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
#  class {'lizardfs::ha::keepalived':
#    interface  => 'eth0',
#    auth_pass  => 'MyPassword',
#    virtual_ip => ['192.168.1.100'],
#  }
#
# === Parameters
#
# [*interface*] the network interface (e.g. eth0)
#
# [*priority*] keepalived priority (e.g. 100)
#
# [*state*] keepalived state (MASTER or BACKUP)
#
# [*auth_pass] the authentication password
#
# [*virtual_ip*] the virtual IP address (need to be a list)
#
# [*virtual_router_id*] arbitary unique number 0..255
# used to differentiate multiple instances of vrrpd
# running on the same NIC (and hence same socket).
# You need to have the same value on the members of the
# same cluster.
#
# [*lvs_id*] keepalived's lvs_id
#
# [*track_script_interval*] check the track script every x seconds (keepalived)
#
# [*track_script_fall*] requires x failures for KO status (keepalived)
#
# [*track_script_raise*] requires x success for OK status (keepalived)
#

class lizardfs::ha::keepalived(
  $interface,
  $auth_pass,
  $virtual_ip,
  $state,
  $lvs_id,
  $virtual_router_id = 99,
  $priority = 100,
  $email_enabled = false,
  $smtp_server = '127.0.0.1',
  $email_from = 'noreply@domain.com',
  $email_to = 'noreplay@domain.com',
  $track_script_interval = 10,
  $track_script_fall = 5,
  $track_script_raise = 2,
) {
  validate_string($interface)
  validate_integer($priority)
  validate_string($state)
  validate_string($auth_pass)
  validate_array($virtual_ip)
  validate_integer($virtual_router_id)
  validate_string($lvs_id)
  validate_string($email_to)
  validate_string($email_from)
  validate_string($smtp_server)

  include ::lizardfs::master

  File {
    ensure  => present,
    mode    => '0644',
    owner   => 'root',
    group   => 'root',
  }

  $mfsmaster_personality = $::lizardfs::master::mfsmaster_personality
  $script_generate_mfsmaster = $::lizardfs::master::script_generate_mfsmaster

  $cfgdir = $::lizardfs::cfgdir

  Class['::lizardfs::master']

  -> package { 'keepalived':
    ensure => present
  }

  -> file { "${::lizardfs::cfgdir}lfs_failover.sh":
    ensure  => present,
    mode    => '0700',
    content => template('lizardfs/etc/lizardfs/lfs_failover.sh'),
  }

  # TODO: remove this file
  -> file { "${::lizardfs::cfgdir}lfs_failover_to_master.sh":
    ensure  => absent,
    mode    => '0700',
    content => "#!/usr/bin/env bash
${::lizardfs::cfgdir}lfs_failover.sh to_master",
  }

  # TODO: remove this file
  -> file { "${::lizardfs::cfgdir}lfs_failover_to_shadow.sh":
    ensure  => absent,
    mode    => '0700',
    content => "#!/usr/bin/env bash
${::lizardfs::cfgdir}lfs_failover.sh to_shadow",
  }

  -> file { '/etc/keepalived/keepalived.conf':
    content => template('lizardfs/etc/keepalived/keepalived.conf.erb'),
    notify  => Exec['reload-keepalived'],
  }

  -> service { 'keepalived':
    ensure    => running,
  }

  -> exec { 'reload-keepalived':
    command     => 'systemctl reload keepalived',
    path        => '/bin:/sbin:/usr/bin:/usr/sbin',
    refreshonly => true,
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
