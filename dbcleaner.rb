require 'pry'
require_relative 'db_cleaner_util.rb'

class DBCleaner
  include DBCleanerUtil

  # These are the column types that we know how to handle, normalized (for example,
  # varchar(255) becomes simply varchar, and so on).
  COLUMN_TYPES = %w(varchar int tinyint text datetime decimal blob)

  @db_client = nil
  def db_client
    @db_client ||= get_db_client
  end

  @config_path = "./db_config.json"
  def set_config_path(new_config_path)
    @config_path = new_config_path
  end

  #
  # Main method, call this to execute the DBCleaner extraction based on the db_config.json file.
  #
  def extract(outfile_path = 'dbcleaner_output.sql')
    @outfile = open(outfile_path, 'w')
    puts "Loading config...\n"
    dbconfig = parse_db_config(@config_path)

    extract_tables(dbconfig["tables"])
    @outfile.close
  end

  #
  # Loops through each table in the config, and extracts it.
  #
  def extract_tables(tables)
    puts "Extracting #{tables.count} tables..."
    tables.each do |table|
      extract_table(table)
    end
  end

  #
  # For a given table, figure out the columns and types, determine which columns and
  # ids are desired, construct the query, and then create an INSERT statement for each
  # row.
  #
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

  #
  # Generate the CREATE TABLE statement for this table.
  #
  def create_table(table)
    db_client.query("SHOW CREATE TABLE #{table['name']}").first['Create Table'] + ';'
  end

  #
  # Generate the INSERT statement for the given row
  #
  def make_insert(table, columns, fields, row)
    statement = "INSERT INTO #{table['name']} (#{fields.join(',')}) VALUES ("
    values = []
    fields.each do |field|
      values << make_val(row[field], columns[field])
    end
    statement << "#{values.join(',')});\n"
    statement
  end

  #
  # Generate a string with the value of the given column, based on the column type.
  # Sometimes needs to tweak a given value to put quotes around it or modify it slightly.
  #
  def make_val(row_value, column_type)
    val = row_value
    if (row_value.nil?)
      val = 'NULL'
    else
      val = "'#{row_value}'" if (column_type == 'varchar' || column_type == 'text' || column_type == 'blob')
      # datetime values come back like '2014-12-25 11:11:11 -0500' and we want to remove the timezone offset
      if (column_type == 'datetime')
        val = "'#{/(\S* \S*) .*/.match(val.to_s)[1]}'"
      end
    end
    val
  end

  #
  # Generate the SELECT based on the columns and ids desired.
  #
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
        t = 'decimal' if t.start_with?('decimal')
        t = 'int' if (t.start_with?('int') || t.start_with?('tinyint') || t.start_with?('bigint') || t.start_with?('smallint'))
        if !(COLUMN_TYPES.include?(t))
          raise "Unknown column type #{t}, exiting."
        end
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
