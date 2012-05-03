require 'spec_helper'

describe 'Pipe' do

  context '#data callback' do

    it 'should be called on data' do
      received = []
      EM.run do
        EM::SystemCommand.new %q{echo -n "123123";} do |on|
          on.stdout.data do |data|
            received << data
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123123"]
          end
        end
      end
    end

    it 'should be called once even when there is a linebreak' do
      received = []
      EM.run do
        EM::SystemCommand.new %Q{echo "123\n456"} do |on|
          on.stdout.data do |data|
            received << data
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123\n456\n"]
          end
        end
      end
    end
  end

  context '#line callback' do

    it 'should be called on readline' do
      received = []
      EM.run do
        EM::SystemCommand.new 'echo "123"; echo "456"' do |on|
          on.stdout.line do |data|
            received << data
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123","456"]
          end
        end
      end
    end

    it 'should be called on carriage return' do
      received = []
      EM.run do
        EM::SystemCommand.new "echo -n \"123\r\"; echo -n \"456\r\"" do |on|
          on.stdout.line do |data|
            received << data
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123","456"]
          end
        end
      end
    end

  end

  context '#update callback' do

    it 'should be called on receive data' do
      received = []
      EM.run do
        EM::SystemCommand.new %q{ruby -e '$stdout.sync = true; puts "123"; puts "456"; exit 0'} do |on|
          on.stdout.update do |data|
            received << data
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123\n456\n"]
          end
        end
      end
    end

    it 'should be called on carriage return'do
      received = []
      EM.run do
        EM::SystemCommand.new %q{ruby -e '$stdout.sync = true; print "123\r"; print "456\r"; exit 0;'} do |on|
          on.stdout.update do |data|
            received << data
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123","456"]
          end
        end
      end
    end

  end

  context '#match callback' do

    it 'should match in lines on receive_line' do
      received = []
      EM.run do
        EM::SystemCommand.new 'echo "-123-"; echo "-456-"' do |on|
          on.stdout.match /-([0-9]+)-/, in: :line do |match, number|
            received << number
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123","456"]
          end
        end
      end
    end

    it 'should match in output buffer on receive_update' do
      received = []
      EM.run do
        EM::SystemCommand.new %q{ruby -e '$stdout.sync = true; print "-123-\r"; print "-456-\r"; exit 0'} do |on|
          on.stdout.match /-([0-9]+)-/, in: :output do |match, number|
            received << number
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123","456"]
          end
        end
      end
    end
  end
end
