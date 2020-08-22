module Furikake
  module Resources
    module Cloudfront
      def report
        resources = get_resources
        headers = ['Distribution ID', 'Domain Name', 'Comment', 'Origin ID', 'Alias', 'Status', 'State',
          'Web ACL', 'HTTP Version', 'IPv6']
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### CloudFront Distribution

#{info}
EOS
        
        documents
      end

      def get_resources
        cf = Aws::CloudFront::Client.new

        req = {}
        distributions = []
        loop do
          res = cf.list_distributions(req)
          distributions.push(*res.distribution_list.items)
          break if res.distribution_list.next_marker.nil?
          req[:marker] = res.distribution_list.next_marker
        end

        distribution_infos = []
        distributions.map(&:to_h).each do |d|
          distribution = []
          distribution << d[:id]
          distribution << d[:domain_name]
          distribution << d[:comment]

          origins = []
          d[:origins].each do |o|
            if o[0] == :items
              o[1].each do |i|
                origins << i[:id]
              end
            end
          end
          distribution << origins.join('<br>')

          aliases = []
          d[:aliases].each do |a|
            if a[0] == :items
              a[1].each do |i|
                aliases << i
              end
            end
          end
          distribution << aliases.join('<br>')

          distribution << d[:status]
          distribution << d[:enabled]
          distribution << d[:web_acl_id]
          distribution << d[:http_version]
          distribution << d[:is_ipv6_enabled]
          distribution_infos << distribution
        end
        distribution_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end
