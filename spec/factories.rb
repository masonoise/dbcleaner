require 'mysql2'

module Factories

  def create_student(db_client, opts = {})
    student = OpenStruct.new
    student.id = opts[:id] || 1
    student.first_name = opts[:first_name] || "John"
    student.last_name = opts[:last_name] || "Doe"
    if (opts[:created_at])
      if (opts[:created_at] == 'NULL')
        student.created_at = 'NULL'
      else
        student.created_at = "'#{opts[:created_at]}'"
      end
    else
      student.created_at = "'#{Time.new.strftime("%Y-%m-%d %H:%M:%S")}'"
    end
    student.active = opts[:active] || 'FALSE'
    if (opts[:comments])
      student.comments = "'#{opts[:comments]}'"
    else
      student.comments = "NULL"
    end
    query = <<SQL
INSERT INTO students (id,first_name,last_name,created_at,active,comments) VALUES \
(#{student.id},'#{student.first_name}','#{student.last_name}',\
#{student.created_at},#{student.active},#{student.comments})
SQL
    db_client.query(query)
    student
  end

  def create_course(db_client, opts = {})
    course = OpenStruct.new
    course.id = opts[:id] || 1
    course.title = opts[:title] || "New Course"
    course.student_id = opts[:student_id] || 1
      query = <<SQL
INSERT INTO courses (id,title,student_id) VALUES \
(#{course.id},'#{course.title}','#{course.student_id}')
SQL
    db_client.query(query)
    course
  end

end