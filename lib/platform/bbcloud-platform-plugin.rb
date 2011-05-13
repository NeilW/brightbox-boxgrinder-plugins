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
require 'boxgrinder-build/helpers/linux-helper'
require 'tempfile'

module BoxGrinder
  class BbcloudPlatformPlugin < BasePlugin
    def after_init
      register_deliverable(:disk => "#{deliverable_name}.gz")

      register_supported_os('fedora', ['13', '14', '15'])
      register_supported_os('centos', ['5'])
      register_supported_os('rhel', ['5', '6'])
      register_supported_os('sl', ['5', '6'])
    end

    def deliverable_name
      "#{@appliance_config.name}-#{@appliance_config.version}.#{@appliance_config.release}-#{@appliance_config.os.name}-#{@appliance_config.os.version}"
    end

    def execute
      @linux_helper = LinuxHelper.new(:log => @log)

      @log.info "Converting #{@appliance_config.name} appliance image to use Brightbox metadata services"

      @image_helper.convert_disk(@previous_deliverables.disk, 'raw', uncompressed_disk_name)

      @image_helper.customize([uncompressed_disk_name], :automount => true) do |guestfs, guestfs_helper|
        upload_rc_local(guestfs)
        add_default_user(guestfs)
	disable_root_password(guestfs)
        change_configuration(guestfs_helper)
        execute_post(guestfs_helper)
      end

      @log.info "Image converted to Brightbox format, compressing"
      @exec_helper.execute("gzip --fast -v #{uncompressed_disk_name}")
      @log.info "Disk compressed"
    end

    def uncompressed_disk_name
      @uncompressed_name ||= File.join(File.dirname(@deliverables.disk), File.basename(@deliverables.disk, '.gz'))
    end


    def execute_post(guestfs_helper)
      if @appliance_config.post['bbcloud']
        @appliance_config.post['bbcloud'].each do |cmd|
          guestfs_helper.sh(cmd, :arch => @appliance_config.hardware.arch)
        end
        @log.debug "Post commands from appliance definition file executed."
      else
        @log.debug "No commands specified, skipping."
      end
    end

    def default_user
      "brightbox"
    end

    def add_default_user(guestfs)
      @log.debug "Adding #{default_user} user..."
      guestfs.sh("useradd #{default_user}")
      guestfs.sh("echo -e '#{default_user}\tALL=(ALL)\tNOPASSWD: ALL' >> /etc/sudoers")
      @log.debug "User #{default_user} added."
    end

    def disable_root_password(guestfs)
      @log.debug "Disabling root password"
      guestfs.sh("usermod -L root")
      @log.debug "root password disabled - use sudo from #{default_user} account"
    end

    def upload_rc_local(guestfs)
      @log.debug "Uploading '/etc/rc.local' file..."
      rc_local = Tempfile.new('rc_local')
      rc_local << guestfs.read_file("/etc/rc.local") + File.read("#{File.dirname(__FILE__)}/src/rc_local")
      rc_local.flush

      guestfs.upload(rc_local.path, "/etc/rc.local")

      rc_local.close
      @log.debug "'/etc/rc.local' file uploaded."
    end

    def change_configuration(guestfs_helper)
      guestfs_helper.augeas do
        # disable password authentication
        set("/etc/ssh/sshd_config", "PasswordAuthentication", "no")

        # disable root login
        set("/etc/ssh/sshd_config", "PermitRootLogin", "no")
      end
    end
  end
end

plugin :class => BoxGrinder::BbcloudPlatformPlugin, :type => :platform, :name => :bbcloud, :full_name => "Brightbox Cloud"
