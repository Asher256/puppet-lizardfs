#!/usr/bin/env ruby
#
# Author: Asher256 <asher256@gameloft.com>
# License: Apache 2.0
#

require 'facter'

Facter.add('lizardfs_personality') do
  begin
    content = File.open('/etc/lizardfs/.mfsmaster_personality', 'r') {|fd| fd.readline.chomp}
  rescue
    content = nil
  end

  if content != nil
    if ['MASTER', 'SHADOW'].include? content
      setcode { content }
    end
  end
end

# vim:ai:et:sw=2:ts=2:sts=2:tw=78:fenc=utf-8
