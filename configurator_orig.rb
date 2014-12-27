#
# Copy this to configurator.rb and replace configs with your own correct settings.
#
module Configurator
  Configs = {
    "database/host" => "YOUR DB HOST",
    "database/user" => "YOUR USER",
    "database/db" => "YOUR DATABASE"
  }

  def configuration(key)
    Configs[key]
  end
end
