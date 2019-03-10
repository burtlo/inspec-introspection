# encoding: utf-8

# You can find all the meta magic added to the resource within this file
require './introspection/libraries/meta'

class Inspec::Resources::Port
  include MetaDefinition

  # TODO: without being given a block perhaps it could be by default set an instance variable
  resource_parameter 'ip', required: false, type: [:to_s], is_identifier: false do |ip|
    @ip = ip
  end

  resource_parameter 'port', required: false, type: [:to_s], is_identifier: false do |port|
    @port = port
  end

  def preprocess_arguments(args)
    args.unshift(nil) if args.length <= 1 # add the ip address to the front
    args
  end

  def post_initialize
    # TODO: consider changing this instance variable to private method in this resource
    @cache = nil
    @port_manager = port_manager_for_os
    return skip_resource 'The `port` resource is not supported on your OS yet.' if @port_manager.nil?
  end
end

# When defining a port you can start with an address to filter
# when you provide the acutal port value you filter on that
# providing both creates a double filter

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

describe port.where { protocol =~ /tcp/ && port > 22 && port < 80 } do
  it { should_not be_listening }
end

describe 'Port' do
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
  end
end