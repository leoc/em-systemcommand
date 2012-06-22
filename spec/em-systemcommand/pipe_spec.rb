require 'spec_helper'

describe 'Pipe' do

  context '#receive_data' do
    it 'should correctly do a carriage return in the output buffer' do
      EM.run do
        EM::SystemCommand.execute %q{ruby -e '$stdout.sync = true; print "12345\r"; puts "321"; print "123"; print "\r3210"; exit 0;'} do |on|
          on.success do |process|
            EM.stop_event_loop
            process.stdout.output.should == "32145\n3210"
          end
        end
      end
    end
  end

  context '#data callback' do

    it 'should be called on data' do
      received = []
      EM.run do
        EM::SystemCommand.execute %q{echo -n "123123";} do |on|
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
        EM::SystemCommand.execute %Q{echo "123\n456"} do |on|
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
        EM::SystemCommand.execute 'echo "123"; echo "456"' do |on|
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
        EM::SystemCommand.execute %q{ruby -e '$stdout.sync = true; print "123\r"; print "456\r"; exit 0;'} do |on|
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
        EM::SystemCommand.execute %q{ruby -e '$stdout.sync = true; puts "123"; puts "456"; exit 0'} do |on|
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
        EM::SystemCommand.execute %q{ruby -e '$stdout.sync = true; print "123\r"; sleep 0.1; print "456\r"; exit 0;'} do |on|
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
        EM::SystemCommand.execute 'echo "-123-"; echo "-456-"' do |on|
          on.stdout.match /-([0-9]+)-/, in: :line do |number|
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
        EM::SystemCommand.execute %q{ruby -e '$stdout.sync = true; print "-123-\r"; sleep 0.1; print "-456-\r"; exit 0'} do |on|
          on.stdout.match /-([0-9]+)-/, in: :output do |number|
            received << number
          end

          on.success do
            EM.stop_event_loop
            received.should == ["123","456"]
          end
        end
      end
    end

    it 'should match last occurence on receive_update' do
      received = []
      EM.run do
        EM::SystemCommand.execute %q{ruby -e '$stdout.sync = true; print "-123-\n"; sleep 0.1; print "-456-\n"; exit 0'} do |on|
          on.stdout.match /-([0-9]+)-/, match: :last, in: :output do |number|
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
