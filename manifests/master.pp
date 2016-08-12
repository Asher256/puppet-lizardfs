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
#
# URL: https://github.com/Asher256/puppet-lizardfs
#
# === Examples
#
# class {'lizardfs::master':
#   ensure              => 'present',
#   first_personality   => 'MASTER',
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

  Package {
    require => Class['lizardfs']
  }

  Exec {
    user => 'root',
    path => '/bin:/sbin:/usr/bin:/usr/sbin',
    require => [Class['lizardfs'],
                Package[$lizardfs::master_package]]
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => [Class['lizardfs'],
                Package[$lizardfs::master_package]]
  }

  # Packages
  package { $lizardfs::master_package:
    ensure  => present,
  }

  package { $lizardfs::adm_package:
    ensure => present,
  }

  # $cfgdir is set because some templates use it (like the script generate-mfsmaster.cfg)
  $cfgdir = $lizardfs::cfgdir
  $script_generate_mfsmaster = "${lizardfs::cfgdir}generate-mfsmaster.cfg"

  # /etc/lizardfs/mfsmaster.cfg is generated with $script_generate_mfsmaster
  # $script_generate_mfsmaster will do this:
  #   1. cat $mfsmaster_header > /etc/lizardfs/mfsmaster.cfg
  #   2. echo "PERSONALITY=$(cat $mfsmaster_personality)"
  $mfsmaster_header = "${lizardfs::cfgdir}.mfsmaster.header.cfg"
  $mfsmaster_personality = "${lizardfs::cfgdir}.mfsmaster_personality"

  exec { $script_generate_mfsmaster:
    refreshonly => true,
    subscribe   => File[$mfsmaster_header],
    require     => File[$script_generate_mfsmaster],
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
  }

  -> file { "${lizardfs::cfgdir}mfsgoals.cfg":
    content => template('lizardfs/etc/lizardfs/mfsgoals.cfg.erb'),
  }

  -> file { "${lizardfs::cfgdir}mfstopology.cfg":
    content => template('lizardfs/etc/lizardfs/mfstopology.cfg.erb'),
  }

  -> exec { 'cp /var/lib/lizardfs/metadata.mfs.empty /var/lib/lizardfs/metadata.mfs':
    unless => 'test -f /var/lib/lizardfs/metadata.mfs',
    user   => 'lizardfs',
  }

  if $manage_service {
    service { $lizardfs::master_service:
      ensure  => running,
      enable  => true,
      require => [Package[$master_package],
                  Exec['cp /var/lib/lizardfs/metadata.mfs.empty /var/lib/lizardfs/metadata.mfs']]
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
