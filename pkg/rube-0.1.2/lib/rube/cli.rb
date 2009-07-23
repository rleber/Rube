require 'optparse'

module Rube
  class ExitStatus
    HELP_REQUESTED = 1
    BAD_ARGUMENT = 2
    MISSING_REQUIRE = 3
    MISSING_TEMPLATE = 4
    SCRIPT_ERROR = 5
  end
  
  class CLI
    def self.execute(stdout, arguments=[])

      # NOTE: the option -p/--path= is given as an example, and should be replaced in your application.

      options = {
        :tasks              => [],
        :explicit           => false,
        :trim_level         => '0',
        :disable_percent    => false,
        :safe               => nil,
        :from_command_line  => true
      }
  
      mandatory_options = %w(  )
      template_count = 0
      tr_level = nil
      parser = OptionParser.new do |opts|
        opts = OptionParser.new

        opts.banner = <<-BANNER.gsub(/^          /,'')
          Process erb templates along with other ruby tasks

          Usage: #{File.basename($0)} [options] tasks

          Each task may be a template, require or eval (see below). These are processed in the order given,
          so results from prior tasks are available to subsequent ones. All variables and constants, including
          local variables, are preserved, so their values are available to subsequent tasks.
        BANNER

        opts.separator ''
        opts.separator "Tasks:"
        opts.separator "    path/to/template/file            Process the specified erb template file"
        opts.on('-i', '--stdin', "Process the template provided in stdin") do |val| 
          template_count += 1
          options[:tasks] << [:template, '/dev/stdin']
        end
        opts.on('-r', '--require path/to/ruby/file', "Load a ruby library or source code file") {|val| options[:tasks] << [:require, val] }
        opts.on('-e', '--eval "ruby code"', "Evaluate some inline ruby code"){|src| options[:tasks] << [:eval, src] }
        opts.separator ''
        opts.separator "Options:"
        opts.on('-E', '--[no-]explicit', "All templates must be explicitly provided. Default is false -- rube assumes it should read",
                          "a template from stdin if no templates are specified among the tasks") {|val| options[:explicit] = val }
        opts.on('-S', '--safe SAFE_LEVEL', Integer, "Set $SAFE (0..4). Default off") do |val|
          help stdout, opts, "Invalid --safe level #{val}. Should be 0..4", ExitStatus::BAD_ARGUMENT unless (0..4).include?(val)
          options[:safety] = val 
        end
        opts.on('-T', '--trim TRIM_LEVEL', "Set trim level (0..2, or '-'). Default 0") {|trim| tr_level = trim }
        opts.on('-P', '--[no-]disable-percent', "Disable '%' prefix for erb code. Default false") {|val| options[:disable_percent] = val }
        opts.on_tail('-h', '--help', "Produce this help list") {|val| help stdout, opts }
        opts.on_tail('-v', '--version', "Show version") {|val| puts VERSION; exit 0 }
        begin
          @templates = opts.order!(arguments) do |template|
            template_count += 1
            options[:tasks] << [:template, template]
          end
        rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
          help stdout, opts, e.to_s, ExitStatus::BAD_ARGUMENT 
        end
        options[:tasks] << [:template, '/dev/stdin'] if !options[:explicit] && template_count == 0
        options[:trim_level] = tr_level

        if mandatory_options && mandatory_options.find { |option| options[option.to_sym].nil? }
          help stdout, opts
        end
      end

      begin
        Rube.generate(stdout, options)
      rescue BadArgumentError => e
        quit stdout, e.to_s, ExitStatus::BAD_ARGUMENT
      rescue MissingRequireError => e
        quit stdout, e.to_s, ExitStatus::MISSING_REQUIRE
      rescue MissingTemplateError => e
        quit stdout, e.to_s, ExitStatus::MISSING_TEMPLATE
      rescue ScriptError => e
        quit stdout, e.to_s, ExitStatus::SCRIPT_ERROR
      end
    end
    
    def self.help(stdout, opt_parser, msg = nil, exit_code = ExitStatus::HELP_REQUESTED)
      m = msg.to_s
      m += "\n" unless m == ''
      m += opt_parser.to_s
      quit stdout, m, exit_code
    end
    
    def self.quit(stdout, msg=nil,exit_code = 0)
      stdout.puts msg
      exit exit_code
    end
      
  end
end