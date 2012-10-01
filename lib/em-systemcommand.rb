require 'posix/spawn'

require "em-systemcommand/version"
require "em-systemcommand/pipe"
require "em-systemcommand/pipe_handler"
require "em-systemcommand/builder"

module EventMachine
  class SystemCommand
    include EM::SystemCommand::PipeHandler
    include EM::Deferrable
    extend Forwardable

    def_delegators :@command, :<<, :add

    pipe_handler :stdin,  EM::SystemCommand::Pipe
    pipe_handler :stdout, EM::SystemCommand::Pipe
    pipe_handler :stderr, EM::SystemCommand::Pipe

    attr_accessor :pipes, :stdin, :stdout, :stderr

    ##
    # Prepares a `SystemCommand` object.
    #
    # An easy way is to use the `Builder` idea:
    #
    #     cmd = EM::SystemCommand.new 'echo'
    #     cmd << :n
    #     cmd << 'Some text to put out.'
    #     cmd.execute do |on|
    #       on.success do
    #         puts 'Yay!'
    #       end
    #     end
    #
    def initialize *args, &block
      @pipes = {}
      @command = EM::SystemCommand::Builder.new *args

      @execution_proc = block
    end

    ##
    # Convinience method to quickly execute a command.
    def self.execute *args, &block
      sys_cmd = EM::SystemCommand.new *args, &block
      sys_cmd.execute
    end

    ##
    # Get the command string from the builder object.
    #
    # @return [String] The command string
    def command
      @command.to_s
    end

    ##
    # Executes the command from the `Builder` object.
    # If there had been given a block at instantiation it will be
    # called after the `popen3` call and after the pipes have been
    # attached.
    def execute &block
      raise 'Previous process still exists' unless pipes.empty?

      # clear callbacks
      @callbacks = []
      @errbacks = []

      pid, stdin, stdout, stderr = POSIX::Spawn.popen4 @command.to_s

      @pid = pid
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

    ##
    # Returns the command string.
    def command
      @command.to_s
    end

    ##
    # Returns the pid of the child process.
    def pid
      @pid
    end

    ##
    # Returns the status object of the popen4 call.
    def status
      @status ||= Process.waitpid2(pid)[1]
    end

    alias_method :success, :callback
    alias_method :failure, :errback

    ##
    # Called by child pipes when they get unbound.
    def unbind name
      pipes.delete name
      if pipes.empty?
        exit_callbacks.each do |cb|
          EM.next_tick do
            cb.call status
          end
        end
        if status.exitstatus == 0
          EM.next_tick do
            succeed self
          end
        else
          EM.next_tick do
            fail self
          end
        end
      end
    end

    ##
    # Kills the child process.
    def kill signal = 'TERM', wait = false
      Process.kill signal, self.pid
      val = status if wait
      @stdin.close
      @stdout.close
      @stderr.close
      val
    end

    ##
    # A method to add a callback for when the process unbinds.
    def exit &block
      exit_callbacks << block
    end

    ##
    # An array of exit callbacks, being called with `status` as
    # parameter when the process is unbound.
    def exit_callbacks
      @exit_callbacks ||= []
    end
  end
end
