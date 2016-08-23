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
# [*ensure*]
#   This parameter is passed to the LizardFS Metalogger package.
#   You can specify: present, absent or the package version.
#
# [*options*]
#   keys/values of the configuration file mfsmetalogger.cfg:
#   https://github.com/lizardfs/lizardfs/blob/metalogger/doc/mfsmetalogger.cfg.5.txt
#
# [*manage_service*]
#   True to tell Puppet to start or stop the lizardfs-metalogger
#   service automatically.
#
# [*data_path*]
#   The directory where the LizardFS Metalogger's data is stored. It is the equivalent
#   of DATA_PATH on 'mfsmetalogger.cfg'. By default, it is equal to /var/lib/lizardfs/
#   More informations about DATA_PATH can be found in this page:
#   https://github.com/lizardfs/lizardfs/blob/metalogger/doc/mfsmetalogger.cfg.5.txt
#

class lizardfs::metalogger(
  $ensure = 'present',
  $options = {},
  $manage_service = true,
  $data_path = '/var/lib/lizardfs',
)
{
  validate_string($ensure)
  validate_hash($options)
  validate_bool($manage_service)

  $options_keys = upcase(keys($options))
  if 'DATA_PATH' in $options_keys {
    fail('To modify DATA_PATH use the argument "lizardfs::data_path" instead of "lizardfs::metalogger::options[\'DATA_PATH\']".')
  }

  # Because the Debian package is different than the Debian package
  # from packages.lizardfs.org, we will unify the user with Puppet
  $metadata_dir = $data_path
  validate_re($metadata_dir, '[^/]$')  # / is forbidden in the end of $data_path
  validate_absolute_path($metadata_dir)

  include ::lizardfs
  $working_user = $::lizardfs::user
  $working_group = $::lizardfs::group

  Exec {
    user => 'root',
    path => $::lizardfs::path,
  }

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
  }

  if $::lizardfs::create_legacy {
    file { "${::lizardfs::legacy_cfgdir}mfsmetalogger.cfg":
      ensure  => 'link',
      target  => "${::lizardfs::cfgdir}mfsmetalogger.cfg",
      before  => File["${lizardfs::cfgdir}/mfsmetalogger.cfg"],
      require => Class['::lizardfs'],
    }
  }

  Class['::lizardfs']

  -> package { $::lizardfs::metalogger_package:
    ensure  => $ensure,
  }

  -> file { "${lizardfs::cfgdir}/mfsmetalogger.cfg":
    content => template('lizardfs/etc/lizardfs/mfsmetalogger.cfg.erb'),
    notify  => Exec['mfsmetalogger reload']
  }

  if $manage_service {
    if $::osfamily == 'Debian' {
      file { '/etc/default/lizardfs-metalogger':
        ensure  => present,
        content => "# MANAGED BY PUPPET\nLIZARDFSMETALOGGER_ENABLE=true\nDAEMON_OPTS=\"\"\n",
        before  => Service[$::lizardfs::metalogger_service],
      }
    }

    service { $::lizardfs::metalogger_service:
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
      command     => 'true', # lint:ignore:quoted_booleans
      refreshonly => true,
      require     => File["${::lizardfs::legacy_cfgdir}mfsmetalogger.cfg"],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
