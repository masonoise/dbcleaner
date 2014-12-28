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
  end

  context "specifying a table" do

    it "should return a list of columns" do
      columns = @dbcleaner.table_columns(table)
      expect(columns).to match_array(['last_name', 'first_name'])
    end

    it "should return star if no columns specified" do
      columns = @dbcleaner.table_columns(table_no_columns)
      expect(columns).to match_array(['*'])
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
            @dbcleaner.table_ids(table_no_ids_or_columns))).to eq('SELECT * FROM students')
      end

      it "should make a good query with no ids specified" do
        expect(@dbcleaner.table_query(table_no_ids,
            @dbcleaner.table_columns(table_no_ids),
            @dbcleaner.table_ids(table_no_ids))).to eq('SELECT first_name,last_name FROM students')
      end

      it "should make a good query with no columns specified" do
        expect(@dbcleaner.table_query(table_no_columns,
            @dbcleaner.table_columns(table_no_columns),
            @dbcleaner.table_ids(table_no_columns))).to eq('SELECT * FROM students WHERE id IN (1,2)')
      end

      it "should make a good query with ids and columns specified" do
        expect(@dbcleaner.table_query(table,
            @dbcleaner.table_columns(table),
            @dbcleaner.table_ids(table))).to eq('SELECT first_name,last_name FROM students WHERE id IN (1,2)')
      end
    end

  end # context specifying a table

  context "extracting from a table" do
    before :all do
      @student1 = create_student(@dbcleaner.db_client, { :id => 1, :first_name => 'Bob', :last_name => 'Smith' })
      @student2 = create_student(@dbcleaner.db_client, { :id => 2, :first_name => 'John', :last_name => 'Jones' })
    end

    it "should generate create table command" do
      create_string = "CREATE TABLE `students` (\n  `id` int(11) NOT NULL AUTO_INCREMENT,\n  `first_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,\n  `last_name` varchar(255) COLLATE utf8_unicode_ci DEFAULT NULL,\n  PRIMARY KEY (`id`)\n) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8 COLLATE=utf8_unicode_ci"
      expect(@dbcleaner.create_table(table)).to eq(create_string)
    end

    it "should generate insert statement given columns and ids" do
      columns = ['first_name','last_name']
      ids = [1]
      insert_string = "INSERT INTO students (first_name,last_name) VALUES ('Bob','Smith')"
      query = @dbcleaner.table_query(table, columns, ids)
      results = @dbcleaner.db_client.query(query)
      expect(results.count).to eq(1)
      expect(@dbcleaner.make_insert(table, results.fields, results.first)).to eq(insert_string)
    end

    it "should generate insert statement given columns and no ids" do
    end

    it "should generate insert statement given no columns or ids" do
    end

  end # context extracting from a table

end
