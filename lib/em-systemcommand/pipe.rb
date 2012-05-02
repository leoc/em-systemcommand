module EventMachine
  class SystemCommand
    class Pipe < EM::Connection

      def initialize(master, name)
        @master             = master
        @name               = name
        @master.pipes[name] = self
        begin
          @outputbuffer     = StringIO.new()
        rescue Exception => e
          puts "Uninitialized constant StringIO. This may happen when you forgot to use bundler. Use `bundle exec`."
        end
      end

      def output
        @outputbuffer.string
      end

      # Convenience method to create a callback that matches a regular expression
      def match regexp, opt = {}, &block
        opt = { in: :line }.merge opt
        (opt[:in] == :output ? receive_update_callbacks : receive_line_callbacks) << lambda do |data|
          if m = data.match(regexp)
            block.call m.to_a
          end
        end
      end

      # Invoked when line was received
      def receive_line line
        receive_line_callbacks.each do |callback|
          callback.call line
        end
      end

      # Adds a callback for `receive_line` events.
      def line &block
        receive_line_callbacks << block
      end

      # Invoked when a line was written, but `\r` was received without
      # a line-break in the end.
      def receive_update line
        receive_update_callbacks.each do |callback|
          callback.call line
        end
      end

      # Adds a callback for `receive_update` events.
      def update &block
        receive_update_callbacks << block
      end

      # Invoked when data was received.
      def receive_data data
        receive_data_callbacks.each do |callback|
          callback.call data
        end

        @lt2_linebuffer ||= []

        ix = data.index("\r")
        if ix and data[ix+1] != "\n"
          @lt2_linebuffer << data[0...ix]
          ln = @lt2_linebuffer.join
          @lt2_linebuffer.clear
          @outputbuffer.print ln
          @outputbuffer.pos -= ln.length
          receive_line ln
          receive_update @outputbuffer.string
          receive_data data[(ix+1)..-1] # receive rest data
        elsif ix = data.index("\n")
          @lt2_linebuffer << data[0...ix]
          ln = @lt2_linebuffer.join
          @lt2_linebuffer.clear
          ln.chomp!
          @outputbuffer.puts ln
          receive_line ln
          receive_update @outputbuffer.string
          receive_data data[(ix+1)..-1] # receive rest data
        else
          @lt2_linebuffer << data
        end
      end

      # Adds a callback for `receive_data` events.
      def data &block
        receive_data_callbacks << block
      end

      # Close the attached IO object.
      def close
        begin
          @io.close unless @io.closed?
        rescue Exception => e
          # ignore errors, when the io object might be closed already
        end
      end

      # Invoked when the connection is terminated. Calls
      # `unbind(@name)` on master.
      def unbind
        self.close
        @master.unbind(@name)
      end

      private
      def receive_line_callbacks
        @receive_line_callbacks ||= []
      end

      def receive_update_callbacks
        @receive_update_callbacks ||= []
      end

      def receive_data_callbacks
        @receive_data_callbacks ||= []
      end
    end
  end
end
