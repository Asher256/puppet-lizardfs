# puppet-lizardfs

- Author: Asher256
- Github repository: https://github.com/Asher256/puppet-lizardfs

#### Table of Contents

1. [Overview](#overview)
2. [Github repository](#github-repository)
2. [Requirements](#requirements)
4. [Contribute](#contribute)

## Overview

The puppet-lizardfs module lets you use Puppet to install and configure
LizardFS.

LizardFS is an open source distributed file system, highly available, scalable
and ready to use.

You can configure with puppet-lizardfs:
- The LizardFS master (ready for High-availability with tools like keepalived)
- The LizardFS chunkserver
- The LizardFS metalogger
- The LizardFS client and mount points

Puppet dependencies (Puppet modules):
- stdlib

## Example

To configure the LizardFS master:
```
class {'lizardfs::master':
  ensure              => 'present',
  first_personality   => 'MASTER',
  exports             => ['*    /    ro'],
}
```

To configure the chunkserver:
```
class {'lizardfs::chunkserver':
  ensure => present,
}
```

Don't forget to add the host mfsmaster on all servers (chunkservers, shadows,
etc.):
```
host { 'mfsmaster':
  ip => 'x.x.x.x',
}
```

## Requirements

- Operating system: Debian Linux

(Please contribute to make your operating system supported!)

## Contribute

This Puppet module is an open project, and community contributions are
essential for keeping it great. I can't access the huge number of platforms and
myriad hardware, software, and deployment configurations that Puppet is
intended to serve. I encourage you to contribute. Send me your pull requests on
Github! 

