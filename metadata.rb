name 'certificate'
maintainer 'Eric G. Wolfe'
maintainer_email 'eric.wolfe@gmail.com'
license 'Apache 2.0'
description 'Installs/Configures certificates, private keys, CA root bundles from encrypted data bags.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version IO.read(File.join(File.dirname(__FILE__), 'VERSION')) rescue '0.0.1'
chef_version '>= 12.8'
%w( amazon centos debian fedora redhat oracle scientific ubuntu smartos ).each do |os|
  supports os
end

depends 'chef-vault'

gem 'vault'