module EventMachine
  class SystemCommand
    module PipeHandler
      def self.included(base)
        base.extend(ClassMethods)
      end

      def attach_pipe_handler name, io_object
        EM.attach(io_object, pipe_handler_class(name), self, name)
      end

      def pipe_handler_class name
        self.class.pipe_handlers[name]
      end

      module ClassMethods

        def pipe_handler name, klass
          pipe_handlers[name] = klass
        end

        def pipe_handler_class name
          pipe_handlers[name]
        end

        def pipe_handlers
          @pipe_handlers ||= {
            stdin:  EM::SystemCommand::Pipe,
            stdout: EM::SystemCommand::Pipe,
            stderr: EM::SystemCommand::Pipe
          }
        end

      end
    end
  end
end
