module YARD
  module CLI
    # A local documentation server
    class Server < Command
      # @return [Hash] a list of options to pass to the doc server
      attr_accessor :options
      
      # @return [Hash] a list of options to pass to the web server
      attr_accessor :server_options
      
      # @return [Hash] a list of project names and yardoc files to serve
      attr_accessor :projects
      
      def description
        "Runs a local documentation server"
      end
      
      def initialize
        Templates::Template.extra_includes << YARD::Server::DocServerHelper
        Templates::Engine.template_paths.push(File.dirname(__FILE__) + '/../server/templates')
      end
      
      def run(*args)
        self.projects = {}
        self.options = SymbolHash.new(false).update(
          :single_project => true,
          :caching => false
        )
        self.server_options = {:Port => 8808}
        optparse(*args)
        
        log.debug "Serving projects: #{projects.keys.join(', ')}"
        YARD::Server::WebrickAdapter.start(projects, options, server_options) 
      end
      
      private
      
      def add_projects(args)
        args.each_cons(2) do |project, yardoc| 
          if File.exist?(yardoc)
            projects[project] = yardoc || '.yardoc'
          else
            log.warn "Cannot find yardoc db for #{project}: #{yardoc}"
          end
        end
      end
      
      def optparse(*args)
        opts = OptionParser.new
        opts.banner = 'Usage: yard server [options] [[project yardoc_file] ...]'
        opts.separator ''
        opts.separator 'Example: yard server yard .yardoc ruby-core ../ruby/.yardoc'
        opts.separator 'The above example serves documentation for YARD and Ruby-core'
        opts.separator ''
        opts.separator 'If no project/yardoc_file is specified, the server uses'
        opts.separator 'the name of the current directory and `.yardoc` respectively'
        opts.separator ''
        opts.separator "General Options:"
        opts.on('-m', '--multi-project', 'Serves documentation for multiple projects') do
          options[:single_project] = false
        end
        opts.on('-c', '--cache', 'Caches all documentation to document root (see --docroot)') do
          options[:caching] = true
        end
        opts.on('-r', '--reload', 'Reparses the project code on each request') do
          options[:incremental] = true
        end
        opts.separator ''
        opts.separator "Web Server Options:"
        opts.on('-d', '--daemon', 'Daemonizes the server process') do 
          server_options[:ServerType] = WEBrick::Daemon
        end
        opts.on('-p PORT', '--port', 'Serves documentation on PORT') do |port|
          server_options[:Port] = port.to_i
        end
        opts.on('--docroot DOCROOT', 'Uses DOCROOT as document root') do |docroot|
          server_options[:DocumentRoot] = docroot
        end
        common_options(opts)
        parse_options(opts, args)
        
        if args.empty?
          projects[File.basename(Dir.pwd)] = '.yardoc'
        else
          add_projects(args)
          options[:single_project] = false if projects.size > 1
        end
      end
    end
  end
end