# encoding: utf-8

# You can find all the meta magic added to the resource within this file
require './introspection/libraries/meta'

class Inspec::Resources::File
  # NOTE: this is monkey-patched in already but to ensure we override the initialize
  include MetaDefinition

  def pre_initialize
    @perms_provider = select_file_perms_style(inspec.os)
  end

  resource_parameter 'path', type: [:to_s], required: true, is_identifier: true do |path|
    @file = inspec.backend.file(path)
  end

  %w[type link_path shallow_link_path  mtime size selinux_label 
    product_version file_version version? md5sum sha256sum
    path basename source source_path uid gid].each do |name|
      # NOTE: A block is provided to replace the existing method definitions so that 
      #   in the final resource definition there wouldn't exist both the meta definition
      #   and the function definition. But they could exist separately.
      # NOTE: There are no details provided to this property definition. I assume
      #   if that was supported by a property then there should be some default values.
      #   Though, with a property most of the property details are related to description
      #   and examples.
      property name do |m|
        define_method m.to_sym do |*args|
          file.method(m.to_sym).call(*args)
        end
      end
  end

  %w[ exist? file? block_device? character_device? socket? directory?
    symlink? pipe? mode mode? owner owned_by? group grouped_into? linked_to? immutable? ].each do |name|
      # NOTE: No block is provided relying instead on the methods with the same name 
      #   already defined in the resource. It could contain the function declaration as 
      #   well.
      # NOTE: There are no details provided to this property definition. This is not
      #   ideal as it would give little help for potential resource users as far as
      #   definition, example and potential parameters.
      matcher name
  end

  # NOTE: Here the definition of the matcher relies on the existing #readable? method
  #   that has been defined. It describes the arguments that it takes but does not 
  #   include the examples. Similar to properties and the matcher itself including the
  #   examples and lengthy descriptions that format well and read well would make it
  #   difficult with all this hashing.
  matcher 'readable?', args: [
    { name: 'usergroup', 
      # NOTE: the file resoure checks for presence and a non-empty string
      #   similar to other things, perhaps this work could be expressed with a specific
      #   and perhaps that type or validators could be provided to ensure the incoming
      #   argument value.
      type: [:to_s], 
      desc: "other, others, all or the value provided. defaults to all" },
    { name: 'specific user', type: [:to_s],
      desc: "the identifier of the user, overrides the group value provided" }
  ]
end

# Test Functionality

current_user = ENV['USER'] || ENV['username']

describe file('./inspec.rb') do
  it { should exist }
  it { should be_file }
  it { should be_readable }
  it { should be_writable }
  it { should_not be_executable.by_user(current_user) }
  it { should be_owned_by current_user }
  its('mode') { should cmp '0644' }
end


# Test Introspection

describe 'File Introspection' do
  let(:resource) { Inspec::Resources::File }

  def file_properties
    %w[type link_path shallow_link_path  mtime size selinux_label 
      product_version file_version version? md5sum sha256sum
      path basename source source_path uid gid]
  end

  def file_matchers
    %w[ exist? file? block_device? character_device? socket? directory?
    symlink? pipe? mode mode? owner owned_by? group grouped_into? linked_to? immutable? ]
  end

  describe 'resource parameters' do
    let(:resource_parameters) { resource.resource_parameters }
    
    describe 'path' do
      let(:name) { 'path' }
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
  end

  describe 'properties' do
    let(:properties) { resource.properties }

    file_properties.each do |name|
      describe "property: #{name}" do
        let(:property) { properties.find { |p| p.name == name } }
        
        it "property #{name} exists" do
          expect(property).not_to be_nil
        end
      end
    end
    
    file_matchers.each do |name|
      describe "matcher: #{name}" do
        let(:matcher) { properties.find { |p| p.name == name } }
    
        it "matcher #{name} does not exist as property" do
          expect(matcher).to be_nil
        end
      end
    end

  end

  describe 'matchers' do
    let(:matchers) { resource.matchers }

    file_matchers.each do |name|
      describe "matcher: #{name}" do
        let(:matcher) { matchers.find { |p| p.name == name } }
        
        it "matcher #{name} exists" do
          expect(matcher).not_to be_nil
        end
      end
    end

    # NOTE: When we talk about matchers is often in the context of how they would be
    #   used a matcher and it makes me wonder if the prefixes and suffixes that are
    #   normally associated with the method but not the use of it should be coming
    #   back in the introspection.
    describe "readable?" do
      let(:name) { 'readable?' }
      let(:matcher) { matchers.find { |p| p.name == name } }

      it "matcher #{name} exists" do
        expect(matcher).not_to be_nil
      end

      it "has two args" do
        expect(matcher.args.count).to eq(2)
      end

      it "has a usergroup argument" do
        expect(matcher.args.first.name).to be 'usergroup'
      end

      it "has a specific user argument" do
        expect(matcher.args.last.name).to be 'specific user'
      end
    end
  end
end