//> using scala "3.3.1"
//> using dep "org.duckdb:duckdb_jdbc:1.5.2.0"
//> using dep "tech.tablesaw:tablesaw-core:0.44.4"

import java.sql.DriverManager
import tech.tablesaw.api.{DoubleColumn, IntColumn, StringColumn, Table}

val conn = DriverManager.getConnection("jdbc:duckdb:")
val stmt = conn.createStatement()

stmt.execute("create table sales(day varchar, category varchar, amount double)")
stmt.execute("insert into sales values ('2026-02-01','books',19.0)")
stmt.execute("insert into sales values ('2026-02-01','games',59.0)")
stmt.execute("insert into sales values ('2026-02-02','books',24.0)")
stmt.execute("insert into sales values ('2026-02-02','coffee',8.5)")
stmt.execute("insert into sales values ('2026-02-03','hardware',129.0)")
stmt.execute("insert into sales values ('2026-02-03','games',64.0)")

val rs = stmt.executeQuery(
  """
  select category, round(sum(amount), 2) as revenue, count(*) as orders
  from sales
  group by category
  order by revenue desc
  """
)

val categoryCol = StringColumn.create("category")
val revenueCol = DoubleColumn.create("revenue")
val orderCol = IntColumn.create("orders")

while rs.next() do
  categoryCol.append(rs.getString("category"))
  revenueCol.append(rs.getDouble("revenue"))
  orderCol.append(rs.getInt("orders"))

val table = Table.create("Scala DuckDB + Tablesaw Demo", categoryCol, revenueCol, orderCol)
println(table.print())

rs.close()
stmt.close()
conn.close()
