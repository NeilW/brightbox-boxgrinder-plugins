#  Brightbox - Boxgrinder Delivery Plugin for Brightbox Cloud
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

module BoxGrinder
  class BbcloudDeliveryPlugin < BasePlugin
   
    def execute( type = :bbcloud )
      @log.info "Adding '#{@appliance_config.name}' appliance to Brightbox Cloud..." 
      @log.info "Using Brightbox account id #{account}"
      upload
      register_image
    end

    def upload
      @log.info "Uploading to #{ftp_hash['library_ftp_host']} with secure FTP"
      if system curl_command
        @log.info "Appliance #{@appliance_config.name} uploaded."
      else
        raise "An error occurred while uploading files."
      end
    end

    def register_image
      @log.info "Registering appliance as #{image_id} under account #{account} with the name '#{appliance_name}'"
      @log.info "Run 'brightbox-images show #{image_id}' to check registration progress"
    end

    def image_id
      @image_id ||=
	if @exec_helper.execute(register_image_command) =~ /img-\w{5}/
	  Regexp.last_match[0]
	else
	  raise "Failed to obtain an image id from the registration command"
	end
    end

    def account
      @account ||= @exec_helper.execute("brightbox-accounts -s list").split[0]
    rescue RuntimeError => e
      @log.error e.message
      raise PluginValidationError, "Make sure the that brightbox cloud API tools are installed. Use 'brightbox-config client_add' to add the api client details for your account." 
    end

    def disk_image
      @previous_deliverables[:disk]
    end

    def ftp_hash
      @ftp_hash ||= Hash[*(@exec_helper.execute("brightbox-accounts -s reset_ftp_password #{account} 2>/dev/null").split)]
    end

    def target_name
      File.basename(disk_image)
    end

    def curl_command
      "curl -# -u #{ftp_hash['library_ftp_user']}:#{ftp_hash['library_ftp_password']} --ftp-ssl-control -T #{disk_image} ftp://#{ftp_hash['library_ftp_host']}/incoming/#{target_name}"
    end
    
    def appliance_name
      "#{@appliance_config.name}-#{@appliance_config.version}.#{@appliance_config.release}-#{@appliance_config.os.name}-#{@appliance_config.os.version}-#{current_platform}"
    end

    def register_image_command
      "brightbox-images register -a #{@appliance_config.hardware.arch} -s #{target_name} -n '#{appliance_name}' -d '#{@appliance_config.summary}'"
    end

  end
end

plugin :class => BoxGrinder::BbcloudDeliveryPlugin, :type => :delivery, :name => :bbcloud, :full_name => "Brightbox Cloud Image Registration Service"
