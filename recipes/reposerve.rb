#
# Cookbook Name:: nedge-dev
# Recipe:: reposerve
#
# Copyright 2014, Nexenta
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#

include_recipe "rsync::server"
include_recipe "apache2"

wwwroot = "/var/www/html"
nedgedev = "#{wwwroot}/nedge-dev"

directory "#{nedgedev}/rhel7" do
	action :create
	owner user
	group user
	mode 0755
	recursive true
end

directory "#{nedgedev}/ubuntu14" do
	action :create
	owner user
	group user
	mode 0755
	recursive true
end

directory "#{nedgedev}/neadm" do
	action :create
	owner user
	group user
	mode 0755
	recursive true
end

apache_site "default" do
	enable true
end

rsync_serve 'nedge-dev-rhel7' do
	path "#{nedgedev}/rhel7"
	comment 'CentOS/RHEL 7.0 latest dev mirror'
	read_only false
	use_chroot true
	list true
	uid 'root'
	gid 'root'
	transfer_logging true
	log_file '/var/log/rsync-rhel7.log'
end

rsync_serve 'nedge-dev-ubuntu14' do
	path "#{nedgedev}/ubuntu14"
	comment 'Ubuntu 14.04 latest dev mirror'
	read_only false
	use_chroot true
	list true
	uid 'root'
	gid 'root'
	transfer_logging true
	log_file '/var/log/rsync-ubuntu14.log'
end

rsync_serve 'nedge-dev-neadm' do
	path "#{nedgedev}/neadm"
	comment 'NEADM latest dev mirror'
	read_only false
	use_chroot true
	list true
	uid 'root'
	gid 'root'
	transfer_logging true
	log_file '/var/log/rsync-neadm.log'
end
