require 'escape'

module EventMachine
  class SystemCommand
    class Builder

      def initialize *args
        unless args.length > 0
          raise "You have to provide at least one argument as command"
        end
        @arr = args
      end

      def add opt, val = nil
        if opt.is_a?(Array)
          opt.each do |element|
            add *element
          end
        else
          if val
            @arr << [ opt, val ]
          else
            @arr << opt
          end
        end
        self
      end
      alias :<< :add

      ##
      # Returns the command string
      def to_s
        cmd = ''
        @arr.each do |arg|
          if arg == @arr.first
            cmd << arg
          elsif arg.is_a?(Array)
            param = arg.shift
            param = param.to_s if param.is_a?(Symbol)
            if param =~ /^\-{1,2}(.*)/
              param = $1
            end
            value = arg.shift
            if param.length == 1
              cmd << ' ' << "-#{param} #{Escape.shell_single_word(value)}"
            else
              cmd << ' ' << "--#{param}=#{Escape.shell_single_word(value)}"
            end
          elsif arg.is_a?(Symbol)
            arg = arg.to_s
            if arg.length == 1
              cmd << ' ' << "-#{arg}"
            else
              cmd << ' ' << "--#{arg}"
            end
          elsif arg.strip =~ /^\-/
            cmd << ' ' << arg
          else
            cmd << ' ' << Escape.shell_single_word(arg)
          end
        end
        cmd
      end

    end
  end
end
