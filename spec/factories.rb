require 'mysql2'

module Factories

  def create_student(db_client, opts = {})
    student = OpenStruct.new
    student.id = opts[:id] || 1
    student.first_name = opts[:first_name] || "John"
    student.last_name = opts[:last_name] || "Doe"
    query = "INSERT INTO students (id,first_name,last_name) VALUES (#{student.id},'#{student.first_name}','#{student.last_name}')"
    db_client.query(query)
    student
  end

end