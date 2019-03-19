# encoding: utf-8

# You can find all the meta magic added to the resource within this file
require './introspection/libraries/meta'


module Inspec::Resources
  class DockerContainerFilter
    include MetaDefinition
    # use filtertable for containers
    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
    filter.register_column(:commands,       field: 'command')
          .register_column(:ids,            field: 'id')
          .register_column(:images,         field: 'image')
          .register_column(:labels,         field: 'labels', style: :simple)
          .register_column(:local_volumes,  field: 'localvolumes')
          .register_column(:mounts,         field: 'mounts')
          .register_column(:names,          field: 'names')
          .register_column(:networks,       field: 'networks')
          .register_column(:ports,          field: 'ports')
          .register_column(:running_for,    field: 'runningfor')
          .register_column(:sizes,          field: 'size')
          .register_column(:status,         field: 'status')
          .register_custom_matcher(:running?) { |x|
            x.where { status.downcase.start_with?('up') }
          }
    filter.install_filter_methods_on_resource(self, :containers)

    attr_reader :containers
    def initialize(containers)
      @containers = containers
    end
  end

  class DockerImageFilter
    include MetaDefinition

    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
    filter.register_column(:ids,           field: 'id')
          .register_column(:repositories,  field: 'repository')
          .register_column(:tags,          field: 'tag')
          .register_column(:sizes,         field: 'size')
          .register_column(:digests,       field: 'digest')
          .register_column(:created,       field: 'createdat')
          .register_column(:created_since, field: 'createdsize')
    filter.install_filter_methods_on_resource(self, :images)

    attr_reader :images
    def initialize(images)
      @images = images
    end
  end

  class DockerPluginFilter
    include MetaDefinition

    filter = FilterTable.create
    filter.add(:ids,      field: 'id')
          .add(:names,    field: 'name')
          .add(:versions, field: 'version')
          .add(:enabled,  field: 'enabled')
    filter.connect(self, :plugins)

    attr_reader :plugins
    def initialize(plugins)
      @plugins = plugins
    end
  end

  class DockerServiceFilter
    include MetaDefinition

    filter = FilterTable.create
    filter.register_custom_matcher(:exists?) { |x| !x.entries.empty? }
    filter.register_column(:ids,      field: 'id')
          .register_column(:names,    field: 'name')
          .register_column(:modes,    field: 'mode')
          .register_column(:replicas, field: 'replicas')
          .register_column(:images,   field: 'image')
          .register_column(:ports,    field: 'ports')
    filter.install_filter_methods_on_resource(self, :services)

    attr_reader :services
    def initialize(services)
      @services = services
    end
  end

  class Docker
    include MetaDefinition

    property 'version', {}


    property 'images', { type: DockerImageFilter }
    # containers
    # images
    # plugins
    # services

  end
end

# Test Functionality

describe docker.containers do
  its('images') { should include 'habitat/default-studio-x86_64-linux:0.78.0' }
end

describe docker.images do
  its('repositories') { should include 'habitat/default-studio-x86_64-linux' }
end

describe docker.plugins.where { name == 'rexray/ebs' } do
  it { should_not exist }
end

describe docker.services do
  its('images') { should_not include 'inssecure_image' }
end

describe docker.version do
  its('Server.Version') { should cmp >= '1.12'}
  its('Client.Version') { should cmp >= '1.12'}
end

docker.containers.ids.each do |id|
  # call docker inspect for a specific container id
  describe docker.object(id) do
    its(%w(HostConfig Privileged)) { should cmp true }
    its(%w(HostConfig NetworkMode)) { should cmp "default" }
  end
end

# Test Introspection

describe 'Docker Introspection' do
  let(:resource) { Inspec::Resources::Docker }

  describe 'properties' do
    let(:properties) { resource.properties }

    describe 'version' do
      let(:name) { 'version' }
      let(:property) { properties.find { |p| p.name == name } }
      let(:expected_type) { String }
      
      it 'name' do
        expect(property.name).to eq(name)
      end
    end

    describe 'images' do
      let(:name) { 'images' }
      let(:property) { properties.find { |p| p.name == name } }

      it 'name' do
        expect(property.name).to eq(name)
      end

      %w[ where entries raw_data ids repositories tags sizes digests created created_since ].each do |filter_property|
        it "images.#{filter_property}" do
          given_property = property.type.properties.find { |p| p.name == filter_property }
          # NOTE: I would prefer a different interface.
          #     
          #     resource.property('images').properties
          #   
          #  Because the meta-definition methods are defined right on the class it would make the first
          #  hard without there being a potential collision of the defining and the retrieving. So to make
          #  the first thing possible requires some indirection at the start:
          #
          #     resource.meta.property('images').properties
          #
          # NOTE: When approaching iterating through this particular object a special exception would have to be
          #   made for these properties during its doc rendering, shell rendering, or snippet rendering. Asking each
          #   type if it has a meta definition itself would suffice. The one worry here is that if we were to ask 
          #   a Ruby class for that method it may return it someday.
          #
          #   Then it would fall on the process that would render the docs to ask each property if they had a MetaDefinition
          #   ancestor. `resource.meta.property('images').ancestors.include?(MetaDefinition)`
          #
          #   An alternative would be define a property and that property returns back a PropertyDefinition.
          #   The property definition would include the details provided alongside the name when it was created.
          #   The PropertyDefinition could respond with a boolean if the property it is describing also
          #   has a meta definition. Behind the scenes that could simply be the above code but it would guard it
          #   much better and create a better interface.
          expect(given_property).not_to be_nil
        end
      end

      %w[ id repository tag size digest createdat createdsize ].each do |filter_criterion|
        it "images. filter criterion #{filter_criterion}" do
          given_property = property.type.filter_criterian.find { |p| p.name == filter_criterion }
          expect(given_property).not_to be_nil
        end
      end
    end
  end
end
