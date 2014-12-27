module DBCleanerUtil
  require 'mysql2'
  require 'json'
  require_relative 'configurator.rb'
  include Configurator

  def parse_db_config
    JSON.parse(File.read('db_config.json'))
  end

  def get_db_client
    Mysql2::Client.new(:host => configuration('database/host'),
          :username => configuration('database/user'),
          :database => configuration('database/db'))
  end

end
