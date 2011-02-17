# spec helper methods

def build_command(command)
  "#{$client_executable} #{command}"
end

def run_command(command, app_path='.')
  `cd #{app_path} && #{build_command(command)}`.chomp
end

def run_expect(command, app_name=nil)
  `expect #{File.dirname(__FILE__)}/console_test.expect #{$client_executable} "#{command}" #{app_name}`.gsub("\r", '')
end

# http://stackoverflow.com/questions/1496019/suppresing-output-to-console-with-ruby
def silence_stream(stream, &block)
  require 'stringio'
  original_stream = stream
  stream = StringIO.new
  begin
    yield
  ensure
    stream = original_stream
  end
end
