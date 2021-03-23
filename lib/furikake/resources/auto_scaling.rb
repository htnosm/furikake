module Furikake
  module Resources
    module AutoScaling
      def report
        resources = get_resources
        headers = [
          'Name',
          'LaunchTemplate/Configuration',
          'Min',
          'Max',
          'LoadBalancers/TargetGroups',
          'HealthCheckType'
        ]
        if resources.empty?
          info = 'N/A'
        else
          info = MarkdownTables.make_table(headers, resources, is_rows: true, align: 'l')
        end
        documents = <<"EOS"
### AutoScaling Group

#{info}
EOS
        
        documents

      end

      def get_resources
        autoscaling = Aws::AutoScaling::Client.new
        params = {}
        asgs = []
        loop do
          res = autoscaling.describe_auto_scaling_groups(params)
          res.auto_scaling_groups.each do |a|
            asg = []
            asg << a.auto_scaling_group_name
            if a.launch_configuration_name.nil?
              launch_template = []
              if a.launch_template.nil?
                asg << ''
              else
                launch_template << a.launch_template.launch_template_name
                launch_template << a.launch_template.version
                asg << launch_template.join(":")
              end
            else
              asg << a.launch_configuration_name
            end
            asg << a.min_size
            asg << a.max_size

            load_balancers = []
            if a.load_balancer_names.length > 0
              load_balancers = a.load_balancer_names
            end
            if a.target_group_arns.length > 0
              a.target_group_arns.each do |t|
                load_balancers << t.gsub(/.*:targetgroup\//, '')
              end
            end
            asg << load_balancers.sort.join('<br>')

            asg << a.health_check_type
            asgs << asg
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end
        asgs.sort
      end
      module_function :report, :get_resources
    end
  end
end
