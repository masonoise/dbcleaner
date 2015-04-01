module DBExtractorUtil
  require 'mysql2'
  require 'json'
  require_relative 'configurator.rb'
  include Configurator

  def parse_db_config(config_path)
    JSON.parse(File.read(config_path))
  end

  def get_db_client
    Mysql2::Client.new(:host => configuration('database/host'),
          :username => configuration('database/user'),
          :database => configuration('database/db'))
  end

end
