# encoding: utf-8

# You can find all the meta magic added to the resource within this file
require './introspection/libraries/meta'

class Inspec::Resources::Cmd
  # NOTE: this is monkey-patched in already but to ensure we override the initialize
  include MetaDefinition

  # initialize has been replaced with one defined in the MetaDefinition 
  #   when the Module#included event fires. It's a workaround because
  #   I believe the initialize should be replaced with a more operations
  #   focused around the resource arguments

  resource_parameter 'cmd', type: [:to_s], required: true, is_identifier: true do |cmd|
    # TODO: type validation could be done automatically based on the type value or respond_to if one has been defined.
    # TODO: type validation could also have a block provided to perform these operations
    # TODO: given that there is a block to validate the incoming arg then the assignment 
    #   to ivar could be automatic when no block is provided ; assuming the parameter
    #   name and ivar name align.
    if cmd.nil?
      raise 'InSpec `command` was called with `nil` as the argument. This is not supported. Please provide a valid command instead.'
    end
    @command = cmd
  end
  
  resource_parameter 'options', type: Hash, required: false, is_identifier: false do |options|
    # TODO: type validation could be done automatically based on the type value or respond_to if one has been defined.
    # TODO: default values could be used instead of explictly stating required false
    default_options = {}
    options ||= default_options

    if options[:redact_regex]
      unless options[:redact_regex].is_a?(Regexp)
        # Make sure command is replaced so sensitive output isn't shown
        @command = 'ERROR'
        raise Inspec::Exceptions::ResourceFailed,
              'The `redact_regex` option must be a regular expression'
      end
      @redact_regex = options[:redact_regex]
    end
  end

  
  # BREAK existing methods/properties to ensure that the property definitions are working
  def result ; end
  def stdout ; end
  # Defining stdout is enough to prove that the meta definitions work
  # def stderr ; end
  # def exit_status ; end
  
  # result is defined here as a public property. If it was not meant to be public the existing
  # instance_methdod be left alone or TODO: property definition could be marked as private
  property 'result', {} do
    @result ||= inspec.backend.run_command(@command)
  end

  property 'stdout', { type: String, 
    desc: 'The stdout property tests results of the command as returned in standard output (stdout).',
    # LIKE using heredoc to define the example as it makes it the easist to compose
    example: <<-EXAMPLE
describe command('echo hello') do
  its('stdout') { should eq "hello\n" }
end
EXAMPLE
    # DISLIKE that the {} become required and the block follows like it does
    # IDEA: provide the block that follows to a key in the hash provided
    # DISLIKE that the HEREDOC'd value would always have to be last if defined in the Hash
    #   and that could follow a fair amount of code in the property invokation
    # IDEA: The property could be a simple shim to an instance_variable of existing method.
    #   The method handled would handle all the code and could be private.
    } do
      result.stdout
    end

  # BREAK existing matchers to ensure the matcher definitions are working
  def exist? ; end 
  

  matcher 'exist?', { desc: 'Test if the command exists', example: <<-EXAMPLE
describe command('echo') do
  it { should exist }
end
EXAMPLE
    # DISLIKE that the {} become required and the block follows like it does
    # IDEA: provide the block that follows to a key in the hash provided
    # DISLIKE that the HEREDOC'd value would always have to be last if defined in the Hash
    #   and that could follow a fair amount of code in the property invokation
    # IDEA: The matcher could be a simple shim to an existing method.
      } do
    # silent for mock resources
    return false if inspec.os.name.nil? || inspec.os.name == 'mock'

    if inspec.os.linux?
      res = if inspec.platform.name == 'alpine'
              inspec.backend.run_command("which \"#{@command}\"")
            else
              inspec.backend.run_command("bash -c 'type \"#{@command}\"'")
            end
    elsif inspec.os.windows?
      res = inspec.backend.run_command("Get-Command \"#{@command}\"")
    elsif inspec.os.unix?
      res = inspec.backend.run_command("type \"#{@command}\"")
    else
      warn "`command(#{@command}).exist?` is not supported on your OS: #{inspec.os[:name]}"
      return false
    end
    res.exit_status.to_i == 0
  end
end

# Test Functionality

describe command('echo hello') do  
  its(:stdout) { should eq "hello\n" }
  its(:stderr) { should be_empty }
  its(:exit_status) { should eq 0 }
end

describe command('ls') do
  it { should exist }
end

# Test Introspection

describe 'Cmd Introspection' do
  let(:resource) { Inspec::Resources::Cmd }
  
  describe 'resource parameters' do
    let(:resource_parameters) { resource.resource_parameters }
    
    describe 'cmd' do
      let(:name) { 'cmd' }
      let(:parameter) { resource_parameters.find { |p| p.name == name } }
      let(:type) { [:to_s] }
      let(:required) { true }
      let(:is_identifier) { true }

      it 'name' do
        expect(parameter.name).to eq(name)
      end

      it 'type' do
        expect(parameter.type).to eq(type)
      end

      it 'required' do
        expect(parameter.required).to eq(required)
      end

      it 'is_identifier' do
        expect(parameter.is_identifier).to eq(is_identifier)
      end
    end

    describe 'options' do
      let(:name) { 'options' }
      let(:parameter) { resource_parameters.find { |p| p.name == name } }
      let(:type) { Hash }
      let(:required) { false }
      let(:is_identifier) { false }

      it 'name' do
        expect(parameter.name).to eq(name)
      end

      it 'type' do
        expect(parameter.type).to eq(type)
      end

      it 'required' do
        expect(parameter.required).to eq(required)
      end

      it 'is_identifier' do
        expect(parameter.is_identifier).to eq(is_identifier)
      end
    end
  end

  describe 'properties' do
    let(:properties) { resource.properties }

    describe 'result' do
      let(:name) { 'result' }
      let(:property) { properties.find { |p| p.name == name } }
      let(:expected_type) { String }
      
      it 'name' do
        expect(property.name).to eq(name)
      end
    end


    describe 'stdout' do
      let(:name) { 'stdout' }
      let(:property) { properties.find { |p| p.name == name } }
      let(:expected_type) { String }
      let(:expected_desc) do
        'The stdout property tests results of the command as returned in standard output (stdout).'
      end
      let(:expected_example) do
        <<-EXAMPLE
describe command('echo hello') do
  its('stdout') { should eq "hello\n" }
end
EXAMPLE
      end  

      it 'name' do
        expect(property.name).to eq(name)
      end

      it 'type' do
        expect(property.type).to eq(expected_type)
      end

      it 'description' do
        expect(property.desc).to eq(expected_desc)
      end

      it 'example' do
        expect(property.example).to eq(expected_example)
      end    
    end

  end

  describe 'matchers' do
    let(:matchers) { resource.matchers }

    describe 'exist?' do
      let(:name) { 'exist?' }
      let(:subject) { matchers.find { |p| p.name == name } }
      let(:expected_desc) do
        'Test if the command exists'
      end
      let(:expected_example) do
        <<-EXAMPLE
describe command('echo') do
  it { should exist }
end
EXAMPLE

      end

      its('name') { should eq name }
      its('desc') { should eq expected_desc }
      its('example') { should eq expected_example }
    end
  end
end