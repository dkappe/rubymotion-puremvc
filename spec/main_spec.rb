describe "Initialize the facade in two threads" do
  class MyFacade < Facade
    def initialize
      super
      puts "in init"
    end
  end

  it "singleton facade" do
    @facade = nil
    @facade2 = nil

    Dispatch::Queue.concurrent.async do
      sleep 2
      @facade = MyFacade.instance
      @facade.should.not == nil
      puts "Did facade"
    end

    Dispatch::Queue.concurrent.async do
      sleep 1
      @facade2 = MyFacade.instance
      @facade2.should.not == nil
      puts "Did facade2"
    end

    wait 5 do

      @facade.should.not == nil
      @facade.should == @facade2
    end
  end
end
