module Furikake
  module Resources
    module VpcEndpoint
      def report
        resources = get_resources
        headers = ['ServiceName', 'Name', 'ID', 'Type', 'VPC ID', 'State']
        if $output_tag_keys and $output_tag_keys.length > 0
          headers << 'Tags'
        end
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### VPC Endpoint

#{info}
EOS
        
        documents
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        params = {}
        endpoints = []
        loop do
          res = ec2.describe_vpc_endpoints(params)
          res.vpc_endpoints.each do |e|
            endpoint = []
            endpoint << e.service_name
            endpoint << 'N/A' if e.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
            e.tags.each do |tag|
              endpoint << tag.value if tag.key == 'Name'
            end
            endpoint << e.vpc_endpoint_id
            endpoint << e.vpc_endpoint_type
            endpoint << e.vpc_id
            endpoint << e.state

            if $output_tag_keys
              output_tags = []
              $output_tag_keys.each do |t|
                e.tags.each do |tag|
                  output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
                end
              end
              endpoint << output_tags.sort.join('<br>')
            end

            endpoints << endpoint
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end

        endpoints.sort_by!{|x| [x[0].to_s, x[1].to_s]}
      end

      module_function :report, :get_resources
    end
  end
end
