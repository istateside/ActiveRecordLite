require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    @class_name.constantize
  end

  def table_name
    @class_name.underscore + 's'
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @class_name  = options[:class_name]  || (name.camelize.singularize)
    @foreign_key = options[:foreign_key] || (name + '_id').to_sym
    @primary_key = options[:primary_key] || :id
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @class_name = options[:class_name]   || (name.camelize.singularize)
    @foreign_key = options[:foreign_key] ||
      (self_class_name.underscore + '_id').to_sym
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    assoc_options[name] = BelongsToOptions.new(name.to_s, options)

    define_method(name) do
      foreign_key_value = self.id
      model_class = assoc_options[name].model_class
      primary_key = assoc_options[name].primary_key

      model_class.where({primary_key.to_s => foreign_key_value}).first
    end
  end

  def has_many(name, options = {})
    define_method(name) do
      options2 = HasManyOptions.new(name.to_s, self.class.to_s, options)

      foreign_key = options2.foreign_key
      model_class = options2.model_class
      primary_key_value = self.id

      model_class.where({foreign_key.to_s => primary_key_value})
    end
  end

  def assoc_options
    @assoc_options ||= {}
  end
end

class SQLObject
  extend Associatable
end
