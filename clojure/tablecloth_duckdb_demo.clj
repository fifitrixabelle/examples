;; Run with:
;; clj -Sdeps '{:deps {org.clojure/clojure {:mvn/version "1.11.1"}
;;                     org.duckdb/duckdb_jdbc {:mvn/version "1.2.1"}
;;                     com.github.seancorfield/next.jdbc {:mvn/version "1.3.1002"}
;;                     scicloj/tablecloth {:mvn/version "7.029"}}}' \
;;   -M clojure/tablecloth_duckdb_demo.clj

(require '[next.jdbc :as jdbc])
(require '[tablecloth.api :as tc])

(def ds (jdbc/get-datasource {:dbtype "duckdb" :dbname ":memory:"}))

(jdbc/execute! ds ["create table sales(day varchar, category varchar, amount double)"])
(doseq [[d c a] [["2026-02-01" "books" 19.0]
                 ["2026-02-01" "games" 59.0]
                 ["2026-02-02" "books" 24.0]
                 ["2026-02-02" "coffee" 8.5]
                 ["2026-02-03" "hardware" 129.0]
                 ["2026-02-03" "games" 64.0]]]
  (jdbc/execute! ds ["insert into sales values (?, ?, ?)" d c a]))

(def rows
  (jdbc/execute! ds
                 ["select category, round(sum(amount), 2) as revenue, count(*) as orders
                   from sales
                   group by category
                   order by revenue desc"]))

(def table (tc/dataset rows))

(println "Clojure Tablecloth + DuckDB Demo")
(println "-------------------------------")
(println table)
