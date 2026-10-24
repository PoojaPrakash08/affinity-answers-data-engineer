
-- Query 1: Count distinct Acacia species

SELECT COUNT(DISTINCT species) AS acacia_species_count
FROM taxonomy
WHERE species LIKE 'Acacia %';


-- Query 2: Find the longest sequence for a wheat species

SELECT
    t.species AS wheat_type,
    r.rfamseq_acc AS sequence_accession,
    r.length AS sequence_length
FROM rfamseq AS r
JOIN taxonomy AS t
    ON r.ncbi_id = t.ncbi_id
WHERE t.species LIKE 'Triticum %'
ORDER BY r.length DESC
LIMIT 1;


-- Query 3: Find Rfam families associated with sequences
-- longer than 1,000,000 bases.
-- Return 15 rows after skipping the first 120 results.

SELECT
    f.rfam_acc AS family_accession,
    f.rfam_id AS family_name,
    MAX(rs.length) AS max_sequence_length
FROM family AS f
JOIN full_region AS fr
    ON fr.rfam_acc = f.rfam_acc
JOIN rfamseq AS rs
    ON rs.rfamseq_acc = fr.rfamseq_acc
WHERE rs.mol_type IN ('DNA', 'genomic DNA')
GROUP BY
    f.rfam_acc,
    f.rfam_id
HAVING MAX(rs.length) > 1000000
ORDER BY
    max_sequence_length DESC,
    f.rfam_acc ASC
LIMIT 15 OFFSET 120;
