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
                        'Volume(device:volume_id:volume_size)'],
               resource: instance.sort
            }
          ]
        }
        Furikake::Formatter.shaping(format, contents)
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        params = {}
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
