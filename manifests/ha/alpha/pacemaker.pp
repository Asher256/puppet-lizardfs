#
# == Define: lizardfs::ha::pacemaker
#
# 'lizardfs::ha::pacemaker': install and configure corosync and pacemaker for
# HA LizardFS.
#
# This class follows the recommendations of the "Puppet Labs Style Guide":
# http://docs.puppetlabs.com/guides/style_guide.html . If you want to
# contribute, please check your code with puppet-lint.
#
# === Authors
#
# Copyright (c) fchioralia
#
# License: Apache 2.0
# Contact: fchioralia@gmail.com
# URL: https://github.com/Asher256/puppet-lizardfs
#
# === Examples
#
# class {'lizardfs::ha::pacemaker':
#   multicast_address  => "239.1.1.2",
#   quorum_members     => [ 'master.dev', 'shadow.dev' ],
# }
#
# === Parameters
#
# [*quorum_members*] a list of the Lizardfs masters IPs or FQDNs (must be resolvable by dns).
# Ex: quorum_members   => ['lizardfs-master.dev', 'lizardfs-shadow.dev'],
#
# [*multicast_address*] the multicast address for corosync service, if you have multiple corosync clusters.
# Default: multicast_address  = "239.1.1.2",
#
# === Important
#
# Require the module https://forge.puppet.com/puppet/corosync
#
# Open in firewall the following ports, besides the ones for lizardfs.
# #multicast
# -A INPUT -p udp -m state --state NEW -m multiport --dports 5404,5405 -j ACCEPT
# #pcsd
# -A INPUT -m tcp -p tcp -m state --state NEW --dport 2224 -j ACCEPT
#
### and the VIP for lfs master service like: options => { MASTER_HOST => "192.168.1.xxx", }

class lizardfs::ha::pacemaker(
  $multicast_address = "239.1.1.2",
  $quorum_members    = [],
)
{
  if $::osfamily == 'RedHat' {
    yumrepo { "centos-base-lizardfs":
      mirrorlist => "http://mirrorlist.centos.org/?release=$operatingsystemmajrelease&arch=\$basearch&repo=os",
      descr => "CentOS-$operatingsystemmajrelease - Base",
      enabled => 1,
      gpgcheck => 0,
      before => Class['corosync'],
    }
  }

  if ! is_ip_address($multicast_address) {
    fail('The multicast_address is not a valid IP address.')
  }

  if ! is_ip_address($lizardfs::master::options[MASTER_HOST]) {
    fail('Set the virtual IP for HA lfs master service like: options => { MASTER_HOST => "192.168.1.xxx", }.')
  }

  if ! $lizardfs::master::options[ADMIN_PASSWORD]  {
    fail('Set the admin password for lizardfs::master service like: options => { ADMIN_PASSWORD => "password", }.')
  }

  if empty($quorum_members) {
    fail('The quorum_members parameter is required.')
  }

  class { 'corosync':
    enable_secauth             => true,
    authkey                    => "/var/lib/puppet/ssl/certs/ca.pem",
    bind_address               => $ipaddress,
    multicast_address          => $multicast_address,
    package_pcs                => true,
    manage_pcsd_service        => true,
    # debug                      => true,
    set_votequorum             => true,
    quorum_members             => $quorum_members,
    # votequorum_expected_votes  => 2,
    require                    => Class['lizardfs::master'],
  }

  corosync::service { 'pacemaker':
    version => '0',
  }

  cs_property { 'stonith-enabled' :
    value   => 'false',
    cib     => 'puppet'
  } ~> Cs_commit['puppet']

  cs_property { 'no-quorum-policy' :
    value   => 'ignore',
    cib     => 'puppet'
  } ~> Cs_commit['puppet']

  cs_primitive { 'lizardfs-master':
    primitive_class => 'ocf',
    provided_by     => 'lizardfs',
    primitive_type  => 'metadataserver',
    parameters      => { 'master_cfg' => "${::lizardfs::cfgdir}mfsmaster.cfg" },
    metadata        => { 'clone-node-max' => '1', 'master-max' => '1', 'master-node-max' => '1', 'notify' => 'true', 'target-role' => 'Master'},
    promotable      => 'true',
    cib             => 'puppet',
    operations      => {
      'monitor' => { role => 'Master', 'interval' => '1s', 'timeout' => '30s' },
      'monitor' => { role => 'Slave', 'interval' => '2s', 'timeout' => '40s' },
      'start'   => { 'interval' => '0', 'timeout' => '1800s' },
      'stop'    => { 'interval' => '0', 'timeout' => '1800s' },
      'promote' => { 'interval' => '0', 'timeout' => '1800s' },
      'demote'  => { 'interval' => '0', 'timeout' => '1800s' },
    },
  } ~> Cs_commit['puppet']

  cs_primitive { 'Failover-IP':
    primitive_class => 'ocf',
    provided_by     => 'heartbeat',
    primitive_type  => 'IPaddr2',
    parameters      => { 'ip' => "${lizardfs::master::options[MASTER_HOST]}", 'cidr_netmask' => '24' },
    operations      => { 'monitor' => { 'interval' => '1s' }, },
    cib             => 'puppet'
  } ~> Cs_commit['puppet']

  # cs_rsc_defaults { 'resource-stickiness' :
  #    value => '100',
  #    cib   => 'puppet'
  #  }~> Cs_commit['puppet']

  cs_colocation { 'ip_with_master':
    primitives => [ ['Failover-IP', 'ms_lizardfs-master:Master'], ],
    cib        => 'puppet'
  } ~> Cs_commit['puppet']

  cs_order { 'master-after-ip':
    first   => 'Failover-IP:start',
    second  => 'ms_lizardfs-master:promote',
    require => Cs_colocation['ip_with_master'],
    cib     => 'puppet'
  } ~> Cs_commit['puppet']

  cs_shadow {
    'puppet':
  }

  cs_commit {
    'puppet':
  }

  file { 'lizardfs.ocf.folder':
    path    => '/usr/lib/ocf/resource.d/lizardfs/',
    ensure  => directory,
    mode    => 755,
    require => Package['pacemaker'],
  }
  -> file { 'lizardfs.ocf':
    path    => '/usr/lib/ocf/resource.d/lizardfs/metadataserver',
    ensure  => file,
    mode    => 755,
    content => template("lizardfs/lizardfs.ocf"),
    before  => Service['pacemaker'],
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
