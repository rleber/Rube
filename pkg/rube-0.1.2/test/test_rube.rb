require File.dirname(__FILE__) + '/test_helper.rb'

class TestRubeBasic < Test::Unit::TestCase

  def setup
    @new_rube = Rube::Generator.new
  end
  
  def test_truth
    assert true
  end
  
  def test_creates_rube_object
    assert_instance_of Rube::Generator, @new_rube, "Rube:Generator.new does not create Rube::Generator object"
  end
  
  def test_rube_object_has_tasks
    assert_respond_to @new_rube, :tasks
  end
  
  def test_rube_object_has_tasks=
    assert_respond_to @new_rube, :tasks=
  end
  
  def test_rube_object_tasks_is_an_array
    assert_kind_of Array, @new_rube.tasks
  end
  
  def test_rube_object_has_add_task
    assert_respond_to @new_rube, :add_task
  end
  
  def test_rube_object_disable_percent
    assert_respond_to @new_rube, :disable_percent
  end
  
  def test_rube_object_disable_percent=
    assert_respond_to @new_rube, :disable_percent=
  end
  
  def test_rube_object_safety
    assert_respond_to @new_rube, :safety
  end
  
  def test_rube_object_safety=
    assert_respond_to @new_rube, :safety=
  end
  
  def test_rube_object_from_command_line
    assert_respond_to @new_rube, :from_command_line
  end
  
  def test_rube_object_from_command_line=
    assert_respond_to @new_rube, :from_command_line=
  end
  
  def test_rube_object_trim_level
    assert_respond_to @new_rube, :trim_level
  end
  
  def test_rube_object_trim_level=
    assert_respond_to @new_rube, :trim_level=
  end
  
  def test_rube_object_trim_mode
    assert_respond_to @new_rube, :trim_mode
  end

  def test_rube_object_go
    assert_respond_to @new_rube, :generate
  end
  
  def test_rube_class_go
    assert_respond_to Rube, :generate
  end
end
  
class TestRubeTaskManipulation < Test::Unit::TestCase

  def setup
    @empty_rube = Rube::Generator.new
  end

  def test_empty_rube_object_has_no_tasks
    assert_equal @empty_rube.tasks.size, 0
  end
  
  def test_rube_object_adds_eval_task
    @empty_rube.add_task :eval, 'bar'
    assert_equal @empty_rube.tasks.size, 1, "Rube add_task did not add eval task"
  end
  
  def test_rube_object_adds_require_task
    @empty_rube.add_task :require, 'bar'
    assert_equal @empty_rube.tasks.size, 1, "Rube add_task did not add require task"
  end
  
  def test_rube_object_adds_template_task
    @empty_rube.add_task :template, 'bar'
    assert_equal @empty_rube.tasks.size, 1, "Rube add_task did not add template task"
  end
  
  def test_rube_object_checks_task_type
    assert_raises(RuntimeError) { @empty_rube.add_task :foo, 'bar' }
  end
  
  def test_rube_object_adds_eval_task_correctly
    @empty_rube.add_task :eval, 'bar'
    assert_equal @empty_rube.tasks.last, [:eval, 'bar']
  end
  
  def test_rube_object_adds_multiple_tasks
    @empty_rube.add_task :require, 'foo'
    @empty_rube.add_task :eval, 'bar'
    assert_equal @empty_rube.tasks.size, 2
    assert_kind_of Array, @empty_rube.tasks.first
    assert_equal @empty_rube.tasks.first.size, 2
    assert_equal @empty_rube.tasks.first.first, :require
    assert_equal @empty_rube.tasks.first.last, 'foo'
    assert_kind_of Array, @empty_rube.tasks.last
    assert_equal @empty_rube.tasks.first.size, 2
    assert_equal @empty_rube.tasks.last.first, :eval
    assert_equal @empty_rube.tasks.last.last, 'bar'
  end
  
  def test_rube_object_task_assignment_works
    @empty_rube.tasks= [[:eval, 'foo'],[:require, 'bar'],[:template, 'baz']]
    assert_equal @empty_rube.tasks.size, 3
    assert_equal @empty_rube.tasks.first, [:eval, 'foo']
    assert_equal @empty_rube.tasks[1], [:require, 'bar']
    assert_equal @empty_rube.tasks.last, [:template, 'baz']
  end
end

class TestRubeSettings < Test::Unit::TestCase

  def setup
    @empty_rube = Rube::Generator.new
  end

  def test_rube_default_disable_percent
    assert_equal false, !!@empty_rube.disable_percent
  end
  
  def test_rube_object_preserves_disable_percent
    @empty_rube.disable_percent = true
    assert_equal true, @empty_rube.disable_percent
  end

  def test_rube_default_safety
    assert_equal nil, @empty_rube.safety
  end

  def test_rube_object_preserves_safety
    @empty_rube.safety = 'foo'
    assert_equal 'foo', @empty_rube.safety
  end

  def test_rube_default_from_command_line
    assert_equal false, !!@empty_rube.from_command_line
  end

  def test_rube_object_preserves_from_command_line
    @empty_rube.from_command_line = 'foo'
    assert_equal 'foo', @empty_rube.from_command_line
  end
end

class TestRubeTrimLevel < Test::Unit::TestCase

  def setup
    @empty_rube = Rube::Generator.new
    @disabled_rube = Rube::Generator.new
    @disabled_rube.disable_percent = true
  end

  def test_rube_default_trim_level
    assert_equal '0', @empty_rube.trim_level
  end

  def test_rube_default_trim_mode
    assert_equal '%', @empty_rube.trim_mode
  end

  def test_rube_default_trim_mode_with_disabled_percent
    assert_equal '', @disabled_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_0
    @empty_rube.trim_level = '0'
    assert_equal '0', @empty_rube.trim_level
    assert_equal '%', @empty_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_1
    @empty_rube.trim_level = '1'
    assert_equal '1', @empty_rube.trim_level
    assert_equal '%>', @empty_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_2
    @empty_rube.trim_level = '2'
    assert_equal '2', @empty_rube.trim_level
    assert_equal '%<>', @empty_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_numeric_1
    @empty_rube.trim_level = 1
    assert_equal '1', @empty_rube.trim_level
    assert_equal '%>', @empty_rube.trim_mode
  end

  def test_rube_object_rejects_invalid_trim_level
    assert_raises(Rube::BadArgumentError) { @empty_rube.trim_level = 'foo' }
  end
  
  def test_rube_object_accepts_trim_level_dash
    @empty_rube.trim_level = '-'
    assert_equal '-', @empty_rube.trim_level
    assert_equal '%-', @empty_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_0_with_disabled_percent
    @disabled_rube.trim_level = '0'
    assert_equal '0', @disabled_rube.trim_level
    assert_equal '', @disabled_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_1_with_disabled_percent
    @disabled_rube.trim_level = '1'
    assert_equal '1', @disabled_rube.trim_level
    assert_equal '>', @disabled_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_2_with_disabled_percent
    @disabled_rube.trim_level = '2'
    assert_equal '2', @disabled_rube.trim_level
    assert_equal '<>', @disabled_rube.trim_mode
  end

  def test_rube_object_accepts_trim_level_dash_with_disabled_percent
    @disabled_rube.trim_level = '-'
    assert_equal '-', @disabled_rube.trim_level
    assert_equal '-', @disabled_rube.trim_mode
  end
end

class TestRubeProcessing < Test::Unit::TestCase

  def setup
    @out = StringIO.new
    @rube = Rube::Generator.new(@out)
  end
  
  def test_simple_eval
    @rube.add_task :eval, 'puts "foo"'
    res = @rube.generate
    assert_equal "foo\n", @out.string, "Failed to produce expected output on $stdout"
    assert_equal nil, res, "Without redirection, rube.generate should return nil"
  end
  
  def test_process_require_task
    @rube.add_task :require, 'English'
    @rube.add_task :eval, 'puts $PID'
    @rube.generate
    # If English doesn't load properly, then $PID is nil; if it does, then it's a numeric process id
    assert_match(/^\d+$/, @out.string.chomp, "Failed to load require file")
  end
  
  def test_process_template_task
    @rube.add_task :template, 'templates/test1'
    @rube.generate
    assert_equal "foo\nblurg\nblurble\n\nfarb\n\n", @out.string, "Failed to produce expected result from test1 template"
  end
  
  def test_process_template_task_with_disabled_percent
    @rube.disable_percent = true
    @rube.add_task :template, 'templates/test1'
    @rube.generate
    # Note: test1 template produces different results with % lines disabled
    assert_equal "foo\nblurg\nblurble\n\n% z = 'farb'\nbarf\n\n", @out.string, "Failed to produce expected result from test1 template with percentage lines disabled"
  end
  
  def test_process_template_task_with_trim_level_1
    @rube.trim_level = 1
    @rube.add_task :template, 'templates/test1'
    @rube.generate
    assert_equal "foo\nblurgblurblefarb\n", @out.string, "Failed to produce expected result from test1 template"
  end
  
  def test_process_template_task_with_trim_level_2
    @rube.trim_level = 2
    @rube.add_task :template, 'templates/test1'
    out = @rube.generate
    assert_equal "foo\nblurgblurble\nfarb\n", @out.string, "Failed to produce expected result from test1 template"
  end
  
  def test_process_template_with_persistent_variable
    @rube.add_task :eval, 'b="foo"'
    @rube.add_task :template, 'templates/test2'
    @rube.generate
    assert_equal "bar\nfoo*2\n", @out.string, "Failed to produce expected result from test2 template with passed variable value"
  end
end

class TestRubeErrors < Test::Unit::TestCase
  def setup
    @out = StringIO.new
    @rube = Rube::Generator.new(@out)
  end

  def test_bad_eval
    @rube.add_task :eval, 'foo'
    assert_raises(Rube::ScriptError) { @rube.generate }
  end

  def test_bad_require
    @rube.add_task :require, 'foo'
    assert_raises(Rube::MissingRequireError) { @rube.generate }
  end

  def test_bad_template
    @rube.add_task :template, 'foo'
    assert_raises(Rube::MissingTemplateError) { @rube.generate }
  end
end

class TestRubeCommandLineHelp < Test::Unit::TestCase
  HELP_PATTERN = /erb templates.*Usage:/m
  def test_help
    res = `rube --help 2>&1`
    assert_match HELP_PATTERN, res, "Failed to produce help text for --help"
    assert_equal 1, $?.exitstatus, "Expected return code of 1 for help text"
  end

  BAD_PATTERN = /invalid option.*foo.*erb templates.*Usage:/m
  def test_bad_argument
    res = `rube --foo 2>&1`
    assert_match BAD_PATTERN, res, "Failed to produce error message and help text for --foo"
    assert_equal 2, $?.exitstatus, "Expected return code of 2 for bad argument"
  end

  REQUIRE_ERROR_PATTERN = /Can't find require file/
  def test_bad_require
    res = `rube -E -r 'foo' 2>&1`
    assert_match REQUIRE_ERROR_PATTERN, res, "Failed to produce error message for bad require file"
    assert_equal 3, $?.exitstatus, "Expected return code of 3 for bad require file"
  end

  TEMPLATE_ERROR_PATTERN = /Can't find template file/
  def test_bad_template
    res = `rube -E foo 2>&1`
    assert_match TEMPLATE_ERROR_PATTERN, res, "Failed to produce error message for bad template file"
    assert_equal 4, $?.exitstatus, "Expected return code of 4 for bad template file"
  end

  SOURCE_ERROR_PATTERN = /Error executing source/
  def test_bad_eval
    res = `rube -E -e 'foo' 2>&1`
    assert_match SOURCE_ERROR_PATTERN, res, "Failed to produce error message for bad eval source"
    assert_equal 5, $?.exitstatus, "Expected return code of 5 for bad eval source"
  end
end

class TestRubeCommandLineIndirectly < Test::Unit::TestCase
#
#   Not really an exhaustive test, but if this works, things should be okay
#
  
  def test_eval
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['-E', '-e', 'puts "foo"'])
      assert_equal "foo\n", out.string, "Failed to produce expected output on $stdout"
    end
  end

  def test_process_require_task
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['-E', '-r', 'English', '-e', 'puts $PID'])
      # If English doesn't load properly, then $PID is nil; if it does, then it's a numeric process id
      assert_match(/^\d+$/, out.string.chomp, "Failed to load require file")
    end
  end

  def test_process_require_task_long_form
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['--explicit', '--require', 'English', '--eval', 'puts $PID'])
      # If English doesn't load properly, then $PID is nil; if it does, then it's a numeric process id
      assert_match(/^\d+$/, out.string.chomp, "Failed to load require file")
    end
  end
  
  def test_process_template_task
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['templates/test1'])
      assert_equal "foo\nblurg\nblurble\n\nfarb\n\n", out.string, "Failed to produce expected result from test1 template"
    end
  end
  
  def test_process_template_task_with_disabled_percent
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['-P', 'templates/test1'])
      # Note: test1 template produces different results with % lines disabled
      assert_equal "foo\nblurg\nblurble\n\n% z = 'farb'\nbarf\n\n", out.string, "Failed to produce expected result from test1 template with percentage lines disabled"
    end
  end
  
  def test_process_template_task_with_trim_level_1
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['--trim', '1', 'templates/test1'])
      assert_equal "foo\nblurgblurblefarb\n", out.string, "Failed to produce expected result from test1 template"
    end
  end
  
  def test_process_template_task_with_trim_level_2
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['--trim', '2', 'templates/test1'])
      assert_equal "foo\nblurgblurble\nfarb\n", out.string, "Failed to produce expected result from test1 template"
    end
  end
  
  def test_process_template_with_persistent_variable
    StringIO.open do |out|
      res = Rube::CLI.execute(out, ['--eval', 'b="foo"', 'templates/test2'])
      assert_equal "bar\nfoo*2\n", out.string, "Failed to produce expected result from test2 template with passed variable value"
    end
  end
end

class TestRubeCommandLineDirectly < Test::Unit::TestCase
#
#   Not really an exhaustive test, but if this works, things should be okay
#
  def test_eval
    res = `rube -E -e 'puts "foo"'`
    assert_equal "foo\n", res, "Failed to produce expected output on $stdout"
  end

  def test_process_require_task
    res = `rube --explicit -r English -e 'puts $PID'`
    # If English doesn't load properly, then $PID is nil; if it does, then it's a numeric process id
    assert_match(/^\d+$/, res.chomp, "Failed to load require file")
  end
  
  def test_process_template_task
    res = `rube templates/test1` # Not sure why it insists on the '.rb' here, but it does...
    assert_equal "foo\nblurg\nblurble\n\nfarb\n\n", res, "Failed to produce expected result from test1 template"
  end
  
  def test_process_implicit_template_task
    res = `rube < templates/test1`
    assert_equal "foo\nblurg\nblurble\n\nfarb\n\n", res, "Failed to produce expected result from implicit test1 template"
  end
  
  def test_process_explicit_stdin_template_task
    res = `rube -e 'b="foo"' --stdin templates/test2 < templates/test1`
    assert_equal "foo\nblurg\nblurble\n\nfarb\n\nbar\nfoo*2\n", res, "Failed to produce expected result from explicit stdin template"
  end
end
