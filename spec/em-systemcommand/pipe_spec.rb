require 'spec_helper'

describe 'Pipe' do
  context 'parsing' do
    it 'should handle carriage returns' do
      cmd = EM::SystemCommand.new 'exit 0;'
      pipe = EM::SystemCommand::Pipe.new(nil, cmd, :stdout)
      pipe.receive_data "test\n"
      pipe.receive_data "       32768   0%    0.00kB/s    0:00:00\r"
      pipe.receive_data "   131235840  12%  125.12MB/s    0:00:06\r"
      pipe.receive_data "   261619712  25%  124.80MB/s    0:00:05\r"
      pipe.receive_data "   391544832  38%  124.54MB/s    0:00:04\r"
      pipe.receive_data "   522616832  51%  124.69MB/s    0:00:03\r"
      pipe.receive_data "   652738560  63%  124.43MB/s    0:00:02\r"
      pipe.receive_data "   783056896  76%  124.41MB/s    0:00:01\r"
      pipe.receive_data "   906657792  88%  122.90MB/s    0:00:00\r"
      pipe.receive_data "  1024000000 100%  123.67MB/s    0:00:07 (xfer#1, to-check=0/1)\n"
      pipe.receive_data "\n"
      pipe.receive_data "sent 1024125065 bytes  received 31 bytes  120485305.41 bytes/sec\ntotal size is 1024000000  speedup is 1.00\n"
      pipe.output.should == "test\n  1024000000 100%  123.67MB/s    0:00:07 (xfer#1, to-check=0/1)\n\nsent 1024125065 bytes  received 31 bytes  120485305.41 bytes/sec\ntotal size is 1024000000  speedup is 1.00\n"
    end
  end

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

    it 'should be called on carriage return' do
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
          on.stdout.match(/-([0-9]+)-/, in: :line) do |number|
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
          on.stdout.match(/-([0-9]+)-/, in: :output) do |number|
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
          on.stdout.match(/-([0-9]+)-/, match: :last, in: :output) do |number|
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
