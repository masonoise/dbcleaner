require 'pry'
require_relative 'db_cleaner_util.rb'

class DBCleaner
  include DBCleanerUtil

  @db_client = nil

  def extract
    @db_client = get_db_client

    puts "Loading config...\n"
    dbconfig = parse_db_config

    extract_tables(dbconfig["tables"])
  end

  def extract_tables(tables)
    tables.each do |table|
      extract_table(table)
    end
  end

  def extract_table(table)
    puts "Extracting from #{table['name']}\n"
    columns = table_columns(table)
    ids = table_ids(table)
    query = table_query(table, columns, ids)
    @db_client.query(query).each do |row|
      puts "INSERT INTO #{table['name']} (#{columns.join(',')}) VALUES (#{columns.map {|c| row[c]}.join(',')})\n"
    end
  end

  def table_query(table, columns, ids)
    query = "SELECT #{columns.join(',')} FROM #{table['name']}"
    if (ids)
      query << "WHERE id IN (#{ids.join(',')})"
    end
    query
  end

  def table_columns(table)
    ['id','name']
  end

  def table_ids(table)
    nil
  end
end

DBCleaner.new.extract
