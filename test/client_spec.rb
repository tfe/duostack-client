require File.dirname(__FILE__) + '/support'

describe "Duostack client" do
  
  before(:all) do
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
    
    it "should clean up duostack git remote" do
      result = `cd #{@app_path} && git remote`.chomp
      result.should_not include('duostack')
    end
  end
  
end