# encoding: utf-8
# copyright: 2018, The Authors
require 'ostruct'

class Inspec::Resources::Cmd

  # Break initialize
  def initialize(*args)
    Resources::Cmd.resource_parameters.each_with_index do |rp, index|
      instance_exec(args[index], &rp.post_initialize_block)
    end
  end
  
  def self.resource_parameter(name, details, &post_initialize_block)
    resource_parameters.push(OpenStruct.new({name: name, post_initialize_block: post_initialize_block}.merge(details)))
  end

  def self.resource_parameters
    @resource_parameters ||= []
  end

  resource_parameter 'cmd', type: [:to_s], required: true, is_identifier: true do |cmd|
    # TODO: add type validation
    if cmd.nil?
      raise 'InSpec `command` was called with `nil` as the argument. This is not supported. Please provide a valid command instead.'
    end
    @command = cmd
  end
  
  resource_parameter 'options', type: Hash, required: false, is_identifier: false do |options|
    # TODO: make the default value more clear
    options ||= {}

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


  # Break the Properties that we define
  def result ; end
  def stdout ; end

  # Defines a property
  def self.property(name, details, &block)
    properties.push(OpenStruct.new({name: name }.merge(details)))
    define_method name, &block
  end
  # Stores the properties
  # NOTE: consider creating a meta definiton of the object which stores all this information
  def self.properties
    @properties ||= []
  end

  property 'result', {} do
    @result ||= inspec.backend.run_command(@command)
  end

  property 'stdout', { type: String, 
    desc: 'The stdout property tests results of the command as returned in standard output (stdout).',
    example: <<-EXAMPLE
describe command('echo hello') do
  its('stdout') { should eq \"hello\n\" }
end
EXAMPLE
  } do
    result.stdout
  end
  
end

describe command('echo hello') do
  its(:stdout) { should eq "hello\n" }
  its(:stderr) { should be_empty }
  its(:exit_status) { should eq 0 }
end

describe 'Cmd' do
  let(:resource) { Inspec::Resources::Cmd }
  
  describe 'resource parameters' do

    let(:resource_parameters) { resource.resource_parameters }
    # resource_parameter - name, type, description, example, required, is_identifier

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

    # property - name, type, description, example,
    # TODO:  identifier_for, permissions_required, see_also

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
  its('stdout') { should eq \"hello\n\" }
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
  
end

# matcher - name, args (array of hash, name, type description), descrioption, example, permissions_required, see_also
# filter_criterion - name, type, description, example, permissions_required

# limitation
# related_resource


