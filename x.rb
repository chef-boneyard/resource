require 'chef_cluster'

describe 'My Awesome Hello World Application' do
  context "With a single-node chef server" do
    before :all { ChefCluster.converge }

    let(:frontend_ip) { ChefCluster.machines['load_balancer'].ip_address }

    it "Returns Hello World" do
      HTTP.get("https://#{frontend_ip}").should == "Hello World"
    end

    it "Returns Hello World even if a machine goes down" do
      ChefCluster.machine['web1'].stop
      1.upto(50) do
        HTTP.get("https://#{frontend_ip}").should == "Hello World"
      end
    end

    it "Succeeds when running serverspec on web1" do
      ChefCluster.machine['web1'].execute("serverspec /cookbooks/mycookbook").return_code.should == 1
    end

    context "When the web servers have concurrent threads set to 1" do
      before :all { ChefCluster.machines['web1'].upload('config.txt', 'concurrent_threads=1') }
    end

    # Stress test
    # Selenium test
  end
  
  context "In-progress upgrade tests" do
    before :all { ChefCluster.converge(version: 1) }
    it "If half the servers are version 1 and half are version 2, it still succeeds" do
      ChefCluster.converge(machine: 'web1', version: 2)
      # do a full test that everything works
      ChefCluster.converge(version: 2)
      # do a full test again to make sure it still works
    end
  end

  context "Full upgrade test" do
    before :all { ChefCluster.converge(version: 1) }
    context "With a bunch of data in the server that we know about" do
      before :each { chef_rest.post('/data/x/y', '{ "x": "y" }') }
      context "And an upgrade AFTER the data is in the server" do
        before :each { ChefCluster.converge(version: 2) }
        it "Still has all the data" do
          chef_rest.get('/data/x/y').should == '{ "x": "y" }'
        end
      end
    end
  end

  context "With a multi-frontend chef server" do
    before :all { ChefCluster.converge('multi_frontend') }
  end

  context "With an HA chef server" do
    before :all { ChefCluster.converge('ha') }
    it_behaves_like "a normal chef server"
  end
end
