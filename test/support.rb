# spec helper methods

def build_command(command)
  "#{File.dirname(__FILE__)}/../src/duostack #{command}"
end

def run_command(command)
  `#{build_command(command)}`.chomp
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
