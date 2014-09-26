require_relative 'db_connection'
require 'active_support/inflector'
# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    DBConnection.execute2(<<-SQL).first.map {|column| column.to_sym }
    SELECT
      *
    FROM
      #{self.table_name}
    SQL
  end

  def self.finalize!
    self.columns.each do |column|
      define_method("#{column}=") { |val| attributes[column] = val }
      define_method("#{column}") { attributes[column] }
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name ||= self.to_s.downcase + 's'
  end

  def self.all
    table = self.table_name
    self.parse_all(DBConnection.execute(<<-SQL))
      SELECT
        #{table}.*
      FROM
        #{table}
      SQL

  end

  def self.parse_all(results)
    results.map{ |attr_hash| self.new(attr_hash) }
  end

  def self.find(id)
    table = self.table_name
    self.parse_all(DBConnection.execute(<<-SQL, id)).first
      SELECT
        #{table}.*
      FROM
        #{table}
      WHERE
        #{table}.id = ?
      SQL
  end

  def initialize(params = {})
    params.keys.each do |attr_name|
      unless self.class.columns.include?(attr_name.to_sym)
        raise "unknown attribute '#{attr_name}'"
      end
      self.send("#{attr_name}=", params[attr_name])
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    attributes.values
  end

  def insert
    col_names = self.class.columns.drop(1).join(', ')
    question_marks = ["?"] * (self.class.columns.count - 1)

    DBConnection.execute(<<-SQL, *attribute_values)
    INSERT INTO
      #{self.class.table_name} (#{col_names})
    VALUES
      (#{question_marks.join(', ')})
    SQL
    self.id = DBConnection.last_insert_row_id
  end

  def update
    col_names = self.class.columns.drop(1).map do |col_name|
      col_name.to_s + ' = ?'
    end

    DBConnection.execute(<<-SQL, *attribute_values[1..-1])
    UPDATE
      #{self.class.table_name}
    SET
      #{col_names.join(', ')}
    WHERE
      id = #{self.id}
    SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
