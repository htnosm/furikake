module Furikake
  module Resources
    module VpcSubnet
      def report
        resources = get_resources
        headers = ['Name', 'Subnet ID', 'State', 'VPC ID', 'IPv4 CIDR', 'Available IPv4 Addresses',
                   'Availability Zone', 'Availability Zone ID', 'Default Subnet', 'Auto-assign Public IPv4 Address',
                   'Auto-assign Customer-owned IPv4 Address', 'Customer-owned IPv4 Pool']
        if $output_tag_keys and $output_tag_keys.length > 0
          headers << 'Tags'
        end
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### subnet

#{info}
EOS
        
        documents
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        params = {}
        params[:filters] = $filters
        subnets = []
        res = ec2.describe_subnets(params)
        res.subnets.each do |s|
          subnet = []
          subnet << 'N/A' if s.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
          s.tags.each do |tag|
            subnet << tag.value if tag.key == 'Name'
          end
          subnet << s.subnet_id
          subnet << s.state
          subnet << s.vpc_id
          subnet << s.cidr_block
          subnet << s.available_ip_address_count
          subnet << s.availability_zone
          subnet << s.availability_zone_id
          subnet << s.default_for_az
          subnet << s.map_public_ip_on_launch
          subnet << s.map_customer_owned_ip_on_launch
          subnet << s.customer_owned_ipv_4_pool

          if $output_tag_keys
            output_tags = []
            $output_tag_keys.each do |t|
              s.tags.each do |tag|
                output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
              end
            end
            subnet << output_tags.sort.join('<br>')
          end

          subnets << subnet
        end
        subnets.sort
      end
      module_function :report, :get_resources
    end
  end
end
