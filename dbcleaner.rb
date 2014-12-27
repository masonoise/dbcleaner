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
    db_client.query(query).each do |row|
      @outfile.puts "INSERT INTO #{table['name']} (#{columns.join(',')}) VALUES (#{columns.map {|c| row[c]}.join(',')})\n"
    end
  end

  def create_table(table)
    db_client.query("SHOW CREATE TABLE #{table['name']}").first['Create Table']
  end

  def table_query(table, columns, ids)
    query = "SELECT #{columns.join(',')} FROM #{table['name']}"
    if (ids)
      query << " WHERE id IN (#{ids.join(',')})"
    end
    query
  end

  def table_columns(table)
    if (table['columns'])
      table['columns']
    else
      ['*']
    end
  end

  def table_ids(table)
    table['ids'] if (table['ids'])
  end
end

# DBCleaner.new.extract
