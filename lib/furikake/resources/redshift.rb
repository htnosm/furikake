module Furikake
  module Resources
    module Redshift
      def report(format = nil)
        cluster = get_resources
        contents = {
          title: 'Redshift',
          resources: [
              {
                 subtitle: 'Clusters',
                 header: ['Cluster Identifier', 'Endpoint', 'Node Type', 'Status(AvailabilityStatus)',
                          'Number Of Nodes', 'JDBC URL', 'ODBC URL', 'Parameter Group', 'Security Group'],
                 resource: cluster
              }
          ]
        }
        if $output_tag_keys and $output_tag_keys.length > 0
          contents[:resources][0][:header] << 'Tags'
        end
        Furikake::Formatter.shaping(format, contents).chomp
      end

      def get_resources
        redshift = Aws::Redshift::Client.new

        cluster_infos = []
        redshift.describe_clusters.clusters.map(&:to_h).each do |c|
          cluster = []
          cluster << c[:cluster_identifier]
          endpoint = "#{c[:endpoint][:address]}:#{c[:endpoint][:port]}/#{c[:db_name]}"
          cluster << endpoint
          cluster << c[:node_type]
          cluster << "#{c[:cluster_status]}(#{c[:cluster_availability_status]})"
          cluster << c[:number_of_nodes]
          cluster << "`jdbc:redshift://#{endpoint}`"
          odbc_url = "`Driver={Amazon Redshift (x64)}; Server=#{c[:endpoint][:address]}; Database=#{c[:db_name]};UID=#{c[:master_username]}; PWD=insert_your_master_user_password_here; Port=#{c[:endpoint][:port]}`"
          cluster << odbc_url
          cluster << (c[:cluster_parameter_groups].map {|c| c[:parameter_group_name]}).join(',')

          security_groups = []
          if c[:cluster_security_groups].length > 0
            security_groups << (c[:cluster_security_groups].map {|c| c[:cluster_security_group_name]})
          end
          if c[:vpc_security_groups].length > 0
            security_groups << (c[:vpc_security_groups].map {|c| c[:vpc_security_group_id]})
          end
          cluster << security_groups.sort.join('<br>')

          if $output_tag_keys
            output_tags = []
            $output_tag_keys.each do |t|
              c[:tags].each do |tag|
                output_tags << '"' + t + '":"' + tag[:value] + '"' if tag[:key] == t
              end
            end
            cluster << output_tags.sort.join('<br>')
          end

          cluster_infos << cluster
        end

        cluster_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end
