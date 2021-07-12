module Furikake
  module Resources
    module Ec2WithVol
      def report(format = nil)
        instance = get_resources
        contents = {
          title: 'EC2',
          resources: [
            {
               subtitle: '',
               header: ['Name', 'Instance ID', 'Instance Type',
                        'Availability Zone', 'Private IP Address',
                        'Public IP Address', 'State',
                        'Volume(device:volume_id:volume_size)',
                        'Security Group'],
               resource: instance.sort
            }
          ]
        }
        if $output_tag_keys and $output_tag_keys.length > 0
          contents[:resources][0][:header] << 'Tags'
        end
        Furikake::Formatter.shaping(format, contents)
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        params = {}
        params[:filters] = $filters
        instances = []
        loop do
          res = ec2.describe_instances(params)
          res.reservations.each do |r|
            r.instances.each do |i|
              instance = []
              instance << 'N/A' if i.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
              i.tags.each do |tag|
                instance << tag.value if tag.key == 'Name'
              end
              instance << i.instance_id
              instance << i.instance_type
              instance << i.placement.availability_zone
              instance << i.private_ip_address
              if i.public_ip_address.nil?
                instance << ' '
              else
                instance << i.public_ip_address
              end
              instance << i.state.name

              volume_ids = []
              i.block_device_mappings.each do |b|
                volume_ids << b.ebs.volume_id
              end
              volumes = []
              if volume_ids.length > 0
                params = {
                  volume_ids: volume_ids,
                }
                vol_res = ec2.describe_volumes(params)
                vol_res.volumes.each do |v|
                  volume = []
                  volume << v.attachments[0].device
                  volume << v.volume_id
                  volume << v.size
                  volumes << volume.join(':')
                end
              end
              instance << volumes.sort.join('<br>')

              security_groups = []
              i.security_groups.each do |sg|
                security_groups << sg.group_id
              end
              instance << security_groups.sort.join('<br>')

              if $output_tag_keys
                output_tags = []
                $output_tag_keys.each do |t|
                  i.tags.each do |tag|
                    output_tags << '"' + t + '":"' + tag.value + '"' if tag.key == t
                  end
                end
                instance << output_tags.sort.join('<br>')
              end

              instances << instance
            end
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end

        instances.sort
      end
      module_function :report, :get_resources
    end
  end
end
