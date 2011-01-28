require File.dirname(__FILE__) + '/support'

describe "Duostack client" do
  
  before(:all) do
    # set which client to use (allows testing of gem installed client)
    # uses client in src/ by default
    $client = ENV['DSCLIENT'] || "#{File.dirname(__FILE__)}/../src/duostack"
    
    # generate a test app name off of current timestamp
    @app_name = "test#{Time.now.to_i}"
    @app_path = "/tmp/duostack/#{@app_name}"
  end
  
  describe "general commands" do
    
    it "displays help" do
      run_command("").should =~ /Usage/
      run_command("help").should =~ /Usage/
    end
    
    it "displays version number" do
      run_command("version").should =~ /\A\d+\.\d+\.\d+\Z/
    end
  end
  
  
  describe "user commands" do
    
    before(:all) do
      
      # make directory, copy template app, and initialize a git repo for test app
      `mkdir -p #{@app_path}`
      `cp -r #{File.dirname(__FILE__)}/templates/rack/* #{@app_path}`
      `cd #{@app_path} && git init && git add . && git commit -m "Initial commit."`
    end
    
    
    it "should allow app creation" do
      result = `cd #{@app_path} && #{build_command("create")} #{@app_name}`.chomp
      result.should match("Duostack initialized. To push: git push duostack master")
    end
    
    it "should list apps with created app" do
      result = run_command("list")
      result.split("\n").length.should > 0
      result.split("\n").include?(@app_name)
    end
    
    
    describe "app commands" do
      
      it "should accept a git push" do
        result = `cd #{@app_path} && git push duostack master 2>&1`
        result.should match("App successfully deployed to")
        result.should match("http://#{@app_name}.duostack.net")
      end
      
      it "should restart an app" do
        result = run_command("restart --app #{@app_name}")
        result.should match("App restarted")
        result.should_not match("Unable to restart app")
      end
      
      it "should retrieve logs" do
        run_command("logs --app #{@app_name}").should match('==>')
      end
      
      it "should retrieve process list" do
        run_command("ps --app #{@app_name}").should match('Instance ID')
      end
      
      
      describe "config commands" do
      
        it "should list config options for stack" do
          result = run_command("config stack --app #{@app_name}")
          result.should match("autodetect")
          result.should match("ruby-mri-1.9.2")
        end
      
        it "should allow setting config option for stack" do
          result = run_command("config stack ruby-mri-1.9.2 --app #{@app_name}")
          result.should match("App will be migrated to ruby-mri-1.9.2 during next Git push.")
        end
      
        it "should reflect stack change upon re-push" do
          `cd #{@app_path} && touch poke && git add poke && git commit -m "poke" && git push duostack master 2>&1`
          result = `expect #{File.dirname(__FILE__)}/console_test.expect #{@app_name} "IO.popen('ruby -v') { |f| puts f.gets }"`.gsub("\r", '')
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn duostack console --app #{@app_name}
            Connecting to Ruby console for #{@app_name}...
            >> IO.popen('ruby -v') { |f| puts f.gets }
            ruby 1.9.2p136 (2010-12-25 revision 30365) [x86_64-linux]
            => nil
            >> exit
            Connection to duostack.net closed.
          END
        
          result.should == expected
        end
      
      end      
      
      describe "environment variables" do
      
        it "should allow adding env vars" do
          run_command("env add env1=var1 --app #{@app_name}").should match('env1 => var1')
        end
      
        it "should allow adding multiple env vars at once" do
          result = run_command("env add env2=var2 env3=var3 --app #{@app_name}")
          result.should match('env2 => var2')
          result.should match('env3 => var3')
        end
      
        it "should allow adding quoted env vars" do
          run_command("env add env4='multi word string' --app #{@app_name}").should match('env4 => multi word string')
        end
      
        it "should allow adding env vars containing single/double quotes" do
          run_command(%Q(env add env5='"double quoted"' --app #{@app_name})).should match(%Q(env5 => "double quoted"))
          run_command(%Q(env add env6="'single quoted'" --app #{@app_name})).should match(%Q(env6 => 'single quoted'))
        end
      
        it "should list env vars" do
          result = run_command("env --long --app #{@app_name}")
          result.should match(run_command("env list --app #{@app_name}"))
          result.should match('env1 => var1')
          result.should match('env2 => var2')
          result.should match('env3 => var3')
          result.should match('env4 => multi word string')
          result.should match('env5 => "double quoted"')
          result.should match("env6 => 'single quoted'")
        end
      
        it "should see env vars in console" do
          run_command("restart --app #{@app_name}") # need to restart first
        
          result = `expect #{File.dirname(__FILE__)}/console_test.expect #{@app_name} "ENV['env1']"`.gsub("\r", '')
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn duostack console --app #{@app_name}
            Connecting to Ruby console for #{@app_name}...
            >> ENV['env1']
            => "var1"
            >> exit
            Connection to duostack.net closed.
          END
        
          result.should == expected
        end
      
        it "should allow removing env vars" do
          run_command("env remove env1 --app #{@app_name}").should == "Environment variable(s) removed"
          run_command("env --app #{@app_name}").should_not match('env1')
        end

        it "should allow removing multiple env vars at once" do
          run_command("env remove env2 env3 --app #{@app_name}").should == "Environment variable(s) removed"
        
          list = run_command("env --app #{@app_name}")
          list.should_not match('env2')
          list.should_not match('env3')
        end
      
        it "should require confirmation to clear env vars" do
          run_command("env clear --app #{@app_name} 2>&1").should match("command requires confirmation")
        end
      
        it "should clear env vars" do
          run_command("env clear --app #{@app_name} --confirm").should match("Environment variables cleared")
          list = run_command("env --app #{@app_name}")
          list.should be_empty
        end
      end
      
      
      describe "for Ruby apps" do
        it "should start a console session" do
          result = `expect #{File.dirname(__FILE__)}/console_test.expect #{@app_name} "puts 'console test'"`.gsub("\r", '')
          expected = <<-END.gsub(/^ {12}/, '').gsub("\r", '')
            spawn duostack console --app #{@app_name}
            Connecting to Ruby console for #{@app_name}...
            >> puts 'console test'
            console test
            => nil
            >> exit
            Connection to duostack.net closed.
          END
          
          result.should match(expected)
        end
        
        it "should run rake tasks" do
          run_command("rake -T --app #{@app_name}").should match('rake about')
        end
      end
    end
  
  end
  
  
  describe "cleanup commands" do
    it "should allow app deletion" do
      # cd first so that remote will be removed
      result = `cd #{@app_path} && #{build_command("destroy --app")} #{@app_name} --confirm`
      result.should match("App destroyed")
    end
    
    it "should not have deleted app in list" do
      run_command("list").should_not match(@app_name)
    end
    
    it "should clean up duostack git remote" do
      result = `cd #{@app_path} && git remote`.chomp
      result.should_not include('duostack')
    end
  end
  
end