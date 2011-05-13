#
# Copyright 2010 Red Hat, Inc.
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

require 'rubygems'

begin
  require 'rake/dsl'
rescue LoadError
end

require 'echoe'

Echoe.new("brightbox-boxgrinder-plugins") do |p|
  p.project = "Brightbox Cloud"
  p.author = "Neil Wilson"
  p.email = "hello@brightbox.co.uk"
  p.summary = "Brightbox Cloud support for Boxgrinder"
  p.url = "http://beta.brightbox.com"
  p.runtime_dependencies = ['bbcloud >=0.11.2']
end

