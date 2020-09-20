require 'furikake'

module Furikake
  class CLI < Thor
    desc 'version', 'version print.'
    def version
      puts Furikake::VERSION
    end

    desc 'show', 'resouces print.'
    def show
      report = Furikake::Report.new(true)
      report.show
    end

    desc 'diff', 'resouces diffs print.'
    def diff
      report = Furikake::Report.new(true)
      report.diff
    end

    desc 'publish', 'resouces publish to something. (Default: Backlog)'
    option :force, type: :boolean, aliases: '-f', default: true, desc: 'force publish.'
    def publish
      report = Furikake::Report.new(true)
      report.publish(options)
    end

    desc 'monitor', 'resouces publish to something by daemonize process.'
    option :detach, type: :boolean, aliases: '-d', default: false, desc: 'detach monitor process.'
    option :interval, type: :numeric, aliases: '-i', default: 3600, desc: 'specify monitor interval (sec).'
    option :pid, type: :string, aliases: '-p', default: 'furikake.pid', desc: 'specify PID file path (Default: furikake.pid)'
    def monitor
      monitor = Furikake::Monitor.new(options)
      monitor.run
    end

    desc 'setup', 'generate .furikake.yml template.'
    def setup
      Furikake::Setup.run
    end
  end
end
