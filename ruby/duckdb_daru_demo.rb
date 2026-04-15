# frozen_string_literal: true

# Run with:
#   gem install duckdb daru
#   ruby duckdb_daru_demo.rb

begin
  require 'duckdb'
  require 'daru'
rescue LoadError
  warn 'Missing gems. Install with: gem install duckdb daru'
  exit 1
end

db = DuckDB::Database.open
conn = db.connect

conn.query('CREATE TABLE sales(day DATE, category VARCHAR, amount DOUBLE)')
[
  ['2026-02-01', 'books', 19.0],
  ['2026-02-01', 'games', 59.0],
  ['2026-02-02', 'coffee', 8.5],
  ['2026-02-02', 'books', 24.0],
  ['2026-02-03', 'hardware', 129.0],
  ['2026-02-03', 'games', 64.0]
].each do |day, category, amount|
  conn.query("INSERT INTO sales VALUES ('#{day}', '#{category}', #{amount})")
end

rows = conn.query(<<~SQL).to_a
  SELECT category, ROUND(SUM(amount), 2) AS revenue, COUNT(*) AS orders
  FROM sales
  GROUP BY category
  ORDER BY revenue DESC
SQL

df = Daru::DataFrame.rows(rows, order: %i[category revenue orders])
puts 'Ruby DuckDB + Daru Demo'
puts '------------------------'
puts df
