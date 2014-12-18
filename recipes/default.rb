#
# Cookbook Name:: nedge-dev
# Recipe:: default
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

if 'ubuntu' == node['platform']
  execute 'update packages' do
    command 'apt-get update -y'
  end
end

include_recipe "build-essential::default"
include_recipe "git"
include_recipe "apt"
include_recipe "rsync"

user = ENV['USER']
home = Dir.home(user)

vimrc = "#{home}/.vimrc"
lint_tar = "#{home}/lint.tar"
ssh_dir = "#{home}/.ssh"
ssh_config = "#{ssh_dir}/config"
ssh_private_key = "#{ssh_dir}/git-identity"

nedge_repo_host = "repository.nexenta.com"
if node.has_key?('NEDGE_REPO_HOST')
	nedge_repo_host = node['NEDGE_REPO_HOST']
end

nedge_build_number = "0"
if node.has_key?('NEDGE_BUILD_NUMBER')
	nedge_build_number = node['NEDGE_BUILD_NUMBER']
end

if node.has_key?('NEDGE_BUILD_PROD') and node['NEDGE_BUILD_PROD']
    build_suffix = nedge_build_number
else
    build_suffix = 'debug/' + nedge_build_number
end

directory ssh_dir do
	owner user
	group user
	mode 0600
end

cookbook_file vimrc do
	owner user
	group user
	action :create_if_missing
	mode 0644
	source "dot-vimrc"
end

cookbook_file lint_tar do
	owner user
	group user
	action :create_if_missing
	mode 0644
	source "lint.tar"
end

execute "untar ~/lint" do
	cwd ::File.dirname(lint_tar)
	command <<-COMMAND
		tar xvf #{lint_tar}
		rm #{lint_tar}
	COMMAND
end

cookbook_file ssh_config do
	owner user
	group user
	action :create_if_missing
	mode 0600
	source "disable-host-check"
end

cookbook_file ssh_private_key do
	owner user
	group user
	action :create_if_missing
	source "chef-stash-private-key"
	mode "0600"
end

execute "git clone" do
	cwd "/opt"
	command "sudo git clone ssh://git@stash.nexenta.com:7999/ned/nedge.git"
	creates "/opt/nedge"
	not_if "test -d /opt/nedge"
end

execute "set buildnumber" do
    cwd "/opt/nedge"
    command <<-COMMAND
        echo 'export NEDGE_BUILD_NUMBER=#{nedge_build_number}' >> /opt/nedge/.local
    COMMAND
end

execute "disable debug" do
    cwd "/opt/nedge"
    command <<-COMMAND
        echo 'export NEDGE_NDEBUG=1' >> /opt/nedge/.local
    COMMAND
    only_if { node.has_key?('NEDGE_BUILD_PROD') and node['NEDGE_BUILD_PROD'] }
end

execute "make install" do
	cwd "/opt/nedge"
	command <<-COMMAND
		/bin/bash -c "(source env.sh && make install)"
	COMMAND
end

execute "make yum" do
	cwd "/opt/nedge"
	command <<-COMMAND
		/bin/bash -c "(source env.sh && make yum)"
		rsync -avr /var/tmp/nedge/repo/rhel7/ #{nedge_repo_host}::nedge-dev-rhel7/#{build_suffix}
	COMMAND
	only_if { platform?("redhat", "centos", "fedora") }
end

execute "make apt" do
	cwd "/opt/nedge"
	command <<-COMMAND
		/bin/bash -c "(source env.sh && make apt)"
		rsync -avr /var/tmp/nedge/repo/ubuntu14/ #{nedge_repo_host}::nedge-dev-ubuntu14/#{build_suffix}
	COMMAND
	only_if { platform?("ubuntu") }
end

execute "make tar" do
	cwd "/opt/nedge"
	command <<-COMMAND
		/bin/bash -c "(source env.sh && make tar)"
		rsync -avr /var/tmp/nedge/neadm-*.tar.gz #{nedge_repo_host}::nedge-dev-neadm/#{nedge_build_number}
	COMMAND
    only_if { node.has_key?('NEDGE_BUILD_PROD') and node['NEDGE_BUILD_PROD'] }
end
