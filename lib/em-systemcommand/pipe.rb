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

      ##
      # Convenience method to create a callback that matches a regular
      # expression
      def match regexp, opt = {}, &block
        opt = { in: :line, match: :first }.merge opt
        (opt[:in] == :output ? receive_update_callbacks : receive_line_callbacks) << lambda do |data|
          matches = data.scan regexp
          if matches.length > 0
            case opt[:match]
            when :first
              block.call *matches[0]
            when :last
              block.call *matches[matches.length-1]
            end
          end
        end
      end

      # Invoked when line was received
      def receive_line line
        receive_line_callbacks.each do |callback|
          callback.call line.dup
        end
      end

      # Adds a callback for `receive_line` events.
      def line &block
        receive_line_callbacks << block
      end

      # Invoked when a line was written, but `\r` was received without
      # a line-break in the end.
      def receive_update buffer
        receive_update_callbacks.each do |callback|
          callback.call buffer.dup
        end
      end

      # Adds a callback for `receive_update` events.
      def update &block
        receive_update_callbacks << block
      end

      # Invoked when data was received.
      def receive_data data, recursive = false
        unless recursive
          receive_data_callbacks.each do |callback|
            callback.call data.dup
          end
        end
        @linebuffer ||= []
        @cr_offset    = 0

        parse_crlf data

        receive_update @outputbuffer.string unless recursive
      end

      def parse_cr data, ix
        ln = (@linebuffer << data[0...ix]).join
        @linebuffer.clear
        receive_line ln
        @outputbuffer.print ln
        @outputbuffer.pos = @cr_offset
        parse_crlf data[(ix+1)..-1] # receive rest data
      end

      def parse_lf data, ix
        ln = (@linebuffer << data[0...ix]).join
        @linebuffer.clear
        ln.chomp!
        receive_line ln
        @outputbuffer.print ln
        @outputbuffer.pos = @outputbuffer.length
        @outputbuffer.puts
        @cr_offset = @outputbuffer.pos
        parse_crlf data[(ix+1)..-1] # receive rest data
      end

      def parse_crlf data
        if ilf = data.index("\n")
          # if we find a LF and that LF is after a CR we first handle
          # the CR
          if icr = data.index("\r") and ilf != (icr+1) and icr < ilf
            parse_cr data, icr
          else
            parse_lf data, ilf
          end
        else
          if icr = data.index("\r")
            parse_cr data, icr
          else
            @linebuffer << data
            @outputbuffer.print data
          end
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
          detach
        rescue Exception => e
          # ignore errors, when the io object might be closed already
        end
      end

      ##
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
