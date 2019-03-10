require 'ostruct'

module MetaDefinition
  def self.included(klass)
    klass.extend ResourceParameters
    klass.extend Properties
    klass.extend Matchers
  
    klass.instance_exec do 
      # REPLACE - #initialize
      #
      # NOTE: Definining #initialize in the module places it in a "superclass" of the current class
      #   and fails to override it. By getting inside the class object itself we are able to override it.
      #
      # As a resource can define N number of resource parameters I needed
      # to replace the initialize argument signature with one that could
      # take N arguments.
      #
      define_method :initialize do |*args|
        # NOTE: a `pre_initialize` invokation by default with every resource defining an no-op method 
        klass.resource_parameters.each_with_index do |rp, index|
          instance_exec(args[index], &rp.post_initialize_block)
        end
        # NOTE: a `post_initialize` invokation by default with every resource defining an no-op method 
      end
    end
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
end