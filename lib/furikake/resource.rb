module Furikake
  class Resource
    def self.generate(cli, resources)
      documents = ''
      load_resource_type(cli, resources).each do |type|
        if type.include?('addon')
          $LOAD_PATH.push(Dir.pwd + '/addons')
          require "#{type}"
          type_name = type.split('-')[-1]
          eval "documents.concat(Furikake::Resources::Addons::#{type_name.camelize}.report)"
          logger.info("リソースタイプ: #{type_name} の情報を取得しました.")
          documents.concat("\n\n")
        else
          begin
            require "furikake/resources/#{type}"
            eval "documents.concat(Furikake::Resources::#{type.camelize}.report)"
            logger.info("リソースタイプ: #{type} の情報を取得しました.")
            documents.concat("\n\n")
          rescue LoadError
            logger.warn("リソースタイプ: #{type} を読み込めませんでした.")
          rescue => e
            logger.warn("リソースタイプ: #{type} の情報を取得出来ませんでした.")
            logger.warn(e)
          end
        end
      end
      documents
    end

    def self.load_resource_type(cli, resources)
      type = []
      config_defined_resources = cli ? load_config_resource_type : resources['aws'].sort
      default_resources = load_default_resource_type
      if default_resources == config_defined_resources
        type.push(default_resources)
      else
        type.push(config_defined_resources)
      end
      type.push(load_addons_resource_type)
      type.flatten
    end

    def self.load_default_resource_type
      default_resource_type = []
      Dir.glob(File.dirname(__FILE__) + '/resources/*').each do |r|
        default_resource_type << File.basename(r, '.rb') unless r.include?('stub')
      end
      default_resource_type.sort
    end

    def self.load_addons_resource_type
      addons_resource_type = []
      Dir.glob(Dir.pwd + '/addons/furikake-resource-addon-*').each do |r|
        addons_resource_type << File.basename(r, '.rb')
      end
      addons_resource_type.sort
    end

    def self.load_config_resource_type(path = nil)
      path = '.furikake.yml' if path.nil?
      begin
        config = YAML.load_file(path)
        resources = config['resources']['aws'].sort
        if config.has_key?('options')
          options = config['options']
          # keep_config_order
          if options.has_key?('keep_config_order') and options['keep_config_order']
            resources = config['resources']['aws']
          end
          # filters
          if options.has_key?('filters')
            $filters = options['filters']
          end
          # output_tag_keys
          if options.has_key?('output_tag_keys')
            $output_tag_keys = options['output_tag_keys']
          end
        end
        resources
      rescue Errno::ENOENT
        logger.error('.furikake.yml が存在していません.')
        exit 1
      rescue => ex
        logger.error('.furikake.yml の読み込みに失敗しました. ' + ex.message)
        exit 1
      end
    end

    def self.logger
      $stdout.sync = true
      Logger.new($stdout)
    end
  end
end
