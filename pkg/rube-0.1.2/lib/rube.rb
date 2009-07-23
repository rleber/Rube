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
#     rube = Rube.new($stdout, :trim_level=>2)
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

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'optparse'
require 'erb'

module Rube
  VERSION = %x{cat #{File.dirname(__FILE__)+'/../VERSION'}}.chomp
  
  # Class and procedure to provide context for evaluation of tasks: ruby inline code, requires, and erb templates
  class EvalContext
    # All tasks are executed in the sandbox
    def sandbox
      return binding
    end
  end
  
  class RubeError < RuntimeError
  end
  
  class BadArgumentError < RubeError
  end
  
  class MissingRequireError < RubeError
  end
  
  class MissingTemplateError < RubeError
  end
  
  class ScriptError < RubeError
  end
  
  class Generator
    attr_accessor :tasks, :safety, :from_command_line
    attr_reader :trim_level, :trim_mode, :disable_percent
  
    def initialize(stdout=$stdout, options={})
      @stdout = stdout
      @tasks = options[:tasks] || []
      @trim_level = nil
      self.disable_percent = options[:disable_percent]
      self.trim_level = options[:trim_level]
      @from_command_line = options[:from_command_line]
      @safety = options[:safety]
      @explicit = options[:explicit]
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
      saved_stdout, $stdout = $stdout, @stdout
      @tasks.each {|p| execute p }
      nil
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
      @stdout.puts ERB.new(source, @safety, @trim_mode).result(@binding)
    end

    # Issue an error message or exception
    def self.error(exception, msg)
      raise exception, msg
    end
    
    def error(exception, msg)
      self.class.error exception, msg
    end
  end
  
  # Convenience method: create a Rube object and use it to execute command line-style arguments
  def self.generate(stdout, options)
    rube = Generator.new(stdout, options)
    rube.generate
  end
end
