require 'ostruct'

module MetaDefinition
  def self.included(klass)
    klass.extend ResourceParameters
    klass.extend Properties
    klass.extend Matchers
  end

  module ResourceParameters
    def resource_parameter(name, details, &post_initialize_block)
      resource_parameters.push(OpenStruct.new({name: name, post_initialize_block: post_initialize_block}.merge(details)))
    end

    # This stores all the of the resource parameters defined.
    #
    # NOTE: This should likely be added some large meta definition of the Resource
    #   to reduce the surface area introduced into the class object with these very
    #   generic names.
    def resource_parameters
      @resource_parameters ||= []
    end
  end

  module Properties
    # Class level method that enables the definition of a property
    def property(name, details, &block)
      properties.push(OpenStruct.new({name: name }.merge(details)))
      define_method name, &block
    end

    # Stores all the properties
    # NOTE: consider creating a meta definiton of the object which stores all this information
    def properties
      @properties ||= []
    end
  end

  module Matchers
    def matcher(name, details, &block)
      matchers.push(OpenStruct.new({name: name }.merge(details)))
      define_method name, &block
    end
  
    def matchers
      @matchers ||= []
    end  
  end

  # REPLACE - #initialize
  #
  # As a resource can define N number of resource parameters I needed
  # to replace the initialize argument signature with one that could
  # take N arguments.
  #
  # TODO: The specific class object needs to be used because of the way that InSpec generates
  #    resources. The class object could probably be discovered at runtime in a more generic
  #    way
  #
  def initialize(*args)
    # NOTE: a `pre_initialize` invokation by default with every resource defining an no-op method 
    Resources::Cmd.resource_parameters.each_with_index do |rp, index|
      instance_exec(args[index], &rp.post_initialize_block)
    end
    # NOTE: a `post_initialize` invokation by default with every resource defining an no-op method 
  end
  


  
end