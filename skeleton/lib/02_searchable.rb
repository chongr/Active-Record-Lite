require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)

    where_line = params.map  do |key, value|
      "#{self.table_name}.#{key} = '#{value}'"
    end.join(" AND ")

    result = DBConnection.execute(p <<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    parse_all(result)
  end
end

class SQLObject
  extend Searchable
end
