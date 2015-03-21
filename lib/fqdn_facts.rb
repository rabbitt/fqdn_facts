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

require "fqdn_facts/version"
require 'fqdn_facts/core_ext'

#
# Provides a DSL for generating Fact Handlers for different
# fully qualified domain names.
#
module FqdnFacts
  @registry = {}

  autoload :Handler, 'fqdn_facts/handler'
  autoload :Error, 'fqdn_facts/errors'

  class << self
    attr_reader :registry

    # Registers a FQDN Fact Handler
    #
    # @param klass    <Symbol> name of handler to register
    # @param options  [Hash]   options to pass
    # @option options [Symbol] :copy existing handler to copy definition from
    # @param block    [Block]  block of DSL code
    #
    # @raise [Error::HandlerNotFound] if the requested copy handler doesn't exist
    # @return <Handler>
    def register(klass, options = {}, &block)
      parent_name  = (v = options.delete(:copy)).nil? ? :handler : v.to_sym
      parent_class = parent_name == :handler ? Handler : parent_name.constantize(Handler)

      klass_const = klass.to_s.camelize
      unless Handler.const_defined? klass_const
        Handler.const_set(klass_const, Class.new(parent_class))
      end

      if parent_name != :handler
        unless parent = @registry[parent_name]
          fail Error::HandlerNotFound, other
        end
        @registry[klass.to_sym] = Handler.const_get(klass_const).copy_from(parent)
      else
        @registry[klass.to_sym] = Handler.const_get(klass_const).new
      end


      if block.arity == 1
        yield @registry[klass.to_sym]
      else
        @registry[klass.to_sym].instance_eval(&block)
      end

      @registry[klass.to_sym]
    end

    # Retrieves a handler that is capable of generating facts
    # for the given FQDN
    #
    # @param fqdn <String> Fully qualified domain name to resolve into a handler
    #
    # @raise [Error::UnresolveableHandler] if unable to find a handler for the given fqdn
    # @return <Handler>
    def handler(fqdn)
      if (handlers = @registry.values.select { |klass| klass.match?(fqdn) }).empty?
        fail Error::UnresolveableHandler, "unable to find a handler for FQDN:#{fqdn}"
      end
      handlers.sort.first.tap { |handler| handler.fqdn = fqdn }
    end
  end
end
