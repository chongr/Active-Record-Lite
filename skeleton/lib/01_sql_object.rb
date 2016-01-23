require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns

    return_array = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    @columns = return_array.first.map(&:to_sym)
  end

  def self.finalize!
    self.columns.each do |col|
      define_method("#{col}") do
        attributes[col]
      end

      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
    # @table_name = name.tableize unless table_name
  end

  def self.table_name
    @table_name ||= name.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        #{self.table_name}.*
      FROM
        #{self.table_name}
    SQL

    parse_all(results)
  end

  def self.parse_all(results)
    results.map { |hash| new(hash) }
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id = ?
      LIMIT 1
    SQL

    return nil if result.empty?
    new(result.first)
  end

  def initialize(params = {})
    params.each do |key, value|
      raise "unknown attribute '#{key}'" unless self.class.columns.include?(key.to_sym)
      send("#{key.to_s}=", value)
    end
  end

  def attributes
    @attributes ||= {}
  end

  def insert
    col_names = self.class.columns.drop(1).join(", ")
    question_marks = ["?"] * self.class.columns.drop(1).length

    DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks.join(", ")})
    SQL

    send("id=", DBConnection.last_insert_row_id)

  end

  def attribute_values
    self.class.columns.map do |col|
      send("#{col}")
    end
  end

  def update
    set_line = self.class.columns.map {|attr_name| "#{attr_name} = ?"}.join(", ")
    object_id = send("id")

    DBConnection.execute(<<-SQL, *attribute_values)
      UPDATE
        #{self.class.table_name}
      SET
        #{set_line}
      WHERE
        id = #{object_id}
    SQL
  end

  def save
    if send("id").nil?
      insert
    else
      update
    end
  end
end
