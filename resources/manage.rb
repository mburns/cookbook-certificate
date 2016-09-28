#
# Cookbook:: certificate
# Resources:: manage
#
# Copyright 2012, Eric G. Wolfe
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def initialize(*args)
  super
  @action = :create
  @sensitive = true
end

actions :create

# :data_bag is the Data Bag to search.
# :data_bag_secret is the path to the file with the data bag secret
# :data_bag_type is the type of data bag (i.e. unenc, enc, vault)
# :search_id is the Data Bag object you wish to search.
attribute :data_bag, :kind_of => String, :default => 'certificates'
attribute :data_bag_secret, :kind_of => String, :default => Chef::Config['encrypted_data_bag_secret']
attribute :data_bag_type, :kind_of => String, :equal_to => %w(unencrypted encrypted vault), :default => 'encrypted'
attribute :search_id, :kind_of => String, :name_attribute => true
attribute :ignore_missing, :kind_of => [TrueClass, FalseClass], :default => false

# :nginx_cert is a PEM which combine host cert and CA trust chain for nginx.
# :combined_file is a PEM which combine certs and keys in one file, for things such as haproxy.
# :cert_file is the filename for the managed certificate.
# :key_file is the filename for the managed key.
# :chain_file is the filename for the managed CA chain.
# :cert_path is the top-level directory for certs/keys (certs and private sub-folders are where the files will be placed)
# :create_subfolders will automatically create certs and private sub-folders
case node['platform_family']
when 'rhel', 'fedora'
  attribute :cert_path, :kind_of => String, :default => '/etc/pki/tls'
when 'debian'
  attribute :cert_path, :kind_of => String, :default => '/etc/ssl'
when 'smartos'
  attribute :cert_path, :kind_of => String, :default => '/opt/local/etc/openssl'
else
  attribute :cert_path, :kind_of => String, :default => '/etc/ssl'
end
attribute :nginx_cert, :kind_of => [TrueClass, FalseClass], :default => false
attribute :combined_file, :kind_of => [TrueClass, FalseClass], :default => false
attribute :cert_file, :kind_of => String, :default => "#{node['fqdn']}.pem"
attribute :key_file, :kind_of => String, :default => "#{node['fqdn']}.key"
attribute :chain_file, :kind_of => String, :default => "#{node['hostname']}-bundle.crt"
attribute :create_subfolders, :kind_of => [TrueClass, FalseClass], :default => true

# The owner and group of the managed certificate and key
attribute :owner, :kind_of => String, :default => 'root'
attribute :group, :kind_of => String, :default => 'root'

# Cookbook to search for blank.erb template
attribute :cookbook, :kind_of => String, :default => 'certificate'

# Accesors for determining where files should be placed
def certificate
  bits = [cert_path, cert_file]
  bits.insert(1, 'certs') if create_subfolders
  ::File.join(bits)
end

def key
  bits = [cert_path, key_file]
  bits.insert(1, 'private') if create_subfolders
  ::File.join(bits)
end

def chain
  bits = [cert_path, chain_file]
  bits.insert(1, 'certs') if create_subfolders
  ::File.join(bits)
end
