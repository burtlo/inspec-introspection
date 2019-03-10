require 'pry'
require './introspection/libraries/meta'

require 'inspec/plugin/v1/plugin_types/resource'

module Inspec
  module Plugins
    class Resource
      # Adds the meta functionality to every resource
      include MetaDefinition
    end
  end
end

require 'utils/filter'

#
# Welcome the world of monkey-patching of the FilterTable
#
module FilterTable
  class Factory
    alias original_install_filter_methods_on_resource install_filter_methods_on_resource

    def install_filter_methods_on_resource(resource_class, raw_data_fetcher_method_name) # rubocop: disable Metrics/AbcSize, Metrics/MethodLength
      # NOTE: docker and nginx resources have these filter classes that are defined within their own class 
      #   and those are then used within the resource class. This creates a bit of a problem with this patch
      unless resource_class.ancestors.include?(MetaDefinition)
        puts "SKIPPING #{resource_class} for filter properties as it is not a resource"
        return original_install_filter_methods_on_resource(resource_class, raw_data_fetcher_method_name)    
      end

      begin
        # NOTE: The filter_methods where, entries and raw_data are always present and they need
        #   to be added. They really should not be done here but this patch will check if they are
        #   already defined and ignore them if they have been.
        filter_methods = @filter_methods
        
        resource_class.instance_eval do
          filter_methods.each do |filter|
            filter_property(filter.to_s,{}) unless properties.find { |p| p.name == filter.to_s }
          end
        end

        # NOTE: Adding methods here to register the properties and filter critierian require
        #   that all the reesources have the meta module included - which requires that it 
        #   be added to Inspec.resource(1)
        # 
        custom_properties = @custom_properties
        
        resource_class.instance_eval do
          custom_properties.each do |property_name,property_props|
            filter_property(property_name.to_s,{})
            # TODO: CustomPropertyType field_name and opts[:field] will often match
            #   sometimes the option is not present. I need to investigate the reason
            filter_field(property_props.field_name,{})
          end
        end
      rescue Exception => e
        binding.pry
        puts e        
      end
      original_install_filter_methods_on_resource(resource_class, raw_data_fetcher_method_name)
    end
  end
end



require 'inspec'
require 'inspec/cli'

Inspec::InspecCLI.start(%w[exec introspection])