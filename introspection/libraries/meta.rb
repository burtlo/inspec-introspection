require 'ostruct'

module MetaDefinition
  def self.included(klass)
    klass.extend ResourceParameters
    klass.extend Properties
    klass.extend Matchers
    klass.extend MatchersByDSL
  
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
        pre_initialize
        preprocess_arguments(args)
        # NOTE: a `pre_initialize` invokation by default with every resource defining an no-op method 
        klass.resource_parameters.each_with_index do |rp, index|
          instance_exec(args[index], &rp.post_initialize_block)
        end
        # NOTE: a `post_initialize` invokation by default with every resource defining an no-op method 
        post_initialize
      end
    end
  end

  # Generate a no-op method that can be overriden in the Resource
  # This is the first method called in the #initialize
  def pre_initialize ; end

  # The incoming arguments may need to be processed in the initialize
  def preprocess_arguments(args)
    args
  end

  # Generate a no-op method that can be overriden in the Resource
  # This method is called as a final step in the #initalize
  def post_initialize ; end

  module ResourceParameters
    def resource_parameter(name, details, &post_initialize_block)
      resource_parameters.push(OpenStruct.new({ name: name, post_initialize_block: post_initialize_block}.merge(details)))
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
    # TODO: default details should be established if having a default is appropriate
    def property(name, details = {}, &block)
      properties.push(OpenStruct.new({ name: name }.merge(details)))
      # NOTE: When a property is defined it may simply be a symbolic definition and the code is already generated.
      #   this is true currently in the FilterTable case where there is no need to define a new method definition.
      define_method(name, &block) if block
    end

    # TODO: default details should be established if having a default is appropriate
    def filter_property(name, details = {})
      properties.push(OpenStruct.new({ name: name, type: :filter }.merge(details)))      
    end

    # Stores all the properties
    # NOTE: consider creating a meta definiton of the object which stores all this information
    def properties
      @properties ||= []
    end

    # TODO: default details should be established if having a default is appropriate
    def filter_field(name, details = {})
      filter_criterian.push(OpenStruct.new({ name: name }.merge(details)))      
    end

    def filter_criterian
      @filter_criterian ||= []
    end
  end

  module Matchers
    # TODO: default details should be established if having a default is appropriate
    def matcher(name, details = {}, &block)
      # NOTE: Currently args are defined as a Hash. This quickly turns them into an
      #   object to create the interface to simulate an object.
      if details[:args]
        details[:args] = details[:args].map { |arg| OpenStruct.new(arg) }
      end

      matchers.push(OpenStruct.new({ name: name }.merge(details)))

      
      # NOTE: When a matcher is defined it may simply be a symbolic definition and the code is already generated.
      #   this is true currently in the FilterTable case where there is no need to define a new method definition.
      define_method(name, &block) if block
    end

    def matchers
      @matchers ||= []
    end  
  end


  module MatchersByDSL
    # NOTE: The block provided is a DSL block that needs to be evaluated
    #   in the context of Matcher builder
    def matcher_by_dsl(name, &block)
      built_matcher = MatcherBuilder.new.build(name, &block)
      define_method(name, built_matcher.execute) if built_matcher.execute
      matchers.push(built_matcher)
   end

    def matchers
      @matchers ||= []
    end

    class ArgBuilder
      class MatcherArg
        attr_accessor :name, :type, :desc
      end

      attr_reader :arg

      def build(name, &block)
        @arg = MatcherArg.new
        @arg.name = name
        instance_exec(&block)
        @arg
      end

      private
      def type(value)
        arg.type = value
      end

      def desc(value)
        arg.desc = value
      end
    end

    class MatcherBuilder
      class Matcher
        attr_accessor :name, :execute
        def args
          @args ||= []
        end
      end

      attr_reader :matcher

      def build(name, &block)
        @matcher = Matcher.new
        @matcher.name = name
        instance_exec(&block)
        @matcher
      end

      def arg(name,&block)
        matcher.args.push ArgBuilder.new.build(name, &block)
      end

      def execute(&block)
        matcher.execute = block
      end
    end
  end
end