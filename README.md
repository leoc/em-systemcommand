# EM::SystemCommand

`EM::SystemCommand` is an `popen3` abstraction for eventmachine to easily create subprocesses with eventmachine.
The goal is to provide an easy way to invoke system commands and to read and handle their outputs. When creating an 
`EM::SystemCommand` object its basically like a popen. It has `#stdin`, `#stdout` and `#stderr`.
Which are related to `EM::Connection`.

## Installation

Add this line to your application's Gemfile:

    gem 'em-systemcommand'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install em-systemcommand

## Usage

To simply run a process you can instatiate an `EM::SystemCommand`
object and set up the callbacks in the yielded block.

    EM.run do
      EM::SystemCommand.execute 'my_command' do |on|
        on.success do |ps|
          puts "Success!"
        end
        
        on.failure do |ps|
          puts "Failure with status #{ps.status.exitstatus}"
        end
      end
    end
    
When you want to retreive output, you can use the methods
`#update`, `#line` and `#data` on a pipe object like so:

    EM.run do
      EM::SystemCommand.execute 'my_command' do |on|
        on.success do |ps|
          puts "Success!"
        end
        
        on.stdout.data do |data|
          puts "Data: #{data}"
        end
        
        on.stdout.line do |line|
          puts "Line: #{line}"
        end
        
        # `#output` gets the whole output buffer.
        # This means, it has theoretically the screen you´d get when
        # invoking the command in the shell. Although only \r is used.
        on.stdout.update do |output|
          puts output
        end
      end
    end

`Pipe` objects even have a nice convenient method `#match` which lets
you match output against a regular expression:

    EM.run do
      EM::SystemCommand.execute 'echo "25%\n"; sleep 1; echo "50%\n"; sleep 1; echo "75%\n"; sleep 1; echo "100%\n"; exit 0;' do |on|
        on.success do |ps|
          puts "Success!"
        end
        .
        on.stdout.match /([0-9]+)%/, in: :line do |match, progress|
          puts "Percentage: #{progress}"
        end
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Added some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
