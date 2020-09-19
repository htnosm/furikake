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
      end

      def publish
        if @wiki_id.nil?
          if @project_key.nil?
            @logger.error("wiki_id、project_key いずれかの指定が必要です.")
            exit 1
          elsif @wiki_name.nil? or @wiki_name.length == 0
            @logger.error("wiki_name が未入力です.")
            exit 1
          end

          wikis = @client.get_wikis(@project_key)
          wikis.body.each do |w|
            @wiki_id = w.id if w.name == @wiki_name
          end
          if @wiki_id.nil?
            @wiki_id = create_wiki()
            @logger.info("Project \"#{@projcet_key}\" に \"#{@wiki_name}\" を作成しました.")
          end
        elsif not @wiki_id.is_a?(Integer)
          @logger.error("wiki_id: #{@wiki_id} は整数値で指定してください.")
          exit 1
        else
          @logger.info("wiki_id が指定されているため project_key は無視します.") unless @project_key.nil?
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

      private

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
