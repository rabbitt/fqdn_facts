=begin
    Copyright (C) 2015  Carl P. Corliss <rabbitt@gmail.com>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License along
    with this program; if not, write to the Free Software Foundation, Inc.,
    51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
=end

require_relative 'core_ext'
require_relative 'errors'

module FqdnFacts
  #
  # base class for all handlers.
  #
  class Handler
    class << self
      # Creates a new instance of this object using the internal state
      # of another handler object
      #
      # @param other <Handler> the handler to copy
      # @return <Handler>
      def copy_from(other)
        new(other.export)
      end
    end

    attr_accessor :priority, :fqdn

    # default validation hash of FQDN components
    DEFAULT_COMPONENTS = {
      host: %r'(.+)',
      sub: %r:(.+):,
      tld: %r'(.+)'
    } unless defined? DEFAULT_COMPONENTS
    private_constant :DEFAULT_COMPONENTS

    # initilalizer
    #
    # @param data [Hash] seeds the handler with base data
    # @option data [Integer] :priority sets the initial priority level
    # @option data [Hash] :conversions sets the initial set of conversions
    # @option data [Hash] :components sets the initial component validations
    # @option data [Array] :order sets the initial order of components
    # @option data [Hash] :facts sets the initial set of facts
    def initialize(data = {})
      @priority        = data.delete(:priority)        || 1
      @conversions     = data.delete(:conversions)     || {}
      @components      = data.delete(:components)      || DEFAULT_COMPONENTS.dup
      @order           = data.delete(:order)           || DEFAULT_COMPONENTS.keys
      @facts           = data.delete(:facts)           || {}
      @fqdn            = ''

      add_fact :fqdn, ->() { @fqdn }
      add_fact :handler_name, self.class.to_s.split('::').last.underscore
    end

    ## DSL Methods
    # @!group DSL

    # The priority of the registered Fqdn Fact handler
    #
    # Lower priority fqdn fact handlers win out over
    # higer priority handlers.
    #
    # @overload priority(value)
    #   Sets the priority level
    #   @param value [Integer] higher numbers denote lower priority, lower numbers denote higher
    # @overload priority()
    #   Retrieves the current priority level
    # @return Integer
    def priority(value = nil)
      return @priority if value.nil?
      @priority = value.to_i
    end

    # Defines the order of the defined components
    # that make up the FQDN.
    #
    # This defaults to: host, :sub, :tld
    #
    # @param args <Array<Symbol>> list of ordered components
    # @raise [ArgumentError] if args is empty
    def order(*args)
      raise ArgumentError, 'empty list of components' unless order.present?
      @order = args
    end
    alias_method :components, :order

    # Define a validation rule for a component.
    #
    # Validation rules can be one of the following
    #   * :any (the same as /.+/)
    #   * A Hash of sub_component => regexp
    #   * An array of valid values
    #   * A scalar for exact matching
    #
    # @param component <Symbol> the name of the component to set validation for
    # @param validate [Hash{Symbol=>Symbol,Hash,Array,Scalar}] validation to perform for component
    def component(component, validate=:any)
      v = case validate
        when :any then %r:(.+):
        when Hash then
          if @components[component.to_sym].is_a?(Hash)
            basis = @components[component.to_sym]
          else
            basis = {}
          end

          basis.merge(
            Hash[validate.keys.zip(
              validate.values.collect {|v|
                case v
                  when :any then %r:(.+):
                  when Regexp then v
                  else Regexp.new(v)
                end
              }
            )]
          )
        when Array then
          %r:(#{validate.join('|')}):
        else validate
      end

      if @components[component.to_sym]
        # if their not the same class, then remove any conversions
        unless @components[component.to_sym].is_a?(v.class)
          @conversions.delete(component.to_sym)
        end
      end

      @components[component.to_sym]  = v
    end
    alias_method :validate, :component

    # Defines a conversion rule for a given component.
    # The conversion must be a Proc/Lambda
    #
    # @param component <Symbol> the name of the component to set validation for
    # @param conversion <Proc> the conversion proc/lambda
    def convert(component, conversion)
      conversion = case conversion
        when Hash then
          @conversions[component.to_sym] ||= {}
          @conversions[component.to_sym].merge(conversion)
        else conversion
      end
      @conversions[component.to_sym] = conversion
    end

    # Returns the value of a fact
    #
    # @param name <String,Symbol> name of the fact to retrieve
    def get_fact(name)
      retrieve_facts[name.to_sym]
    end

    # Adds a fact, either using a static value, or a Proc/Lambda
    # for runtime determination of the value.
    #
    # @param name <String> Symbol name of the fact to add
    # @param value <Scalar,Array,Hash,Proc> value of the fact
    def add_fact(name, value)
      @facts[name.to_sym] = value
    end

    # Removes a fact from the list of facts.
    # @param name <String,Symbol> name of the fact to remove
    def remove_fact(name)
      @facts.delete(name.to_sym)
    end

    ### End of DSL Methods
    # @!endgroup

    # retrieve aggregated facts
    #
    # @param options [Hash] options to use when retrieving facts
    # @option options [String] :prefix a string to prefix every fact name with
    # @option options [Array<Symbol>] :only a list of specific facts to retrieve
    #
    # @return [Hash{Symbol=><Scalar,Hash,Array>}]
    def retrieve(options={})
      prefix = options.delete(:prefix)
      only   = (o = options.delete(:only)).empty? ? nil : o.collect(&:to_sym)

      merged_facts.dup.tap do |facts|
        facts.replace(
          facts.inject({}) do |hash, (fact, value)|
            next hash unless only.empty? || only.include?(fact)
            key = prefix.empty? ? key : "#{prefix}_#{key}"
            hash[key] = value
            hash
          end
        )
      end
    end

    # Retrieve all facts, possibly prefixing their names (@see #retrieve)
    # @param prefix <String> a string to prefix every fact name with
    # @return [Hash{Symbol=><Scalar,Hash,Array>}]
    def all(prefix = nil)
      retrieve prefix: prefix
    end

    # legacy support method

    alias_method :retrieve_facts, :all

    # @return Hash all aggregate facts
    def to_h
      merged_facts.dup
    end

    # Checks to see if the fqdn matches this particular FQDN Fact Handler
    # @api private
    def match?(fqdn)
      parts = fqdn.split('.', @order.size)
      return unless parts.size == @order.size

      debug "Validating #{self.class}:"

      test_data = @order.zip(parts)
      debug "  test data -> #{test_data.inspect}"

      test_data.all? do |name, value|
        debug "  validating component '#{name}'"
        validation = case @components[name]
          when Hash then Regexp.new(@components[name].values.join)
          when nil then %r:.+:
          else @components[name]
        end

        case validation
          when Regexp then
            (value =~ validation).tap { |r|
              debug "    Regexp -> #{value.inspect} =~ #{validation.inspect} == #{r.inspect}"
            }
          when Array  then
            validation.include?(value).tap { |r|
              debug "    Array -> #{validation.inspect}.include?(#{value.inspect}) == #{r.inspect}"
            }
          else
            (value == validation).tap { |r|
              debug "    #{validation.class} -> #{value.inspect} == #{validation.inspect} == #{r.inspect}"
            }
        end
      end.tap { |r| debug " ---> validation #{r ? 'successful' : 'failed'} for #{self.class}"}
    end

    # Compares the priority of this handler to another handler
    #
    # @param other <Handler> the handler to compare against
    # @return [-1, 0, 1] if other is <=, =, or >= self
    def <=>(other)
      self.priority <=> other.priority
    end

    # Exports the internal state as a hash
    # @api private
    def export
      instance_variables.inject({}) do |exports, name|
        varname = name.to_s.tr('@', '').to_sym
        exports[varname] = begin
          Marshal.load(Marshal.dump(instance_variable_get(name)))
        rescue TypeError
          instance_variable_get(name).dup
        end
        exports
      end
    end

    private

    # Merges and freezes all the facts
    # @api private
    def merge_facts
      @merged ||= begin
        facts = @facts.merge(Hash[fqdn_components]).
                  reject { |k,v| facts.include? v }

        # build facts from components
        @components.each do |name, value|
          case value
          when Hash then
            data = facts[name].scan(Regexp.new(value.values.join)).flatten
            value.keys.zip(data).each do |key, v|
              if @conversions[name] && @conversions[name][key]
                facts["#{name}_#{key}".to_sym] = @conversions[name][key].call(v)
              else
                facts["#{name}_#{key}".to_sym] = v
              end
            end
          else
            if @conversions[name]
              facts[name] = @conversions[name].call(facts[name])
            end
            @facts.merge!(name.to_sym => value)
          end
        end

        # handle conversions
        facts.each do |key, value|
          if value.is_a?(Proc)
            value = value.arity == 1 ? value.call(facts) : value.call()
          end
          facts[key] = value.is_a?(Symbol) ? value.to_s : value
        end

        facts.reject { |k,v| v.empty? }
      end.freeze
    end

    # @api private
    def fqdn_data
      @fqdn.split('.', @order.size)
    end

    # @api private
    def fqdn_components
      @order.zip(fqdn_data)
    end

    # @api private
    def debug(message)
      if ENV.keys.collect(&:downcase).include? 'debug'
        STDERR.puts message
      end
    end
  end
end
