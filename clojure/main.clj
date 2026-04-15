(ns main
  (:require [clojure.string :as str]))

(defn paint [code text]
  (str "\u001b[" code "m" text "\u001b[0m"))

(defn step [state]
  (let [next-pos (+ (:pos state) (first (:moves state)))]
    {:pos next-pos
     :moves (rest (:moves state))
     :trail (conj (:trail state) next-pos)}))

(defn render [pos]
  (apply str
         (for [idx (range -5 6)]
           (cond
             (= idx 0) (paint "33" "|")
             (= idx pos) (paint "32" "@")
             :else (paint "34" ".")))))

(let [moves [1 1 -1 2 -2 1 1 -1 2]
      states (take 9 (iterate step {:pos 0 :moves moves :trail [0]}))]
  (println (paint "35" "════════ Clojure Lazy Drift 🧠 ════════"))
  (println (paint "33" "  iterate builds a walk tape one immutable frame at a time"))
  (println)
  (doseq [[idx state] (map-indexed vector states)]
    (println
     (str "  "
          (paint "1" (format "#%d" idx))
          " "
          (render (:pos state))
          " trail="
          (paint "36" (str/join " " (:trail state))))))
  (println)
  (println (str "  final stop: " (paint "32" (-> states last :pos str)))))
