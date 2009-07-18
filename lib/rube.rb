#!/usr/bin/ruby
#
# Rube --
#   Slightly smarter erb front-end
#   
#   Rube allows you to apply erb to templates, interspersed with other ruby code, either as inline source or as 
#   ruby files (e.g. requires). Rube can be invoked from the command line as a command in the form:
#
#     rube [options] task ...

#   or as part of a ruby script, as in:
#
#     require 'rube'
#     rube = Rube.new
#     rube.add_task(:require, 'active_record')
#     rube.add_task(:template, 'foo')
#     rube.generate
#
#   In either case, tasks may be erb templates, ruby files, or inline ruby code. Each of the tasks is performed in
#   the order specified and variables, constants etc. are preserved across tasks (including local variables) so that
#   subsequent tasks can refer to the the results of earlier tasks. This makes it simpler to use erb templates against 
#   arbitrary data. For instance:
#
#     rube -r active_support -r yaml -e "document=YAML.load(IO.read('document.yml))" --trim 2 --stdin convert_to_textile.erb
#
#   would process the template on stdin followed by the template in convert_to_textile.erb, having already loaded the 
#   active_support and yaml libraries, and having loaded the YAML file document.yml and parsed it into a Ruby variable named 
#   document, where the information could easily be referred to in the template. This all would be done at erb trim level 2.
#
#   The equivalent code for the above, when invoked from within a Ruby script, would be:
#
#     require 'rube'
#     rube = Rube.new
#     rube.trim_level = 2
#     rube.add_task(:require, 'active_support')
#     rube.add_task(:require, 'yaml')
#     rube.add_task(:eval, "document=YAML.load(IO.read('document.yml))" )
#     rube.add_task(:template, 'dev/stdin') # Note, there is no direct equivalent to the --stdin parameter
#     rube.add_task(:template, 'convert_to_textile.erb')
#     rube.generate
#
#   If invoked from the command line AND if no template file is specified among the tasks, rube assumes it should read a 
#   template from stdin, after processing all other tasks. This behavior can be turned off using the --explicit option.
#
#   In addition to the above, rube allows similar parameters to erb for setting $SAFE, $DEBUG and trim levels. Type
#
#     rube --help
#
#   at the command line for more information.
#
#   For convenience, the Ruby API allows two additional methods which override the default setting for output,
#   which is to $stdout:
#     rube.to_string = true     Causes rube.generate to output results to a string
#     rube.to_file "name"       Causes rube.generate to output results to the named file

require 'optparse'
require 'erb'

class Rube
  VERSION = %x{cat #{File.dirname(__FILE__)+'/../VERSION'}}.chomp
  
  # Class and procedure to provide context for evaluation of tasks: ruby inline code, requires, and erb templates
  class EvalContext
    # All tasks are executed in the sandbox
    def sandbox
      return binding
    end
  end
  
  class HelpRequested < ArgumentError
    def self.exit_code
      1
    end
  end
  
  class BadArgumentError < ArgumentError
    def self.exit_code
      2
    end
  end
  
  class MissingRequireError < IOError
    def self.exit_code
      3
    end
  end
  
  class MissingTemplateError < IOError
    def self.exit_code
      4
    end
  end
  
  class ScriptError < IOError
    def self.exit_code
      5
    end
  end
  
  attr_accessor :tasks, :safety, :from_command_line, :to_string, :to_file
  attr_reader :trim_level, :trim_mode, :disable_percent
  
  def initialize
    @tasks = []
    @trim_level = nil
    self.disable_percent = false
    self.trim_level = nil
    @from_command_line = nil
    @to_string = false
    @to_file = nil
    @safety = nil
    @explicit = false
  end
  
  # Process command line options
  def process_options(*args)
    @tasks = []
    template_count = 0
    tr_level = nil
    @op = OptionParser.new
    @op.banner = "Process erb templates along with other ruby tasks"
    @op.separator "Usage: #{File.basename($0)} [options] task ..."
    @op.separator ''
    @op.separator "Each task may be a template, require or eval (see below). These are processed in the order given,"
    @op.separator "so results from prior tasks are available to subsequent ones. All variables and constants, including"
    @op.separator "local variables, are preserved, so their values are available to subsequent tasks."
    @op.separator ''
    @op.separator "Tasks:"
    @op.separator "    path/to/template/file            Process the specified erb template file"
    @op.on('-i', '--stdin', "Process the template provided in stdin") do |val| 
      template_count += 1
      @tasks << [:template, '/dev/stdin']
    end
    @op.on('-r', '--require path/to/ruby/file', "Load a ruby library or source code file") {|val| @tasks << [:require, val] }
    @op.on('-e', '--eval "ruby code"', "Evaluate some inline ruby code"){|src| @tasks << [:eval, src] }
    @op.separator ''
    @op.separator "Options:"
    @op.on('-E', '--[no-]explicit', "All templates must be explicitly provided. Default is false -- rube assumes it should read",
                      "a template from stdin if no templates are specified among the tasks") {|val| @explicit = val }
    @op.on('-S', '--safe SAFE_LEVEL', Integer, "Set $SAFE (0..4). Default off") do |val|
      error BadArgumentError, "Invalid --safe level #{val}. Should be 0..4" unless (0..4).include?(val)
      @safety = val 
    end
    @op.on('-T', '--trim TRIM_LEVEL', "Set trim level (0..2, or '-'). Default 0") {|trim| tr_level = trim }
    @op.on('-P', '--[no-]disable-percent', "Disable '%' prefix for erb code. Default false") {|val| self.disable_percent = val }
    @op.on_tail('-h', '--help', "Produce this help list") {|val| help }
    @op.on_tail('-v', '--version', "Show version") {|val| puts VERSION; exit 0 }
    begin
      @templates = @op.order!(args) do |template|
        template_count += 1
        @tasks << [:template, template]
      end
    rescue OptionParser::InvalidOption, OptionParser::InvalidArgument => e
      $stderr.puts e.to_s
      help BadArgumentError
    end
    @tasks << [:template, '/dev/stdin'] if !@explicit && template_count == 0
    self.trim_level = tr_level
  end
  
  def disable_percent=(disable_percent)
    @disable_percent = disable_percent
    @trim_mode = trim_mode_opt(@trim_level)
  end
  
  def trim_level=(trim_level)
    @trim_level = (trim_level || '0').to_s
    @trim_mode = trim_mode_opt(@trim_level)
  end

  # Convert command line trim_mode to a form erb will understand
  def trim_mode_opt(trim_mode)
    mode = disable_percent ? '' : '%'
    mode += case trim_mode.to_s
    when '0','' then  ''
    when '1'    then  '>'
    when '2'    then  '<>'
    when '-'    then  '-'
    else              error BadArgumentError, "Invalid trim mode #{trim_mode}. Should be 0, 1, 2, or -"
    end
  end

  # Display command line help
  def help(exception=HelpRequested)
    error exception, @op.to_s
  end
  
  # Add a task
  def add_task(type, task)
    case type
    when :require, :eval, :template then  @tasks << [type, task]
    else                                  raise "Invalid task type #{type.inspect}"
    end
    self # Allow chaining
  end
  
  # Run all the tasks
  def generate
    @eval_context = EvalContext.new
    @binding = @eval_context.sandbox
    saved_stdout = $stdout
    if @to_string
      $stdout = StringIO.new
    elsif @to_file
      $stdout = File.new @to_file, 'w'
    end
    @tasks.each {|p| execute p }
    res = nil
    if @to_string
      res = $stdout.string
    elsif @to_file
      $stdout.close
    end
    res
  ensure
    $stdout = saved_stdout
  end
  
  # Execute a single task
  def execute(p)
    case p.first
    when :require
      protected_require(p.last)
    when :eval
      protected_eval(p.last)
    when :template
      protected_erb(p.last)
    else
      raise "Unexpected task #{p.inspect}"
    end
  end
  
  # Load a ruby file or library
  def protected_require(r)
    @eval_context.instance_eval {require r}
  rescue LoadError
    error MissingRequireError, "Can't find require file #{r}"
  end
  
  # Evaluate inline ruby code
  def protected_eval(src)
    bind_at = @binding
    @eval_context.instance_eval{eval src, bind_at}
  rescue => e
    error ScriptError, "Error executing source:\n#{src}\n\n#{e.to_s}"
  end
  
  # Process an erb template
  def protected_erb(template)
    error MissingTemplateError, "Can't find template file #{template}" unless File.exists?(template)
    source = File.read(template)
    puts ERB.new(source, @safety, @trim_mode).result(@binding)
  end

  # Issue an error message or exception
  def error(exception, msg)
    raise exception, msg unless @from_command_line || exception.nil?
    $stderr.puts msg
    exit_code = exception.exit_code rescue 0
    exit exit_code if @from_command_line
  end
  
  # Convenience method: create a Rube object and use it to execute command line-style arguments
  def self.generate(*args)
    rube = new
    options = {}
    if args.last.is_a?(Hash)
      options = args.pop
    end
    rube.from_command_line = options[:from_command_line]
    rube.process_options(*args)
    rube.generate
  end
end

if $0 == __FILE__
  Rube.generate(*(ARGV << {:from_command_line=>true}))
end
