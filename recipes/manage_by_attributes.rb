#
# Cookbook Name:: certificate
# Recipe::manage_by_attributes
#
# Copyright 2012, Eric G. Wolfe
#
# Recipe Information
# Author: Yukihiko Sawanoborii (HiganWorks LLC)
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

node['certificate'].each do |cert|
  cert.each_slice(2) do |id, opts|
    Chef::Log.debug "Create certs #{id} from attribute"
    certificate_manage id do
      action :create
      opts.each { |k, v| __send__(k, v) if self.respond_to?(k) } unless opts.nil?
    end
  end
end
