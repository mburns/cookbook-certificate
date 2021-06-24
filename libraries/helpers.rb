module Certificate
  module Cookbook
    module Helpers
      def default_cert_path
        if platform_family?('rhel', 'fedora')
          '/etc/pki/tls'
        else
          '/etc/ssl'
        end
      end
    end
  end
end
