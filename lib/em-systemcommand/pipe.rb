# -*- coding: utf-8 -*-
module EventMachine
  class SystemCommand
    class Pipe < EM::Connection

      def initialize master, name
        @master             = master
        @name               = name
        @master.pipes[name] = self
        begin
          @outputbuffer     = StringIO.new
        rescue Exception => e
          puts "Uninitialized constant StringIO. This may happen when you forgot to use bundler. Use `bundle exec`."
        end
      end

      ##
      # The content of the output buffer as string.
      #
      # @return [String] The connections output
      def output
        @outputbuffer.string
      end

      ##
      # Convenience method to create a callback that matches a regular
      # expression
      #
      # @param [Regexp] regexp The regular expression that should be matched
      # @option opt [Symbol] :in Match either in `:line` or `:output`
      # @option opt [Symbol] :match Match either `:first` or `:last`
      def match regexp, opt = {}, &block
        opt = { in: :line, match: :first }.merge opt
        (opt[:in] == :output ? receive_update_callbacks : receive_line_callbacks) << lambda do |data|
          matches = data.scan regexp
          if matches.length > 0
            case opt[:match]
            when :first
              EM.next_tick do
                block.call *matches[0]
              end
            when :last
              EM.next_tick do
                block.call *matches[matches.length-1]
              end
            end
          end
        end
      end

      ##
      # Invoked when line was received
      #
      # @param [String] line The line that´s received
      def receive_line line
        receive_line_callbacks.each do |callback|
          EM.next_tick do
            callback.call line.dup
          end
        end
      end

      ##
      # Adds a callback for `receive_line` events.
      #
      # @yield The callback that should be added to callback array for line events
      # @yieldparam [String] line The line that has been received
      def line &block
        receive_line_callbacks << block
      end

      ##
      # Invoked when a line was written, but `\r` was received without
      # a line-break in the end.
      #
      # @param [String] buffer The complete buffer content of this connection
      def receive_update buffer
        receive_update_callbacks.each do |callback|
          EM.next_tick do
            callback.call buffer.dup
          end
        end
      end

      ##
      # Adds a callback for `receive_update` events.
      #
      # @yield The callback that should be added to callback array for update events
      # @yieldparam [String] buffer The complete buffer content of this connection
      def update &block
        receive_update_callbacks << block
      end

      ##
      # Invoked when data was received.
      #
      # @param [String] data The received data
      def receive_data data, recursive = false
        # if recursive is true we already invoked the receive data callbacks!
        unless recursive
          receive_data_callbacks.each do |callback|
            EM.next_tick do
              callback.call data.dup
            end
          end
        end
        @linebuffer ||= []
        @lf_offset  ||= 0

        parse_crlf data

        receive_update @outputbuffer.string unless recursive
      end

      ##
      # Parses carriage return when data is received.
      #
      # @param [String] data The received data
      # @param [Integer] ix The index of the carriage return
      def parse_cr data, ix
        ln = (@linebuffer << data[0...ix]).join
        @linebuffer.clear

        receive_line ln
        @outputbuffer.print ln

        # jump back to the last line feed
        @outputbuffer.pos = @lf_offset

        # parse rest of the data
        parse_crlf data[(ix+1)..-1]
      end

      ##
      # Parses line feed when data is received.
      #
      # @param [String] data The received data
      # @param [Integer] ix The index of the line feed
      def parse_lf data, ix
        ln = (@linebuffer << data[0...ix]).join
        @linebuffer.clear
        ln.chomp!

        receive_line ln
        @outputbuffer.print ln

        # jump to the end of the buffer to keep the characters, that
        # may already have been written
        @outputbuffer.pos = @outputbuffer.length
        # print the line feed
        @outputbuffer.puts
        # set last line feed to the current cursor position, so we
        # know where we have to jump back, when a carriage return occurs
        @lf_offset = @outputbuffer.pos

        # parse rest of the data
        parse_crlf data[(ix+1)..-1]
      end

      ##
      # Parse received data for line feeds or carriage returns.
      #
      # @param [String] data The received data
      def parse_crlf data
        return if data == ''
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
            # @outputbuffer.print data
          end
        end
      end

      ##
      # Adds a callback for `receive_data` events.
      #
      # @yield The callback that´s to be added to the data callback array
      # @yieldparam [String] data The data that´s received
      def data &block
        receive_data_callbacks << block
      end

      ##
      # Close the attached IO object.
      def close
        begin
          @io.close unless @io.closed?
        rescue Exception => e
          # ignore errors, when the io object might be closed already
        ensure
          detach
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
