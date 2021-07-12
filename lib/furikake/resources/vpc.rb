module Furikake
  module Resources
    module Vpc
      def report
        resources = get_resources
        headers = ['Name', 'ID', 'CIDR', 'State']
        if $output_tag_keys and $output_tag_keys.length > 0
          headers << 'Tags'
        end
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### VPC

#{info}
EOS
        
        documents
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        vpcs = []
        ec2.describe_vpcs.vpcs.each do |v|
          vpc = []
          vpc << 'N/A' if v.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
          v.tags.each do |tag|
            vpc << tag.value if tag.key == 'Name'
          end
          vpc << v.vpc_id
          vpc << v.cidr_block
          vpc << v.state

          if $output_tag_keys
            output_tags = []
            $output_tag_keys.each do |t|
              v.tags.each do |tag|
                output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
              end
            end
            vpc << output_tags.sort.join('<br>')
          end

          vpcs << vpc
        end
        vpcs.sort
      end
      module_function :report, :get_resources
    end
  end
end
