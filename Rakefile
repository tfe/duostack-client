require 'rubygems'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:test) do |spec|
  spec.pattern = 'test/**/*_spec.rb'
  spec.rspec_opts = ['--format doc', '--color']
end

task :default => :test
namespace :test do
  task :rvm do
    exec('rvm 1.8.6,1.9.2 rake test')
  end
  
  namespace :packages do
    task :gem => :version do
      puts "Removing any existing duostack gem installations..."
      puts `rvm 1.8.6,1.9.2 gem uninstall duostack -ax`
      puts "Installing packaged gem..."
      puts `rvm 1.8.6,1.9.2 gem install packages/duostack-client.#{$version}.gem`
      puts "Running tests..."
      exec("DSCLIENT=duostack rake test:rvm")
    end
    task :npm => :version do
      puts "Removing any duostack gem installations..."
      puts `sudo gem uninstall duostack -ax`
      puts "Installing npm package..."
      puts `npm install ./packages/duostack-client.#{$version}.npm.tgz`
      puts "Running tests... (duostack is now #{`which duostack`.chomp})"
      exec("DSCLIENT=duostack rake test")
    end
  end
end

task :version do
  $version = `src/duostack version`.chomp
end

task :package => 'package:all'
namespace :package do
  
  desc "Create gem, npm, and tgz packages of the client."
  task :all => [:tgz, :gem, :npm]
  
  task :tgz => :version do
    puts "Packaging tgz of version #{$version}"
    `sh -c 'COPYFILE_DISABLE=true tar -czf packages/duostack-client.#{$version}.tgz -C src .'`
  end
  
  
  task :gem => :version  do
    puts "Packaging gem of version #{$version}"
    `cd support/gem && rake gemspec && rake build` # builds gem into pkg/
    `mv support/gem/pkg/duostack-#{$version}.gem packages/duostack-client.#{$version}.gem` # move to our packages directory
    `rm -rf support/gem/pkg/ support/gem/duostack.gemspec` # clean up
  end
  
  
  task :npm => :version  do
    puts "Packaging npm package of version #{$version}"
    
    # update version number in package.json
    # http://stackoverflow.com/questions/4397412/read-edit-and-write-a-text-file-line-wise-using-ruby
    path    = 'support/npm/package'
    infile  = File.join(path, 'package.json.template')
    outfile = File.join(path, 'package.json')
    
    File.open(infile) do |template|
      File.open(outfile, 'w') do |json|
        template.each_line do |line|
          output = if line.scan('  "version": "",').length > 0
            '  "version": "' + $version + '",'
          else
            line
          end
          json.puts(output)
        end
      end
    end
    
    # write tarball
    `sh -c 'COPYFILE_DISABLE=true tar -czf packages/duostack-client.#{$version}.npm.tgz -L -C support/npm .'`
    
    # clean up generated package.json
    `rm support/npm/package/package.json`
  end
end
