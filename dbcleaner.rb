require 'pry'
require_relative 'db_cleaner_util.rb'

class DBCleaner
  include DBCleanerUtil

  @db_client = nil
  def db_client
    @db_client ||= get_db_client
  end

  #
  # Main method, call this to execute the DBCleaner extraction based on the db_config.json file.
  #
  def extract(outfile_path = 'dbcleaner_output.sql')
    @outfile = open(outfile_path, 'w')
    puts "Loading config...\n"
    dbconfig = parse_db_config

    extract_tables(dbconfig["tables"])
  end

  def extract_tables(tables)
    puts "Extracting #{tables.count} tables..."
    tables.each do |table|
      extract_table(table)
    end
  end

  def extract_table(table)
    puts "Extracting from #{table['name']}\n"
    @outfile.puts create_table(table)
    columns = table_columns(table)
    ids = table_ids(table)
    query = table_query(table, columns, ids)
    results = db_client.query(query)
    results.each do |row|
      @outfile.puts make_insert(table, columns, results.fields, row)
    end
  end

  def create_table(table)
    db_client.query("SHOW CREATE TABLE #{table['name']}").first['Create Table']
  end

  def make_insert(table, columns, fields, row)
    statement = "INSERT INTO #{table['name']} (#{fields.join(',')}) VALUES ("
    values = []
    fields.each do |field|
      val = row[field]
      val = "'#{val}'" if columns[field] == 'varchar'
      values << val
    end
    statement << "#{values.join(',')})\n"
    statement
  end

  def table_query(table, columns, ids)
    query = "SELECT #{columns.keys.join(',')} FROM #{table['name']}"
    if (ids)
      query << " WHERE id IN (#{ids.join(',')})"
    end
    query
  end

  #
  # Get the columns and types for the table from the database, and return a Hash
  # with each of the requested columns where k=column name, v=column type
  #
  def table_columns(table)
    fields = db_client.query("SHOW FIELDS FROM #{table['name']}")
    columns = {}
    fields.each do |field|
      if (table['columns'].nil? || table['columns'].include?(field['Field']))
        t = field['Type']
        t = 'varchar' if t.start_with?('varchar')
        t = 'int' if t.start_with?('int')
        columns[field['Field']] = t
      end
    end
    columns
  end

  def table_ids(table)
    table['ids'] if (table['ids'])
  end
end

# DBCleaner.new.extract
