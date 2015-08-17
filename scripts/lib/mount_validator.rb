require 'sys/filesystem'

module MountValidator
  def self.validate_mount(path, label)
    path_mount = Sys::Filesystem.mount_point(path)
    script_mount = Sys::Filesystem.mount_point(__FILE__)
    fail(<<EOF
Index mount point error
This code (#{__FILE__})
and the #{label} (#{path})
share a mount point: #{path_mount}
If this is development, add --same-mount to ignore.
If this is production, you probably want to set up a large separate volume
for #{label}, and create a symlink. See the README.
EOF
        ) if path_mount == script_mount
  end
end
