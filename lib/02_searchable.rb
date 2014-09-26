require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    # p "entering where search"
    # p "printing params...."
    # p params

    where_line = params.keys.map{ |key| "#{key} = ?"}.join(' AND ')    #
    # p "printing where_line...."
    # p where_line
    #
    # p "printing values"
    # p params.values

    results = DBConnection.execute(<<-SQL, params.values)
    SELECT
      *
    FROM
      #{self.table_name}
    WHERE
      #{where_line}
    SQL
    results.map{ |result_hash| self.new(result_hash)}
  end
end

class SQLObject
  extend Searchable
end
