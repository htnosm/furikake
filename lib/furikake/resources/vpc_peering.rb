module Furikake
  module Resources
    module VpcPeering
      def report
        resources = get_resources
        headers = ['Name', 'Peering Connection',
          'Requester VPC', 'Accepter VPC',
          'Requester CIDRs', 'Accepter CIDRs',
          'Requester Owner', 'Accepter Owner',
          'State']
        if $output_tag_keys and $output_tag_keys.length > 0
          headers << 'Tags'
        end
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### VPC Peering Connections

#{info}
EOS
        
        documents
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        peerings = []
        loop do
          res = ec2.describe_vpc_peering_connections()
          res.vpc_peering_connections.each do |p|
            peering = []            
            peering << 'N/A' if p.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
            p.tags.each do |tag|
              peering << tag.value if tag.key == 'Name'
            end
            peering << p.vpc_peering_connection_id
            peering << p.requester_vpc_info.vpc_id
            peering << p.accepter_vpc_info.vpc_id
            peering << p.requester_vpc_info.cidr_block
            peering << p.accepter_vpc_info.cidr_block
            peering << p.requester_vpc_info.owner_id
            peering << p.accepter_vpc_info.owner_id
            peering << p.status.code

            if $output_tag_keys
              output_tags = []
              $output_tag_keys.each do |t|
                p.tags.each do |tag|
                  output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
                end
              end
              peering << output_tags.sort.join('<br>')
            end

            peerings << peering
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end

        peerings.sort_by!{|x| [x[0].to_s, x[1].to_s]}
      end

      module_function :report, :get_resources
    end
  end
end
