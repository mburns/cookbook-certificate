name 'certificate'
maintainer 'Eric G. Wolfe'
maintainer_email 'eric.wolfe@gmail.com'
license 'Apache 2.0'
description 'Installs/Configures certificates, private keys, CA root bundles from encrypted data bags.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
source_url 'https://github.com/atomic-penguin/cookbook-certificate.git'
issues_url 'https://github.com/atomic-penguin/cookbook-certificate/issues'
begin
  version IO.read(File.join(File.dirname(__FILE__), 'VERSION'))
rescue
  '0.0.1'
end

depends 'chef-vault', '~> 2.0'

supports amazon # <- Not tested
supports centos, '>= 5.11' # Tested
supports debian, '>= 7.8' # <- Assumed to work
supports fedora, '>= 22' # Tested
supports oracle # <- Not tested
supports redhat, '>= 5.11' # <- Assumed to work
supports scientific, '>= 5' # <- Assummed to work
supports smartos # <- Not tested
supports ubuntu, '>= 10.04' # Tested
