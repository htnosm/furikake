module Furikake
  module Resources
    module RouteTable
      def report
        resources = get_resources
        headers = ['VPC ID', 'Name', 'Route Table ID', 'Subnet Associations', 'Routes(Destination/Target/Status)']
        if $output_tag_keys and $output_tag_keys.length > 0
          headers << 'Tags'
        end
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### Route Table

#{info}
EOS
        
        documents
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        route_tables = []
        res = ec2.describe_route_tables
        res.route_tables.each do |r|
          route_table = []
          route_table << r.vpc_id
          route_table << 'N/A' if r.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
          r.tags.each do |tag|
            route_table << tag.value if tag.key == 'Name'
          end
          route_table << r.route_table_id

          associations = []
          r.associations.each do |a|
            associations << a.subnet_id
          end
          route_table << associations.join('<br>')

          routes = []
          r.routes.each do |route|
            row = []
            # destination
            row << route.destination_cidr_block if not route.destination_cidr_block.nil?
            row << route.destination_ipv_6_cidr_block if not route.destination_ipv_6_cidr_block.nil?
            row << route.destination_prefix_list_id if not route.destination_prefix_list_id.nil?
            # target
            row << route.egress_only_internet_gateway_id if not route.egress_only_internet_gateway_id.nil?
            row << route.gateway_id if not route.gateway_id.nil?
            row << route.nat_gateway_id if not route.nat_gateway_id.nil?
            row << route.transit_gateway_id if not route.transit_gateway_id.nil?
            row << route.carrier_gateway_id if not route.carrier_gateway_id.nil?
            row << route.vpc_peering_connection_id if not route.vpc_peering_connection_id.nil?
            row << route.instance_id if not route.instance_id.nil?
            row << route.network_interface_id if not route.network_interface_id.nil?
            # state
            row << route.state
            routes << row.join(' / ')
          end
          route_table << routes.join('<br>')

          if $output_tag_keys
            output_tags = []
            $output_tag_keys.each do |t|
              r.tags.each do |tag|
                output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
              end
            end
            route_table << output_tags.sort.join('<br>')
          end

          route_tables << route_table
        end
        route_tables.sort
      end
      module_function :report, :get_resources
    end
  end
end
