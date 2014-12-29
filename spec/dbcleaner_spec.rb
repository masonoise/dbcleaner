require_relative '../dbcleaner.rb'
require_relative 'factories.rb'
include Factories

describe DBCleaner do
  let (:table) { { 'name' => "students", 'ids' => [1,2], 'columns' => ["first_name", "last_name"] } }
  let (:table_no_columns) { { 'name' => "students", 'ids' => [1,2] } }
  let (:table_no_ids) { { 'name' => "students", 'columns' => ["first_name", "last_name"] } }
  let (:table_no_ids_or_columns) { { 'name' => "students" } }
  @dbcleaner = nil

  before :all do
    @dbcleaner = DBCleaner.new
    @dbcleaner.set_key('database/db', 'test_dbcleaner')
    @dbcleaner.set_config_path('./test_db_config.json')
  end

  context "handling column values" do

    it "should put varchar values in quotes" do
      expect(@dbcleaner.make_val('Foobar', 'varchar')).to eq("'Foobar'")
    end

    it "should put text values in quotes" do
      expect(@dbcleaner.make_val('Foobar', 'text')).to eq("'Foobar'")
    end

    it "should replace empty values with NULL" do
      expect(@dbcleaner.make_val(nil, 'varchar')).to eq("NULL")
      expect(@dbcleaner.make_val(nil, 'int')).to eq("NULL")
      expect(@dbcleaner.make_val(nil, 'tinyint')).to eq("NULL")
      expect(@dbcleaner.make_val(nil, 'datetime')).to eq("NULL")
    end

    it "should pass integers through unchanged" do
      expect(@dbcleaner.make_val(5, 'int')).to eq(5)
    end

    it "should handle datetime values" do
      expect(@dbcleaner.make_val('2014-12-25 11:11:11 -0500', 'datetime')).to eq("'2014-12-25 11:11:11'")
    end

    it "should handle decimal values" do
      expect(@dbcleaner.make_val(41.2318, 'decimal')).to eq(41.2318)
    end

    it "should handle blob values" do
      expect(@dbcleaner.make_val('foobar', 'blob')).to eq("'foobar'")
    end
  end

  context "specifying a table" do

    it "should return a list of columns with types" do
      columns = @dbcleaner.table_columns(table)
      expect(columns).to eq({ 'last_name' => 'varchar', 'first_name' => 'varchar' })
    end

    it "should return all columns if no columns specified" do
      columns = @dbcleaner.table_columns(table_no_columns)
      expect(columns).to eq({ 'id' => 'int', 'last_name' => 'varchar', 'first_name' => 'varchar',
          "created_at"=>"datetime", "active"=>"int", "comments"=>"text", "tuition"=>"decimal",
          "stuff"=>"blob" })
    end

    it "should return a list of desired ids" do
      ids = @dbcleaner.table_ids(table)
      expect(ids).to match_array([2,1])
    end

    it "should return nil if no list of ids is specified" do
      ids = @dbcleaner.table_ids(table_no_ids)
      expect(ids).to be(nil)
    end

    context "when generating a query" do
      it "should make a good query with no ids or columns specified" do
        expect(@dbcleaner.table_query(table_no_ids_or_columns,
            @dbcleaner.table_columns(table_no_ids_or_columns),
            @dbcleaner.table_ids(table_no_ids_or_columns))).to eq('SELECT id,first_name,last_name,created_at,active,comments,tuition,stuff FROM students')
      end

      it "should make a good query with no ids specified" do
        expect(@dbcleaner.table_query(table_no_ids,
            @dbcleaner.table_columns(table_no_ids),
            @dbcleaner.table_ids(table_no_ids))).to eq('SELECT first_name,last_name FROM students')
      end

      it "should make a good query with no columns specified" do
        expect(@dbcleaner.table_query(table_no_columns,
            @dbcleaner.table_columns(table_no_columns),
            @dbcleaner.table_ids(table_no_columns))).to eq('SELECT id,first_name,last_name,created_at,active,comments,tuition,stuff FROM students WHERE id IN (1,2)')
      end

      it "should make a good query with ids and columns specified" do
        expect(@dbcleaner.table_query(table,
            @dbcleaner.table_columns(table),
            @dbcleaner.table_ids(table))).to eq('SELECT first_name,last_name FROM students WHERE id IN (1,2)')
      end
    end

  end # context specifying a table

  context "extracting from a table" do
    before(:all) do
      @student1 = create_student(@dbcleaner.db_client,
          { :id => 1, :first_name => 'Bob', :last_name => 'Smith', :created_at => '2014-12-25 11:11:11' })
      @student2 = create_student(@dbcleaner.db_client,
          { :id => 2, :first_name => 'John', :last_name => 'Jones', :created_at => 'NULL' })
    end
    after(:all) do
      @dbcleaner.db_client.query('DELETE FROM students')
    end

    it "should generate create table command" do
      create_string = "CREATE TABLE `students` (\n  `id` int(11) NOT NULL AUTO_INCREMENT,\n  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,\n  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `active` tinyint(1) DEFAULT '0',\n  `comments` text COLLATE utf8_unicode_ci,\n  `tuition` decimal(10,0) DEFAULT NULL,\n  `stuff` blob,\n  PRIMARY KEY (`id`)\n) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
      expect(@dbcleaner.create_table(table)).to eq(create_string)
    end

    it "should generate insert statement given columns and ids" do
      columns = @dbcleaner.table_columns(table)
      ids = [1]
      query = @dbcleaner.table_query(table, columns, ids)
      results = @dbcleaner.db_client.query(query)
      insert_string = "INSERT INTO students (first_name,last_name) VALUES ('Bob','Smith');\n"
      expect(results.count).to eq(1)
      expect(@dbcleaner.make_insert(table, columns, results.fields, results.first)).to eq(insert_string)
    end

    it "should generate insert statement given columns and no ids" do
      columns = @dbcleaner.table_columns(table)
      query = @dbcleaner.table_query(table, columns, nil)
      results = @dbcleaner.db_client.query(query)
      expect(results.count).to eq(2)
      insert_string = []
      insert_string[0] = "INSERT INTO students (first_name,last_name) VALUES ('Bob','Smith');\n"
      insert_string[1] = "INSERT INTO students (first_name,last_name) VALUES ('John','Jones');\n"
      results.each_with_index do |result,i|
        expect(@dbcleaner.make_insert(table, columns, results.fields, result)).to eq(insert_string[i])
      end
    end

    it "should generate insert statement given no columns or ids" do
      columns = @dbcleaner.table_columns(table_no_columns)
      query = @dbcleaner.table_query(table, columns, nil)
      results = @dbcleaner.db_client.query(query)
      expect(results.count).to eq(2)
      insert_string = []
      insert_string[0] = "INSERT INTO students (id,first_name,last_name,created_at,active,comments,tuition,stuff) VALUES (1,'Bob','Smith','2014-12-25 11:11:11',0,NULL,NULL,NULL);\n"
      insert_string[1] = "INSERT INTO students (id,first_name,last_name,created_at,active,comments,tuition,stuff) VALUES (2,'John','Jones',NULL,0,NULL,NULL,NULL);\n"
      results.each_with_index do |result,i|
        expect(@dbcleaner.make_insert(table, columns, results.fields, result)).to eq(insert_string[i])
      end
    end

  end # context extracting from a table

end
