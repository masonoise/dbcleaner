require_relative '../dbextractor.rb'
require_relative 'factories.rb'
include Factories

describe DBExtractor do
  let (:table) { { 'name' => "students", 'ids' => [1,2], 'columns' => ["first_name", "last_name"] } }
  let (:table_no_columns) { { 'name' => "students", 'ids' => [1,2] } }
  let (:table_no_ids) { { 'name' => "students", 'columns' => ["first_name", "last_name"] } }
  let (:table_no_ids_or_columns) { { 'name' => "students" } }
  let (:table_with_association) { { 'name' => "students", 'associations' => [ { :name => 'courses' } ]  } }
  @dbextractor = nil

  before :all do
    @dbextractor = DBExtractor.new
    @dbextractor.set_key('database/db', 'test_dbextractor')
    @dbextractor.set_config_path('./test_db_config.json')
  end

  #---------------------------------------------------------
  context "handling column values" do

    it "should put varchar values in quotes" do
      expect(@dbextractor.make_val('Foobar', 'varchar')).to eq("'Foobar'")
    end

    it "should put text values in quotes" do
      expect(@dbextractor.make_val('Foobar', 'text')).to eq("'Foobar'")
    end

    it "should escape single quotes in text values" do
      expect(@dbextractor.make_val("Foo's bar", 'text')).to eq("'Foo\\'s bar'")
    end

    it "should replace empty values with NULL" do
      expect(@dbextractor.make_val(nil, 'varchar')).to eq("NULL")
      expect(@dbextractor.make_val(nil, 'int')).to eq("NULL")
      expect(@dbextractor.make_val(nil, 'tinyint')).to eq("NULL")
      expect(@dbextractor.make_val(nil, 'datetime')).to eq("NULL")
    end

    it "should pass integers through unchanged" do
      expect(@dbextractor.make_val(5, 'int')).to eq(5)
    end

    it "should handle datetime values" do
      expect(@dbextractor.make_val('2014-12-25 11:11:11 -0500', 'datetime')).to eq("'2014-12-25 11:11:11'")
    end

    it "should handle decimal values" do
      expect(@dbextractor.make_val(41.2318, 'decimal')).to eq(41.2318)
    end

    it "should handle blob values" do
      expect(@dbextractor.make_val('foobar', 'blob')).to eq("'foobar'")
    end
  end

  #---------------------------------------------------------
  context "specifying a table" do

    it "should return a list of columns with types" do
      columns = @dbextractor.table_columns(table)
      expect(columns).to eq({ 'last_name' => 'varchar', 'first_name' => 'varchar' })
    end

    it "should return all columns if no columns specified" do
      columns = @dbextractor.table_columns(table_no_columns)
      expect(columns).to eq({ 'id' => 'int', 'last_name' => 'varchar', 'first_name' => 'varchar',
          "created_at"=>"datetime", "active"=>"int", "comments"=>"text", "tuition"=>"decimal",
          "stuff"=>"blob" })
    end

    it "should return a list of desired ids" do
      ids = @dbextractor.table_ids(table)
      expect(ids).to match_array([2,1])
    end

    it "should return nil if no list of ids is specified" do
      ids = @dbextractor.table_ids(table_no_ids)
      expect(ids).to be(nil)
    end

    context "when generating a query" do
      it "should make a good query with no ids or columns specified" do
        expect(@dbextractor.table_query(table_no_ids_or_columns,
            @dbextractor.table_columns(table_no_ids_or_columns),
            @dbextractor.table_ids(table_no_ids_or_columns))).to eq('SELECT id,first_name,last_name,created_at,active,comments,tuition,stuff FROM students')
      end

      it "should make a good query with no ids specified" do
        expect(@dbextractor.table_query(table_no_ids,
            @dbextractor.table_columns(table_no_ids),
            @dbextractor.table_ids(table_no_ids))).to eq('SELECT first_name,last_name FROM students')
      end

      it "should make a good query with no columns specified" do
        expect(@dbextractor.table_query(table_no_columns,
            @dbextractor.table_columns(table_no_columns),
            @dbextractor.table_ids(table_no_columns))).to eq('SELECT id,first_name,last_name,created_at,active,comments,tuition,stuff FROM students WHERE id IN (1,2)')
      end

      it "should make a good query with ids and columns specified" do
        expect(@dbextractor.table_query(table,
            @dbextractor.table_columns(table),
            @dbextractor.table_ids(table))).to eq('SELECT first_name,last_name FROM students WHERE id IN (1,2)')
      end
    end

  end # context specifying a table

  #---------------------------------------------------------
  context "extracting from a table" do
    before(:all) do
      @student1 = create_student(@dbextractor.db_client,
          { :id => 1, :first_name => 'Bob', :last_name => 'Smith', :created_at => '2014-12-25 11:11:11' })
      @student2 = create_student(@dbextractor.db_client,
          { :id => 2, :first_name => 'John', :last_name => 'Jones', :created_at => 'NULL' })
    end
    after(:all) do
      @dbextractor.db_client.query('DELETE FROM students')
    end

    it "should generate create table command" do
      create_string = "CREATE TABLE `students` (\n  `id` int(11) NOT NULL AUTO_INCREMENT,\n  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,\n  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,\n  `created_at` datetime DEFAULT NULL,\n  `active` tinyint(1) DEFAULT '0',\n  `comments` text COLLATE utf8_unicode_ci,\n  `tuition` decimal(10,0) DEFAULT NULL,\n  `stuff` blob,\n  PRIMARY KEY (`id`)\n) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci;"
      expect(@dbextractor.create_table(table)).to eq(create_string)
    end

    it "should generate insert statement given columns and ids" do
      columns = @dbextractor.table_columns(table)
      ids = [1]
      query = @dbextractor.table_query(table, columns, ids)
      results = @dbextractor.db_client.query(query)
      insert_string = "INSERT INTO students (first_name,last_name) VALUES ('Bob','Smith');\n"
      expect(results.count).to eq(1)
      expect(@dbextractor.make_insert(table, columns, results.fields, results.first)).to eq(insert_string)
    end

    it "should generate insert statement given columns and no ids" do
      columns = @dbextractor.table_columns(table)
      query = @dbextractor.table_query(table, columns, nil)
      results = @dbextractor.db_client.query(query)
      expect(results.count).to eq(2)
      insert_string = []
      insert_string[0] = "INSERT INTO students (first_name,last_name) VALUES ('Bob','Smith');\n"
      insert_string[1] = "INSERT INTO students (first_name,last_name) VALUES ('John','Jones');\n"
      results.each_with_index do |result,i|
        expect(@dbextractor.make_insert(table, columns, results.fields, result)).to eq(insert_string[i])
      end
    end

    it "should generate insert statement given no columns or ids" do
      columns = @dbextractor.table_columns(table_no_columns)
      query = @dbextractor.table_query(table, columns, nil)
      results = @dbextractor.db_client.query(query)
      expect(results.count).to eq(2)
      insert_string = []
      insert_string[0] = "INSERT INTO students (id,first_name,last_name,created_at,active,comments,tuition,stuff) VALUES (1,'Bob','Smith','2014-12-25 11:11:11',0,NULL,NULL,NULL);\n"
      insert_string[1] = "INSERT INTO students (id,first_name,last_name,created_at,active,comments,tuition,stuff) VALUES (2,'John','Jones',NULL,0,NULL,NULL,NULL);\n"
      results.each_with_index do |result,i|
        expect(@dbextractor.make_insert(table, columns, results.fields, result)).to eq(insert_string[i])
      end
    end

  end # context extracting from a table

  #---------------------------------------------------------
  context "when a table has associations" do

    it "should call extract_associations with the array of associations for the table" do
      dbextractor = DBExtractor.new
      dbc = spy(dbextractor)
      expect(dbc).to have_received(:extract_associations).with([{ :name => 'courses' }])
      dbc.extract_table(table_with_association)
    end
  end

end
