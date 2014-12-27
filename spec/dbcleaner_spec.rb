require_relative '../dbcleaner.rb'

describe DBCleaner do

  context "with a table specified" do
    let (:table) { { 'name' => "students", 'ids' => [1,2], 'columns' => ["first_name", "last_name"] } }
    let (:table_no_columns) { { 'name' => "students", 'ids' => [1,2] } }
    let (:table_no_ids) { { 'name' => "students", 'columns' => ["first_name", "last_name"] } }
    let (:table_no_ids_or_columns) { { 'name' => "students" } }
    let (:dbcleaner) { DBCleaner.new }

    it "should return a list of columns" do
      columns = dbcleaner.table_columns(table)
      expect(columns).to match_array(['last_name', 'first_name'])
    end

    it "should return star if no columns specified" do
      columns = dbcleaner.table_columns(table_no_columns)
      expect(columns).to match_array(['*'])
    end

    it "should return a list of desired ids" do
      ids = dbcleaner.table_ids(table)
      expect(ids).to match_array([2,1])
    end

    it "should return nil if no list of ids is specified" do
      ids = dbcleaner.table_ids(table_no_ids)
      expect(ids).to be(nil)
    end

    context "when generating a query" do
      it "should make a good query with no ids or columns specified" do
        expect(dbcleaner.table_query(table_no_ids_or_columns,
            dbcleaner.table_columns(table_no_ids_or_columns),
            dbcleaner.table_ids(table_no_ids_or_columns))).to eq('SELECT * FROM students')
      end

      it "should make a good query with no ids specified" do
        expect(dbcleaner.table_query(table_no_ids,
            dbcleaner.table_columns(table_no_ids),
            dbcleaner.table_ids(table_no_ids))).to eq('SELECT first_name,last_name FROM students')
      end

      it "should make a good query with no columns specified" do
        expect(dbcleaner.table_query(table_no_columns,
            dbcleaner.table_columns(table_no_columns),
            dbcleaner.table_ids(table_no_columns))).to eq('SELECT * FROM students WHERE id IN (1,2)')
      end

      it "should make a good query with ids and columns specified" do
        expect(dbcleaner.table_query(table,
            dbcleaner.table_columns(table),
            dbcleaner.table_ids(table))).to eq('SELECT first_name,last_name FROM students WHERE id IN (1,2)')
      end
    end

  end
end
