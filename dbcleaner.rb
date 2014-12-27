require_relative 'db_cleaner_util.rb'

class DBCleaner
  include DBCleanerUtil

  def extract
    db_client = get_db_client

    puts "Loading config...\n"
    dbconfig = parse_db_config

    dbconfig["tables"].each do |table|
      puts "Extracting from #{table['name']}\n"
      db_client.query("SELECT * FROM #{table['name']}").each do |row|
        puts "#{row['id']}: #{row['name']}"
      end
    end
  end
end

DBCleaner.new.extract
