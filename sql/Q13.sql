-- =============================================================
-- Q13: Ιεραρχία εποπτείας κάθε ιατρού (από άμεσο επόπτη μέχρι
--      Διευθυντή). Χρησιμοποιεί Recursive Common Table Expression.
-- =============================================================
USE `ygeiopolis_db`;

WITH RECURSIVE supervisor_chain AS (
  -- Anchor: κάθε ιατρός ως ξεκίνημα της αλυσίδας
  SELECT
    d.amka                                       AS doctor_amka,
    d.amka                                       AS current_amka,
    d.supervisor_amka                            AS supervisor_amka,
    d.rank                                       AS current_rank,
    0                                            AS level
  FROM       doctor d

  UNION ALL

  -- Recursive: ανέβα στην αλυσίδα έως το top
  SELECT
    sc.doctor_amka                               AS doctor_amka,
    d2.amka                                      AS current_amka,
    d2.supervisor_amka                           AS supervisor_amka,
    d2.rank                                      AS current_rank,
    sc.level + 1                                 AS level
  FROM       supervisor_chain sc
  JOIN       doctor d2 ON d2.amka = sc.supervisor_amka
  WHERE      sc.supervisor_amka IS NOT NULL
    AND      sc.level < 10  -- ασφάλεια έναντι κύκλων
)
SELECT
  sc.doctor_amka                                 AS doctor_amka,
  s_doc.first_name                               AS doctor_first_name,
  s_doc.last_name                                AS doctor_last_name,
  d_root.specialty                               AS doctor_specialty,
  d_root.rank                                    AS doctor_rank,
  sc.level                                       AS level,
  sc.current_amka                                AS supervisor_in_chain_amka,
  s_sup.first_name                               AS supervisor_first_name,
  s_sup.last_name                                AS supervisor_last_name,
  sc.current_rank                                AS supervisor_rank
FROM       supervisor_chain sc
JOIN       doctor d_root ON d_root.amka = sc.doctor_amka
JOIN       staff  s_doc  ON s_doc.amka  = sc.doctor_amka
JOIN       staff  s_sup  ON s_sup.amka  = sc.current_amka
WHERE      sc.level > 0  -- εξαιρούμε τον ίδιο τον ιατρό (level 0)
ORDER BY   sc.doctor_amka, sc.level;