require 'open3'

require "em-systemcommand/version"
require "em-systemcommand/pipe"
require "em-systemcommand/pipe_handler"
require "em-systemcommand/builder"

module EventMachine
  class SystemCommand
    include EM::SystemCommand::PipeHandler
    include EM::Deferrable

    pipe_handler :stdin,  EM::SystemCommand::Pipe
    pipe_handler :stdout, EM::SystemCommand::Pipe
    pipe_handler :stderr, EM::SystemCommand::Pipe

    attr_accessor :pipes, :stdin, :stdout, :stderr

    def initialize *args, &block
      @pipes = {}
      @command = EM::SystemCommand::Builder.new *args

      @execution_proc = block
    end

    def self.execute *args, &block
      sys_cmd = EM::SystemCommand.new *args, &block
      sys_cmd.execute
    end

    # Executes the command
    def execute &block
      raise 'Previous process still exists' unless pipes.empty?

      # clear callbacks
      @callbacks = []
      @errbacks = []

      stdin, stdout, stderr, @wait_thr = Open3.popen3 @command.to_s

      @stdin  = attach_pipe_handler :stdin, stdin
      @stdout = attach_pipe_handler :stdout, stdout
      @stderr = attach_pipe_handler :stderr, stderr

      if block
        block.call self
      elsif @execution_proc
        @execution_proc.call self
      end
      self
    end

    def pid
      @wait_thr.pid
    end

    def status
      @wait_thr.value
    end

    alias_method :success, :callback
    alias_method :failure, :errback

    def unbind name
      pipes.delete name
      if pipes.empty?
        if status.exitstatus == 0
          succeed self
        else
          fail self
        end
      end
    end

    def kill signal = 'TERM', wait = false
      Process.kill signal, self.pid
      val = status if wait
      @stdin.close
      @stdout.close
      @stderr.close
      val
    end

  end
end
