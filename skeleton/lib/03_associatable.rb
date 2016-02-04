require_relative '02_searchable'
require 'active_support/inflector'
require 'byebug'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    class_name.constantize
  end

  def table_name
    return "humans" if class_name == "Human"
    class_name.tableize
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @foreign_key = options[:foreign_key] || "#{name}_id".to_sym
    @class_name = options[:class_name] || "#{name.capitalize}"
    @primary_key = options[:primary_key] || :id

  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    @foreign_key = options[:foreign_key] || "#{self_class_name.downcase}_id".to_sym
    @class_name = options[:class_name] || "#{name.to_s.singularize.capitalize}"
    @primary_key = options[:primary_key] || :id
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    belongs = BelongsToOptions.new(name, options)
    define_method(name) do
      value_of_foreign_key = send(belongs.foreign_key)
      found_result = belongs.model_class.send(:where, {belongs.primary_key => value_of_foreign_key})
      found_result.first
    end

  end

  def has_many(name, options = {})
    many = HasManyOptions.new(name, self.name, options)
    define_method(name) do

      value_of_id = send(many.primary_key)
      found_result = many.model_class.send(:where, {many.foreign_key => value_of_id})
      found_result
    end
  end

  def assoc_options
    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
end
