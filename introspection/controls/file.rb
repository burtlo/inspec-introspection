# encoding: utf-8

# You can find all the meta magic added to the resource within this file
require './introspection/libraries/meta'

class Inspec::Resources::FileResource
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
      property name, {} do |*args|
        file.method(name.to_sym).call(*args)
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

  # NOTE: To prove that the writable definition below will define the meta and replace the execution
  def writable?(group,user) ; fail "writable replaced" ; end

  # NOTE: Defining a matcher/propert/resource_parameter via an embedded DSL
  #   could make it easier to define the various parameters in a more legible way
  matcher_by_dsl 'writable?' do
    arg 'usergroup' do
      type [:to_s]
      desc "other, others, all or the value provided. defaults to all"
    end

    arg 'specific user' do
      type [:to_s]
      desc "the identifier of the user, overrides the group value provided"
    end

    example "it { should be_writable.by('staff') }", os: 'mac_os_x'
    example "it { should be_writable.by_user('Administrator') }", os: 'windows'

    # NOTE: Since the block provided to the method is now the DSL a method would need
    #   to be added if DSL was also going to provide the code to execute.
    # NOTE: It feels good to include the code with the definition it also has the potential
    #   to create some cognitive overload with all the scope switching with any blocks. As
    #   this block is executed in the resource instance at runtime.
    # NOTE: The mention of the arguments here should probably match the name of the args stated above.
    # NOTE: It potentially feels like poor design that the args are listed above make to the block args below.
    #   As in they could get out of sync. The alternative would require the development of a proxy method that accepts
    #   the args defined, verify them, and then store them. Then the execute block that would be invoked and within
    #   that execute block the provided args could be retrieved from the stored location.but to make it easy would
    #   likely not make it very thread-safe.
    execute do |by_usergroup, by_specific_user|
      return false unless exist?
      return skip_resource '`writable?` is not supported on your OS yet.' if @perms_provider.nil?

      file_permission_granted?('write', by_usergroup, by_specific_user)
    end
  end
end

# Test Functionality

current_user = ENV['USER'] || ENV['username']

describe file('./inspec.rb') do
  it { should exist }
  it { should be_file }
  it { should be_readable }
  # NOTE: The matcher is actually provided in matchers defined in inspec/lib/matchers.rb
  #   be_readable, be_writable, be_executable (by and by_user)
  it { should be_readable('staff') }
  # NOTE: This is failing despite what looks like the matcher working ...
  # it { should be_readable.by('staff') }
  it { should be_writable }
  it { should_not be_executable.by_user(current_user) }
  it { should be_owned_by current_user }
  its('mode') { should cmp '0644' }
end


# Test Introspection

describe 'File Introspection' do
  let(:resource) { Inspec::Resources::FileResource }

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

      it "matcher readable? exists" do
        expect(matcher).not_to be_nil
      end

      it "has two args" do
        expect(matcher.args.count).to eq(2)
      end

      it "has a usergroup argument" do
        expect(matcher.args.first.name).to eq 'usergroup'
      end

      it "has a specific user argument" do
        expect(matcher.args.last.name).to eq 'specific user'
      end
    end

    # TODO: The matcher is defined by an attempt at doing with a DSL
    describe "writable?" do
      let(:name) { 'writable?' }
      let(:matcher) { matchers.find { |p| p.name == name } }

      it "matcher writable? exists" do
        expect(matcher).not_to be_nil
      end

      it "has two args" do
        expect(matcher.args.count).to eq(2)
      end

      it "has a usergroup argument" do
        expect(matcher.args.first.name).to eq 'usergroup'
      end

      it "has a specific user argument" do
        expect(matcher.args.last.name).to eq 'specific user'
      end

      it "has two examples" do
        expect(matcher.examples.count).to eq(2)
      end

      it "specific one os-specific example" do
        expect(matcher.examples(os: 'mac_os_x')).to include "it { should be_writable.by('staff') }"
      end
    end
  end
end