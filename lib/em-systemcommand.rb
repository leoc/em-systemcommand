require 'open3'

require "em-systemcommand/version"

require "em-systemcommand/pipe"
require "em-systemcommand/pipe_handler"

module EventMachine
  class SystemCommand
    include EM::SystemCommand::PipeHandler
    include EM::Deferrable

    pipe_handler :stdin,  EM::SystemCommand::Pipe
    pipe_handler :stdout, EM::SystemCommand::Pipe
    pipe_handler :stderr, EM::SystemCommand::Pipe

    attr_accessor :pipes, :stdin, :stdout, :stderr

    def initialize *arguments

      @pipes = {}

      stdin, stdout, stderr, @wait_thr = Open3.popen3(*arguments)

      @stdin  = attach_pipe_handler :stdin, stdin
      @stdout = attach_pipe_handler :stdout, stdout
      @stderr = attach_pipe_handler :stderr, stderr

      yield self if block_given?

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
