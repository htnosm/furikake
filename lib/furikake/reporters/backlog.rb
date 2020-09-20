require 'backlog_kit'

module Furikake
  module Reporters
    class Backlog
      def initialize(params)
        $stdout.sync = true
        @logger = Logger.new($stdout)
        @client ||= BacklogKit::Client.new(
          space_id: params['space_id'],
          api_key: params['api_key'],
          top_level_domain: params['top_level_domain']
        )
        @wiki_id = params['wiki_id']
        @wiki_name = params['wiki_name']
        @wiki_contents = params['wiki_contents']
        @project_key = params['project_key']
        check_param
      end

      def publish
        if @wiki_id.nil?
          @wiki_id = get_wiki_id_by_name(@project_key, @wiki_name)
          if @wiki_id.nil?
            @wiki_id = create_wiki()
            @logger.info("Project \"#{@project_key}\" に \"#{@wiki_name}\" を作成しました.")
          end
        end

        params = {}
        params['name'] = @wiki_name
        params['content'] = @wiki_contents
        begin
          @client.update_wiki(@wiki_id, params)
        rescue => e
          @logger.error "Wikiページ更新に失敗しました. #{e}"
          exit 1
        end
        @wiki_id
      end

      def pull
        @wiki_id = get_wiki_id_by_name(@project_key, @wiki_name) if @wiki_id.nil?
        if @wiki_id.nil?
          @logger.info("Project \"#{@project_key}\" に \"#{@wiki_name}\" は存在しません.")
          return ''
        else
          wiki = @client.get_wiki(@wiki_id)
        end
        wiki.body.content
      end

      def get_wiki_id_by_name(project_key, wiki_name)
        wiki_id = nil
        wikis = @client.get_wikis(project_key)
        wikis.body.each do |w|
          wiki_id = w.id if w.name == wiki_name
        end
        wiki_id
      end

      private

      def check_param
        if @wiki_id.nil?
          msg = "wiki_id、project_key いずれかの指定が必要です." if @project_key.nil? || @project_key.empty?
          msg = "wiki_name が未入力です." if @wiki_name.nil? || @wiki_name.empty?
        elsif not @wiki_id.is_a?(Integer)
          msg = "wiki_id: #{@wiki_id} は整数値で指定してください."
        else
          @logger.warn("wiki_id が指定されているため project_key は無視します.") unless (@project_key.nil? || @project_key.empty?)
        end
        unless msg.nil?
          @logger.error(msg)
          exit 1
        end
      end

      def create_wiki
        begin
          project = @client.get_project(@project_key)
          project_id = project.body.id
          wiki = @client.create_wiki(@wiki_name, "# #{@wiki_name}", project_id, params = {})
          wiki.body.id
        rescue => e
          @logger.error "Wikiページ生成に失敗しました. #{e}"
          exit 1
        end
      end
    end
  end
end
