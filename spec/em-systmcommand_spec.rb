require 'spec_helper'

describe EM::SystemCommand do

  it 'should take a success callback' do
    called = false
    EM.run do
      EM::SystemCommand.new 'echo "123"; exit 0;' do |on|
        on.success do |ps|
          called = true
        end
      end

      EM.assertions do
        called.should == true
      end
    end
  end

  it 'should take a failure callback' do
    called = false
    EM.run do
      EM::SystemCommand.new 'echo "123"; exit 1;' do |on|
        on.failure do |ps|
          called = true
        end
      end

      EM.assertions do
        called.should == true
      end
    end
  end

  it 'should have stdin pipe' do
    EM.run do
      ps = EM::SystemCommand.new 'echo "123"; exit 1;'
      ps.stdin.should be_a EM::SystemCommand::Pipe
      EM.stop_event_loop
    end
  end

  it 'should have stdout pipe' do
    EM.run do
      ps = EM::SystemCommand.new 'echo "123"; exit 1;'
      ps.stdout.should be_a EM::SystemCommand::Pipe
      EM.stop_event_loop
    end
  end

  it 'should have stderr pipe' do
    EM.run do
      ps = EM::SystemCommand.new 'echo "123"; exit 1;'
      ps.stderr.should be_a EM::SystemCommand::Pipe
      EM.stop_event_loop
    end
  end

end
