require 'spec_helper'

describe EM::SystemCommand do

  it 'should call a success callback when process succeeds' do
    called = false
    EM.run do
      EM::SystemCommand.new 'exit 0;' do |on|
        on.success do |ps|
          called = true
        end
      end

      EM.assertions do
        called.should == true
      end
    end
  end

  it 'should take a success callback with process as parameter' do
    EM.run do
      EM::SystemCommand.new 'exit 0;' do |on|
        on.success do |ps|
          EM.stop_event_loop
          ps.should be_a EM::SystemCommand
        end
      end
    end
  end

  it 'should call a failure callback when process fails' do
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

  it 'should take a failure callback with process as parameter' do
    EM.run do
      EM::SystemCommand.new 'exit 1;' do |on|
        on.failure do |ps|
          EM.stop_event_loop
          ps.should be_a EM::SystemCommand
        end
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
