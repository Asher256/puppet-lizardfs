#
# == Define: lizardfs::cgi
#
# 'lizardfs::cgi': install and configure LizardFS CGI (web interface).
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
# class {'lizardfs::cgi':
#   ensure  => 'present',
# }
#
# === Parameters
#
# [*ensure*]    This parameter is passed to the LizardFS CGI package.
#               You can specify: present, absent or the package version
#

class lizardfs::cgi(
  $ensure = 'present',
  $manage_service = true,
  $bind_host = 'localhost',
  $bind_port = 9425,
  $user = 'nobody',
  $group= 'nogroup',
)
{
  validate_string($ensure)

  include lizardfs

  File {
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    require => Class['lizardfs']
  }

  if $::operatingsystem in ['Debian', 'Ubuntu'] {
    $service_name = 'lizardfs-cgiserv'
    $cgi_package = 'lizardfs-cgi'
    $cgi_serv_package = 'lizardfs-cgiserv'
    package { [$cgi_package, $cgi_serv_package]:
      ensure  => present,
    }

    Class['lizardfs']
    -> Package[$cgi_package]
    -> Class['lizardfs::install']
  }
  else {
    fail()
  }

  if $manage_service {
    file { '/etc/default/lizardfs-cgiserv' :
      content => template('lizardfs/etc/default/lizardfs-cgiserv'),
      notify  => $service_name,
    }

    service { $service_name:
      ensure    => running,
      enable    => true,
      require   => [Package[$cgi_package],
                    Package[$cgi_serv_package],
                    File['/etc/default/lizardfs-cgiserv']],
    }
  }
  else {
    file { '/etc/default/lizardfs-cgiserv' :
      content => template('lizardfs/etc/default/lizardfs-cgiserv'),
    }
  }

  include lizardfs::install
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
