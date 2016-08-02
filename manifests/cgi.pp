#
# == Define: lizardfs::cgi
#
# 'lizardfs::cgi': install and configure LizardFS CGI Server (web interface).
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
# class {'lizardfs::cgi':
#   ensure => 'present',
# }
#
# === Parameters
#
# [*ensure*] This parameter is passed to the LizardFS CGI package.
#            You can specify: present, absent or the package version.
#
# [*bind_host*] local address to listen on
#
# [*bind_port*] port to listen on
#
# [*user*] user to run the daemon as
#
# [*group*] group to run the daemon as
#
# [*manage_service*] ask Puppet to start LizardFS CGI Server automatically
#

class lizardfs::cgi(
  $ensure = 'present',
  $bind_host = 'localhost',
  $bind_port = 9425,
  $user = 'nobody',
  $group= 'nogroup',
  $manage_service = true,
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

  Exec {
    require => Class['lizardfs']
  }

  Package {
    require => Class['lizardfs']
  }

  if $::operatingsystem in ['Debian', 'Ubuntu'] {
    $service_name = 'lizardfs-cgiserv'
    $cgi_package = 'lizardfs-cgi'
    $cgi_serv_package = 'lizardfs-cgiserv'
    package { [$cgi_package, $cgi_serv_package]:
      ensure  => present,
    }
  }
  else {
    fail()
  }

  file { '/etc/default/lizardfs-cgiserv' :
    content => template('lizardfs/etc/default/lizardfs-cgiserv'),
  }

  if $manage_service {
    service { $service_name:
      ensure    => running,
      enable    => true,
      subscribe => File['/etc/default/lizardfs-cgiserv'],
      require   => [Package[$cgi_package],
                    Package[$cgi_serv_package],
                    File['/etc/default/lizardfs-cgiserv']],
    }
  }
}

# vim:et:sw=2:ts=2:sts=2:tw=0:fenc=utf-8
