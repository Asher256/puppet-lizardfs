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
# [*data_path*] (optional) the directory where the LizardFS Master's data is
# stored. It is the equivalent of DATA_PATH on mfsmaster.cfg.
# More informations about DATA_PATH can be found in this page:
# https://github.com/lizardfs/lizardfs/blob/master/doc/mfsmaster.cfg.5.txt
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
  $data_path = undef,
  $enable_pacemaker = false,
  $pacemaker_quorum_members = [],
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

  if $data_path != undef {
    validate_absolute_path($data_path)
  }

  $options_keys = upcase(keys($options))
  if 'PERSONALITY' in $options_keys {
    fail('It is forbidden to modify the personality of the LizardFS Master with "lizardfs::master::options[\'PERSONALITY\']". Use \'lizardfs::master::first_personality\' to set the first personality.')
  }

  if 'DATA_PATH' in $options_keys {
    fail('To modify DATA_PATH use the argument "lizardfs::master::data_path" instead of "lizardfs::master::options[\'data_path\']".')
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
  $mfsmaster_header = "${lizardfs::cfgdir}.mfsmaster.header.cfg"
  $mfsmaster_personality = "${lizardfs::cfgdir}.mfsmaster_personality"

  #
  # The default metadata dir and $data_path management
  # The data_path will be stored in: $final_data_path
  #
  if $::osfamily == 'RedHat' {
    $default_data_path = '/var/lib/mfs'
  }
  elsif $::osfamily == 'Debian' {
    $default_data_path = '/var/lib/lizardfs'
  }
  else {
    fail("Your operating system ${::operatingsystem} is not supported by the class lizardfs::master")
  }

  if $data_path == undef {
    # final_data_path = the default one (chosen by the package manager)
    $metadata_file = "${default_data_path}/metadata.mfs"
    $final_data_path = $default_data_path
  }
  else {
    # final_data_path = $data_path argument (chosen by the user
    $metadata_file = "${data_path}/metadata.mfs"
    $final_data_path = $data_path
  }

  file { $final_data_path:
    ensure => directory,
    owner  => $::lizardfs::user,
    group  => $::lizardfs::group,
    mode   => $::lizardfs::secure_dir_permission,
  }

  # metadata.mfs.empty is always stored in the default_data_path
  $metadata_file_empty = "${default_data_path}/metadata.mfs.empty"

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

  -> exec { "cp '${metadata_file_empty}' '${metadata_file}'":
    unless  => "test -f '${metadata_file}'",
    user    => $::lizardfs::user,
    require => File[$final_data_path],
  }

  if $manage_service {
    Exec["cp '${metadata_file_empty}' '${metadata_file}'"]

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
    Exec["cp '${metadata_file_empty}' '${metadata_file}'"]

    # will do nothing if we choose to not manage the service
    -> exec { 'mfsmaster reload':
      command     => 'true', # lint:ignore:quoted_booleans
      refreshonly => true,
    }
  }

### To enable pacemaker you need to set the FQDNs of the nodes like: $pacemaker_quorum_members =>  [master.lfs, shadow.lfs],
### and the VIP for lfs master service like: options => { MASTER_HOST => "192.168.1.xxx", }
if $enable_pacemaker {
  if ! empty($pacemaker_quorum_members) {
    if is_ip_address($options[MASTER_HOST]) and $options[ADMIN_PASSWORD] {
      class { 'corosync':
        enable_secauth       => true,
        authkey              => "/var/lib/puppet/ssl/certs/ca.pem",
        bind_address         => "$ipaddress",
        multicast_address    => "239.1.1.2",
        manage_pcsd_service  => true,
        #debug               => true,
        set_votequorum       => true,
        #            pacemaker_quorum_members      => $pacemaker_quorum_members,
        votequorum_expected_votes => 2,
      }
      corosync::service { 'pacemaker':
        version => '0',
      }
      cs_property { 'stonith-enabled' :
        value   => 'false',
        cib     => 'puppet'
        }~> Cs_commit['puppet']
        cs_property { 'no-quorum-policy' :
          value   => 'ignore',
          cib     => 'puppet'
          }~> Cs_commit['puppet']
          cs_primitive { 'lizardfs-master':
            primitive_class => 'ocf',
            provided_by     => 'lizardfs',
            primitive_type  => 'metadataserver',
            parameters      => { 'master_cfg' => "${cfgdir}mfsmaster.cfg" },
            metadata        => { 'clone-node-max' => '1', 'master-max' => '1', 'master-node-max' => '1', 'notify' => 'true', 'target-role' => 'Master'},
            operations      => {
              'monitor' => { role => 'Master', 'interval' => '1s', 'timeout' => '30s' },
              'monitor' => { role => 'Slave', 'interval' => '2s', 'timeout' => '40s' },
              'start'   => { 'interval' => '0', 'timeout' => '1800s' },
              'stop'    => { 'interval' => '0', 'timeout' => '1800s' },
              'promote' => { 'interval' => '0', 'timeout' => '1800s' },
              'demote'  => { 'interval' => '0', 'timeout' => '1800s' },
            },
            promotable         => 'true',
            cib                => 'puppet'
            }~> Cs_commit['puppet']
            cs_primitive { 'Failover-IP':
              primitive_class => 'ocf',
              provided_by     => 'heartbeat',
              primitive_type  => 'IPaddr2',
              parameters      => { 'ip' => "${options[MASTER_HOST]}", 'cidr_netmask' => '24' },
              operations      => { 'monitor' => { 'interval' => '1s' }, },
              cib             => 'puppet'
              }~> Cs_commit['puppet']

              # cs_rsc_defaults { 'resource-stickiness' :
              #    value => '100',
              #    cib   => 'puppet'
              #  }~> Cs_commit['puppet']
              cs_colocation { 'ip_with_master':
                primitives => [
                  ['Failover-IP', 'ms_lizardfs-master:Master'],
                  ],
                  cib        => 'puppet'
                  }~> Cs_commit['puppet']

                  cs_order { 'master-after-ip':
                    first   => 'Failover-IP:start',
                    second  => 'ms_lizardfs-master:promote',
                    require => Cs_colocation['ip_with_master'],
                    cib     => 'puppet'
                    }~> Cs_commit['puppet']

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
                      }->
                      file { 'lizardfs.ocf':
                        path    => '/usr/lib/ocf/resource.d/lizardfs/metadataserver',
                        ensure  => file,
                        mode    => 755,
                        content => template("lizardfs/lizardfs.ocf"),
                        before  => Service['pacemaker'],
                      }
    }
    else {
      fail('You need to set the virtual IP and the admin password for the LizardFS Master. Example: lizardfs::master::options => {\'MASTER_HOST\' => \'192.168.1.xx\', ADMIN_PASSWORD => \'passwd\' }')
    }
  }
}
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
