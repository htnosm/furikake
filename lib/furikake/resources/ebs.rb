module Furikake
  module Resources
    module Ebs
      def report(format = nil)
        volumes = get_resources
        contents = {
          title: 'EBS',
          resources: [
            {
               subtitle: '',
               header: ['Name', 'Volume ID', 'Size(GiB)', 'Volume Type', 'IOPS',
                        'Availability Zone', 'State',
                        'Attachment information'],
               resource: volumes.sort
            }
          ]
        }
        Furikake::Formatter.shaping(format, contents)
      end

      def get_resources
        ec2 = Aws::EC2::Client.new
        params = {}
        volumes = []
        loop do
          res = ec2.describe_volumes(params)
          res.volumes.each do |v|
            volume = []
            volume << 'N/A' if v.tags.map(&:to_h).all? { |h| h[:key] != 'Name' }
            v.tags.each do |tag|
              volume << tag.value if tag.key == 'Name'
            end
            volume << v.volume_id
            volume << v.size
            volume << v.volume_type
            volume << v.iops
            volume << v.availability_zone
            volume << v.state

            attachments = []
            v.attachments.each do |a|
              attachment = []
              attachment << a.instance_id
              attachment << a.device
              attachment << a.state
              attachments << attachment.join(':')
            end
            volume << attachments.join('<br>')

            volumes << volume.sort
          end
          break if res.next_token.nil?
          params[:next_token] = res.next_token
        end

        volumes.sort
      end
      module_function :report, :get_resources
    end
  end
end
