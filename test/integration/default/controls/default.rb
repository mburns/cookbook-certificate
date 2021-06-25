control 'cerificate' do
  impact 1
  desc 'Valid cerificates are created'

  cert_path = if os.family == 'redhat'
                '/etc/pki/tls'
              else
                '/etc/ssl'
              end

  describe directory("#{cert_path}/private") do
    it { should exist }
    its('mode') { should cmp '0750' }
  end

  describe file("#{cert_path}/private/test.key") do
    it { should exist }
    its('mode') { should cmp '0640' }
    its('content') { should match /BEGIN RSA PRIVATE KEY/ }
  end

  describe directory("#{cert_path}/certs") do
    it { should exist }
    its('mode') { should cmp '0755' }
  end

  describe file("#{cert_path}/certs/test.pem") do
    it { should exist }
    its('mode') { should cmp '0644' }
    its('content') { should match /BEGIN CERTIFICATE/ }
  end

  describe command("openssl x509 -in #{cert_path}/certs/test.pem") do
    its('exit_status') { should eq 0 }
  end
end

# /etc/pki/tls || /etc/ssl
