#  Brightbox - Boxgrinder Platform Plugin for Brightbox Cloud
#  Copyright (c) 2011, Brightbox Systems
#  Author: Neil Wilson
#
# This is free software; you can redistribute it and/or modify it
# under the terms of the GNU Lesser General Public License as
# published by the Free Software Foundation; either version 3 of
# the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this software; if not, write to the Free
# Software Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA
# 02110-1301 USA, or see the FSF site: http://www.fsf.org.

require 'boxgrinder-build/plugins/base-plugin'
require 'tempfile'

module BoxGrinder
  class BbcloudPlatformPlugin < BasePlugin
    plugin :type => :platform, :name => :bbcloud, :full_name => "Brightbox Cloud"

    def after_init
      register_deliverable(:disk => "#{deliverable_name}.qcow2")
      set_default_config_value('username', default_user)
      @appliance_config.packages |= %w{cloud-init} if has_cloud_init?
    end

    def execute
      @log.info "Converting #{@appliance_config.name} appliance image to use Brightbox metadata services"

      @log.debug "Using qemu-img to convert the image to qcow2 format..."
      @image_helper.convert_disk(@previous_deliverables.disk, :qcow2, @deliverables.disk)
      @log.debug "Conversion done."

      @log.debug "Adding metadata customisations"
      @image_helper.customize([@deliverables.disk], :automount => true) do |guestfs, guestfs_helper|
        add_default_user(guestfs)
	disable_root_password(guestfs_helper)
	set_default_timezone(guestfs_helper)
        change_ssh_configuration(guestfs_helper)
	if has_cloud_init?
	  customise_cloud_init(guestfs_helper)
	else
	  update_rc_local(guestfs)
	end
        execute_post(guestfs_helper)
      end
      @log.debug "Added customisations"
    end

    def has_cloud_init?
      @appliance_config.os.name == 'fedora' and @appliance_config.os.version >= '16'
    end

    def customise_cloud_init(guestfs_helper)
      guestfs_helper.sh("sed -i 's/^user: ec2-user$/user: #{@plugin_config['username']}/' /etc/cloud/cloud.cfg")
    end

    def execute_post(guestfs_helper)
      if @appliance_config.post['bbcloud']
        @appliance_config.post['bbcloud'].each do |cmd|
          guestfs_helper.sh(cmd, :arch => @appliance_config.hardware.arch)
        end
        @log.debug "Post commands from appliance definition file executed."
      else
        @log.debug "No Post commands specified, skipping."
      end
    end

    def default_user
      "brightbox"
    end

    def deliverable_name
      "#{@appliance_config.name}-#{@appliance_config.version}.#{@appliance_config.release}-#{@appliance_config.os.name}-#{@appliance_config.os.version}"
    end

    def add_default_user(guestfs)
      @log.debug "Adding #{@plugin_config['username']} user..."
      unless guestfs.fgrep(@plugin_config['username'], "/etc/passwd").empty?
        @log.debug("#{@plugin_config['username']} already exists, skipping.")
        return
      end
      guestfs.sh("useradd #{@plugin_config['username']}")
      guestfs.sh("echo -e '#{@plugin_config['username']}\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers")
      @log.debug "User #{@plugin_config['username']} added."
    end

    def disable_root_password(guestfs_helper)
      @log.debug "Disabling root password"
      guestfs_helper.sh("usermod -L root")
      @log.info "root password disabled - use sudo from #{@plugin_config['username']} account"
    end

    def update_rc_local(guestfs)
      @log.debug "Updating '/etc/rc.d/rc.local' file..."
      rc_local = Tempfile.new('rc_local')

      if guestfs.exists("/etc/rc.d/rc.local") == 1
        # We're appending
        rc_local << guestfs.read_file("/etc/rc.d/rc.local")
      else
        # We're creating new file
        rc_local << "#!/bin/bash\n\n"
      end

      rc_local << File.read("#{File.dirname(__FILE__)}/src/rc_local")
      rc_local.flush

      guestfs.upload(rc_local.path, "/etc/rc.d/rc.local")

      rc_local.close
    end

    def change_ssh_configuration(guestfs_helper)
      guestfs_helper.augeas do
        # disable password authentication
        set("/etc/ssh/sshd_config", "PasswordAuthentication", "no")

        # disable root login
        set("/etc/ssh/sshd_config", "PermitRootLogin", "no")

	# Switch off GSS Authentication
        set("/etc/ssh/sshd_config", "GSSAPIAuthentication", "no")
      end
    end

    def set_default_timezone(guestfs_helper)
      guestfs_helper.augeas do
        set("/etc/sysconfig/clock", "UTC", "True")
        set("/etc/sysconfig/clock", "ZONE", "Etc/UTC")
      end
      guestfs_helper.guestfs.cp("/usr/share/zoneinfo/UTC", "/etc/localtime")
    end

  end
end

