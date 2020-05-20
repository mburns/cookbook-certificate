#
# Cookbook:: certificate
# Provider:: manage
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

def whyrun_supported?
  true
end

use_inline_resources if defined?(use_inline_resources)

action :create do
  case new_resource.data_bag_type
  when 'encrypted'
    ssl_secret = Chef::EncryptedDataBagItem.load_secret(new_resource.data_bag_secret)
    ssl_item =
      begin
        Chef::EncryptedDataBagItem.load(new_resource.data_bag, new_resource.search_id, ssl_secret)
      rescue => e
        raise e unless new_resource.ignore_missing
        nil
      end
  when 'unencrypted'
    ssl_item =
      begin
        Chef::DataBagItem.load(new_resource.data_bag, new_resource.search_id)
      rescue => e
        raise e unless new_resource.ignore_missing
        nil
      end
  when 'vault'
    # vault doesn't work in chef-solo
    Chef::Application.fatal!('Vault type encryption not supported with chef-solo') if Chef::Config['solo']
    ssl_item =
      begin
        chef_gem 'chef-vault'
        require 'chef-vault'
        ChefVault::Item.load(new_resource.data_bag, new_resource.search_id)
      rescue ChefVault::Exceptions::KeysNotFound, ChefVault::Exceptions::SecretDecryption
        begin
          Chef::DataBagItem.load(new_resource.data_bag, new_resource.search_id)
        rescue => e
          raise e unless new_resource.ignore_missing
          nil
        end
      end
  when 'none' # just take arbitrary plain text from resource
    ssl_item = {
      'cert' => new_resource.plaintext_cert,
      'key' => new_resource.plaintext_key,
      'chain' => new_resource.plaintext_chain,
      }
  else
    fail "Unsupported data bag type #{new_resource.data_bag_type}"
  end

  next if ssl_item.nil?

  if new_resource.combined_file
    cert_file_resource ::File.join(new_resource.cert_path, new_resource.cert_file),
                       "#{ssl_item['cert']}\n#{ssl_item['chain']}\n#{ssl_item['key']}",
                       :private => true
    next
  end

  if new_resource.create_subfolders
    cert_directory_resource 'certs'
    cert_directory_resource 'private', :private => true
  end

  if new_resource.nginx_cert
    cert_file_resource new_resource.certificate, "#{ssl_item['cert']}\n#{ssl_item['chain']}"
  else
    cert_file_resource new_resource.certificate, ssl_item['cert']
    cert_file_resource new_resource.chain, ssl_item['chain']
  end
  cert_file_resource new_resource.key, ssl_item['key'], :private => true
end

def cert_directory_resource(dir, options = {})
  r = directory ::File.join(new_resource.cert_path, dir) do
    owner new_resource.owner
    group new_resource.group
    mode(options[:private] ? 00700 : 00755)
    recursive true
  end
  new_resource.updated_by_last_action(true) if r.updated_by_last_action?
end

def cert_file_resource(path, content, options = {})
  r = template path do
    source 'blank.erb'
    cookbook new_resource.cookbook
    owner new_resource.owner
    group new_resource.group
    mode(options[:private] ? 00600 : 00644)
    variables :file_content => content
    only_if { content }
    sensitive new_resource.sensitive if respond_to?(:sensitive)
  end
  new_resource.updated_by_last_action(true) if r.updated_by_last_action?
end
