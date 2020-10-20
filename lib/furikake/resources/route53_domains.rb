# encoding: utf-8

module Furikake
  module Resources
    module Route53Domains
      def report
        resources = get_resources
        headers = [
          'Domain Name',
          'Expiration date',
          'Auto renew',
          'Transfer lock',
          'Privacy Protection(Registrant:Administrative:Technical)'
        ]
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### Route53 Domains

#{info}
EOS

        documents
      end

      def get_resources
        route53_domains = Aws::Route53Domains::Client.new(region: 'us-east-1')

        params = {}
        domains = []
        loop do
          res = route53_domains.list_domains(params)
          res.domains.each do |d|
            domain = []
            domain << d[:domain_name]
            domain << d[:expiry]
            domain << d[:auto_renew]
            domain << d[:transfer_lock]

            detail = route53_domains.get_domain_detail({domain_name: d[:domain_name]})
            privacy_protection = "#{detail[:registrant_privacy]}:#{detail[:admin_privacy]}:#{detail[:tech_privacy]}"
            domain << privacy_protection
            domains << domain
          end
          break if res.next_page_marker.nil?
          params[:marker] = res.next_page_marker
        end
        domains.sort
      end

      module_function :report, :get_resources
    end
  end
end
