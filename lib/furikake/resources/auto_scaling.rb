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
        if $output_tag_keys and $output_tag_keys.length > 0
          headers << 'Tags'
        end
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
            if ! a.launch_configuration_name.nil?
              asg << a.launch_configuration_name
            elsif ! a.launch_template.nil?
              launch_template = []
              launch_template << a.launch_template.launch_template_name
              launch_template << a.launch_template.version
              asg << launch_template.join(":")
            elsif ! a.mixed_instances_policy.nil?
              launch_template = []
              launch_template << a.mixed_instances_policy.launch_template.launch_template_specification.launch_template_name
              launch_template << a.mixed_instances_policy.launch_template.launch_template_specification.version
              asg << launch_template.join(":")
            else
              asg << "unknown"
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

            if $output_tag_keys
              output_tags = []
              $output_tag_keys.each do |t|
                a.tags.each do |tag|
                  output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
                end
              end
              asg << output_tags.sort.join('<br>')
            end

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
