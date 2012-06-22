# -*- coding: utf-8 -*-
require 'spec_helper'

describe EM::SystemCommand::Builder do
  before :all do
    @cmd = EM::SystemCommand::Builder.new 'ffmpeg'
  end

  describe '.new' do
    it 'should take multiple arguments' do
      b = EM::SystemCommand::Builder.new 'echo', 'Irgendwas'
      b.to_s.should == 'echo Irgendwas'
    end
  end


  describe '#add' do
    before :each do
      @cmd = EM::SystemCommand::Builder.new 'echo'
    end

    it 'should add options' do
      @cmd << :n
      @cmd.to_s.should == 'echo -n'
    end

    it 'should add parameters' do
      @cmd.add :creative, 'not'
      @cmd.add :a, 'b'
      @cmd.add '--something', 'weird$'
      @cmd.to_s.should == "echo --creative=not -a b --something='weird$'"
    end

    it 'should add arguments' do
      @cmd << "A long text. It´s got some $pecial Characters like \" or '. Yeah, so be it"
      @cmd.to_s.should == "echo 'A long text. It´s got some $pecial Characters like \" or '\\''. Yeah, so be it'"
    end

    it 'should add an array' do
      @cmd << [
               [:foo, 'bar'],
               '-a',
               :b,
               'Something'
              ]
      @cmd.to_s.should == 'echo --foo=bar -a -b Something'
    end

    it 'should be chainable' do
      @cmd << :p << 'Something else'
      @cmd.to_s.should == "echo -p 'Something else'"
    end
  end

  describe '#to_s' do
    it 'should stay the same' do
      builder = EM::SystemCommand::Builder.new('echo', 'Irgendwas"$')
      builder.to_s.should == "echo 'Irgendwas\"$'"
      builder.to_s.should == "echo 'Irgendwas\"$'"
      builder.to_s.should == "echo 'Irgendwas\"$'"
    end

    it 'should escape argument strings' do
      EM::SystemCommand::Builder.new('echo', 'Irgendwas"$').to_s.
        should == "echo 'Irgendwas\"$'"
    end

    it 'should not escape symbol options' do
      EM::SystemCommand::Builder.new('echo', :n, 'Irgendwas"$').to_s.
        should == "echo -n 'Irgendwas\"$'"
    end

    it 'should not escape symbol long parameter names' do
      EM::SystemCommand::Builder.new('echo', [:creative, 'not$'], 'Irgendwas"$').to_s.
        should == "echo --creative='not$' 'Irgendwas\"$'"
    end

    it 'should not escape symbol short parameter names' do
      EM::SystemCommand::Builder.new('echo', [:a, 'not$'], 'Irgendwas"$').to_s.
        should == "echo -a 'not$' 'Irgendwas\"$'"
    end

    it 'should not escape long parameters' do
      EM::SystemCommand::Builder.new('echo', ['--creative', 'not$'], 'Irgendwas"$').to_s.
        should == "echo --creative='not$' 'Irgendwas\"$'"
    end

    it 'should not escape short parameters' do
      EM::SystemCommand::Builder.new('echo', ['-a', 'not$'], 'Irgendwas"$').to_s.
        should == "echo -a 'not$' 'Irgendwas\"$'"
    end

    it 'should not escape arguments' do
      EM::SystemCommand::Builder.new('echo', '-n', 'Irgendwas"$').to_s.
        should == "echo -n 'Irgendwas\"$'"
    end
  end
end
