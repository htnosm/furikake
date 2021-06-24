module Furikake
  module Resources
    module Rds
      def report(format = nil)
        instance, cluster = get_resources
        contents = {
          title: 'RDS',
          resources: [
              {
                 subtitle: 'DB Instances',
                 header: ['DB Cluster Name', 'DB Instance Name',
                          'DB Instance Class', 'DB Engine', 'DB Endpoint',
                          'DB Instance Parameter Group', 'Security Group'],
                 resource: instance
              },
              {
                 subtitle: 'DB Clusters',
                 header: ['DB Cluster Name', 'Cluster Endpoint',
                          'Cluster Reader Endpoint', 'DB Cluster Parameter Group', 'Cluster Members'],
                 resource: cluster
              }
          ]
        }
        Furikake::Formatter.shaping(format, contents).chomp
      end

      def get_resources
        rds = Aws::RDS::Client.new

        rds_infos = []
        rds.describe_db_instances.db_instances.map(&:to_h).each do |i|
          instance = []
          instance << (!i[:db_cluster_identifier].nil? ? i[:db_cluster_identifier] : 'N/A')
          instance << i[:db_instance_identifier]
          instance << i[:db_instance_class]
          instance << i[:engine]
          instance << i[:endpoint][:address]
          instance << (i[:db_parameter_groups].map {|i| i[:db_parameter_group_name]}).join(',')

          security_groups = []
          if i[:db_security_groups].length > 0
            security_groups << (i[:db_security_groups].map {|i| i[:db_security_group_name]})
          end
          if i[:vpc_security_groups].length > 0
            security_groups << (i[:vpc_security_groups].map {|i| i[:vpc_security_group_id]})
          end
          instance << security_groups.sort.join('<br>')

          rds_infos << instance
        end

        cluster_infos = []
        rds.describe_db_clusters.db_clusters.map(&:to_h).each do |c|
          cluster = []
          cluster << c[:db_cluster_identifier]
          cluster << c[:endpoint]
          cluster << c[:reader_endpoint]
          cluster << c[:db_cluster_parameter_group]
          cluster << (c[:db_cluster_members].map {|m| m[:is_cluster_writer] ? m[:db_instance_identifier] + '(W)' : m[:db_instance_identifier] + '(R)'}).join(', ')
          cluster_infos << cluster
        end

        return rds_infos.sort, cluster_infos.sort
      end

      module_function :report, :get_resources
    end
  end
end
