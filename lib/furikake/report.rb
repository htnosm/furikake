require 'furikake/reporters/backlog'
require 'diff/lcs'

module Furikake
  class Report
    include Furikake::Config

    def initialize(cli, params = nil)
      $stdout.sync = true
      @logger = Logger.new($stdout)
      @cli = cli
      @params = @cli ? read_furikake_yaml : params
      raise ArgumentError, 'パラメータが設定されていません.' if @params.nil?
    end

    def show
      @params['backlog']['projects'].each do |p|
        header = insert_published_by(p['header'])
        footer = p['footer']
        puts generate(header, footer)
      end
    end

    def diff
      @params['backlog']['projects'].each do |p|
        header = insert_published_by(p['header'])
        footer = p['footer']
        document = generate(header, footer)
        param = check_api_key(p)
        current = Furikake::Reporters::Backlog.new(param).pull
        diffs = diff_content(current.split("\n"), document.split("\n"))
        if diffs.length.positive?
          @logger.info("wikiとの差分を出力します.")
          puts diffs
        else
          @logger.info("wikiとの差分はありません.")
        end
      end
    end

    def publish(options)
      @force = options['force']
      @params['backlog']['projects'].each do |p|
        header = insert_published_by(p['header'])
        footer = p['footer']
        document = generate(header, footer)
        p['wiki_contents'] = document
        param = check_api_key(p)
        current = Furikake::Reporters::Backlog.new(param).pull
        diffs = diff_content(current.split("\n"), document.split("\n")) unless @force
        if @force || diffs.length.positive?
          wiki_id = Furikake::Reporters::Backlog.new(param).publish
          @logger.info("#{param['space_id']} の #{wiki_id} に情報を投稿しました.")
        else
          @logger.info("更新差分が無いためスキップしました.")
        end
      end
    end

    private

    def generate(header, footer)
      resource = Furikake::Resource.generate(@cli, @params['resources'])
      # Backlog上でのテーブル形式崩れの対応
      ## アンダースコア (|_) へバックスラッシュ挿入
      resource.gsub!(/\|_/, "|\\_")
      ## アスタリスク (|*) へバックスラッシュ挿入
      resource.gsub!(/\|\*/, "|\\*")
      ## 空白 (||) へスペース挿入
      resource.gsub!(/\|\|/, "| |") while resource.match(/\|\|/)

      # table format
      resource.gsub!(/\|:-\|/, "|:---|") while resource.match(/\|:-\|/)
      resource.gsub!(/\|-\|/, "|---|") while resource.match(/\|-\|/)
      resource.gsub!(/\|-:\|/, "|---:|") while resource.match(/\|-:\|/)
      resource.gsub!(/\|:-:\|/, "|:---:|") while resource.match(/\|:-:\|/)

      documents = <<"EOS"
#{header}
#{resource}
#{footer}
EOS
      documents
    end

    def check_api_key(param)
      if !param.has_key?('api_key') or param['api_key'].nil?
        if !ENV['BACKLOG_API_KEY'].nil? or !ENV['BACKLOG_API_KEY'] == ''
          param['api_key'] = ENV['BACKLOG_API_KEY'] 
          return param
        end
        raise 'API キーを読み込むことが出来ませんでした.'
      end
      param
    end

    def insert_published_by(header)
      headers = header.split("\n")
      headers.insert(1, published_by)
      headers.insert(2, "\n")
      headers.join("\n")
    end
 
    def published_by
      "*Published #{Time.now}*"
    end

    def diff_content(before, after)
      diffs = Diff::LCS.diff(before, after)
      output = []
      diffs.each do |diff|
        next if diff.first.element.match(/\*Published /)

        output << '-----'
        diff.each do |line|
          output << "#{line.position} #{line.action} #{line.element}"
        end
      end
      output
    end
  end
end
