# encoding: utf-8

# You can find all the meta magic added to the resource within this file
require './introspection/libraries/meta'

class Inspec::Resources::Port
  # NOTE: this is monkey-patched in already but to ensure we override the initialize
  include MetaDefinition

  # TODO: without being given a block perhaps it could be by default set an instance variable
  resource_parameter 'ip', required: false, type: [:to_s], is_identifier: false do |ip|
    @ip = ip
  end

  resource_parameter 'port', required: false, type: [:to_s], is_identifier: true do |port|
    @port = port
  end

  # In the new initialize #preprocess_arguments happens after #pre_initialize
  # The idea is to perform any filtering, cleaning or ordering operations and return the
  # cleaned up arguments. In this case it is being used to enable the ip address to be an optional
  # parameter.
  def preprocess_arguments(args)
    args.unshift(nil) if args.length <= 1 # add the ip address to the front
    args
  end

  def post_initialize
    # TODO: consider changing the instance variables to private methods in this resource
    @port_manager = port_manager_for_os
    return skip_resource 'The `port` resource is not supported on your OS yet.' if @port_manager.nil?
  end
end

# Test Functionality

# port.instance_eval do
#   puts info
# end

# port(4800).instance_eval do
#   puts info
# end

# port('0.0.0.0',4800).instance_eval do
#   puts info
# end

describe port do
  its('ports') { should include 4800 }
  its('info') { should_not be_empty }
end

describe port(4800) do
  it { should be_listening }
  its('processes') { should include 'LogiVCCoreService' }
end

describe port('0.0.0.0', 4800) do
  it { should be_listening }
  its('processes') { should include 'LogiVCCoreService' }
end

describe port(4800).where { process == 'LogiVCCoreService' } do
  it { should be_listening }
  its('processes') { should include 'LogiVCCoreService'}
end

# TODO: custom_property count
# TODO: custom_matcher exist?

describe port.where { protocol =~ /tcp/ && port > 22 && port < 80 } do
  it { should_not be_listening }
end

# Test Introspection

describe 'Port Introspection' do
  let(:resource) { Inspec::Resources::Port }

  describe 'resource parameters' do
    let(:resource_parameters) { resource.resource_parameters }

    describe 'ip' do
      let(:name) { 'ip' }
      let(:parameter) { resource_parameters.find { |p| p.name == name } }
      let(:type) { [:to_s] }
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

    describe 'port' do
      let(:name) { 'port' }
      let(:parameter) { resource_parameters.find { |p| p.name == name } }
      let(:type) { [:to_s] }
      let(:required) { false }
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
  end

  describe 'filter properties' do
    let(:properties) { resource.properties }

    %w[ where entries raw_data ports addresses protocols processes pids ].each do |filter_property|
      describe filter_property do
        let(:name) { filter_property }
        let(:property) { properties.find { |p| p.name == name } }
        
        it "filter: #{filter_property}" do
          expect(property.name).to eq(name)
        end
      end  
    end
  end

  describe 'filter criterian' do
    let(:filter_criterian) { resource.filter_criterian }
    %w[ port address protocol process pid ].each do |filter_criteria|
      describe filter_criteria do
        let(:name) { filter_criteria }
        let(:criteria) { filter_criterian.find { |p| p.name == name } }
        
        it "filter criteria: #{filter_criteria}" do
          expect(criteria.name).to eq(name)
        end
      end  
    end
  end
end