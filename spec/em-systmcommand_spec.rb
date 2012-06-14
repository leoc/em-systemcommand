require 'spec_helper'

describe EM::SystemCommand do

  it 'should call a success callback when process succeeds'  do
    called = false
    EM.run do
      EM::SystemCommand.execute 'exit 0;' do |on|
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
      EM::SystemCommand.execute 'exit 0;' do |on|
        on.success do |ps|
          EM.stop_event_loop
          ps.should be_a EM::SystemCommand
        end

        on.failure do |ps|
          EM.stop_event_loop
        end
      end
    end
  end

  it 'should call a failure callback when process fails' do
    called = false
    EM.run do
      EM::SystemCommand.execute 'echo "123"; exit 1;' do |on|
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
      EM::SystemCommand.execute 'exit 1;' do |on|
        on.failure do |ps|
          EM.stop_event_loop
          ps.should be_a EM::SystemCommand
        end
      end
    end
  end

  it 'should have stdin pipe' do
    EM.run do
      ps = EM::SystemCommand.execute 'echo "123"; exit 1;'
      ps.stdin.should be_a EM::SystemCommand::Pipe
      EM.stop_event_loop
    end
  end

  it 'should have stdout pipe' do
    EM.run do
      ps = EM::SystemCommand.execute 'echo "123"; exit 1;'
      ps.stdout.should be_a EM::SystemCommand::Pipe
      EM.stop_event_loop
    end
  end

  it 'should have stderr pipe' do
    EM.run do
      ps = EM::SystemCommand.execute 'echo "123"; exit 1;'
      ps.stderr.should be_a EM::SystemCommand::Pipe
      EM.stop_event_loop
    end
  end

  it 'should proxy builder commands' do
    EM.run do
      cmd = EM::SystemCommand.new 'echo'
      cmd << '-n'
      cmd.add 'Something\n'
      cmd.execute
      EM.stop_event_loop
    end
  end


  describe 'subclass' do
    before :all do
      class DummyCmd < EM::SystemCommand;end
    end

    it 'should have default handlers' do
      DummyCmd.pipe_handlers.should == {
        stdin:  EM::SystemCommand::Pipe,
        stdout: EM::SystemCommand::Pipe,
        stderr: EM::SystemCommand::Pipe
      }
    end
  end

  it 'should pass multiple command executions' do
    counter = 0
    EM.run do
      2.times do
        EM::SystemCommand.execute 'ls' do |on|
          on.success do
            2.times do
              EM::SystemCommand.execute 'ls' do |on2|
                on2.success do
                  if counter >= 3
                    EM.stop_event_loop
                  else
                    counter += 1
                  end
                end

                on2.failure do
                  if counter >= 3
                    EM.stop_event_loop
                  else
                    counter += 1
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
