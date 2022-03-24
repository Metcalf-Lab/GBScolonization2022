
### import paired end sequences
qiime tools import \
 	--type EMPPairedEndSequences \
 	--input-path ../sr13_06282021/raw/seqs/ \
 	--output-path seqs/emp-paired-end-seqs.qza
 
### demultiplex seqs
 qiime demux emp-paired \
  --m-barcodes-file metadata/metadata.txt \
  --m-barcodes-column barcode \
  --p-rev-comp-barcodes \
  --p-rev-comp-mapping-barcodes \
  --i-seqs seqs/emp-paired-end-seqs.qza \
  --o-per-sample-sequences seqs/demux-full.qza \
  --o-error-correction-details seqs/demux-details.qza
  
qiime demux summarize \
  --i-data seqs/demux-full.qza \
  --o-visualization seqs/demux-full.qzv

### Join paired end sequences
qiime vsearch join-pairs \
  --i-demultiplexed-seqs seqs/demux-full.qza \
  --p-maxmergelen 260 \
  --o-joined-sequences seqs/joined-seqs.qza \
  --verbose
  
# Visualize joined seqs
qiime demux summarize \
  --i-data seqs/joined-seqs.qza \
  --o-visualization seqs/joined-seqs.qzv

### Deblur denoise
qiime deblur denoise-16S \
  --i-demultiplexed-seqs seqs/joined-seqs.qza \
  --p-trim-length 250 \
  --o-representative-sequences seqs/rep-seqs.qza \
  --o-table feature_tables/table.qza \
  --p-sample-stats \
  --p-jobs-to-start 4 \
  --o-stats seqs/denoising-stats.qza
  
# Visualize
qiime deblur visualize-stats \
  --i-deblur-stats seqs/denoising-stats.qza \
  --o-visualization seqs/denoising-stats.qzv

qiime feature-table summarize \
  --i-table feature_tables/table.qza \
  --o-visualization feature_tables/table.qzv \
  --m-sample-metadata-file metadata/metadata.txt

qiime feature-table tabulate-seqs \
  --i-data seqs/rep-seqs.qza \
  --o-visualization seqs/rep-seqs.qzv

### SEPP fragment insertion to obtain phylogenetic tree with gg13.8
wget \
  -O "sepp-refs-gg-13-8.qza" \
  "https://data.qiime2.org/2021.2/common/sepp-refs-gg-13-8.qza"

mv sepp-refs-gg-13-8.qza trees/

qiime fragment-insertion sepp \
  --i-representative-sequences seqs/rep-seqs.qza \
  --i-reference-database trees/sepp-refs-gg-13-8.qza \
  --p-threads 4 \
  --output-dir trees/fragment_insertion_out

### Get greengenes v4 classifier and move to appropriate directory
wget \
  -O "gg-13-8-99-515-806-nb-classifier.qza" \
  "https://data.qiime2.org/2021.2/common/gg-13-8-99-515-806-nb-classifier.qza"

mkdir taxonomy
mv gg-13-8-99-515-806-nb-classifier.qza taxonomy/

### GreenGenes 99% Classification (V4)
qiime feature-classifier classify-sklearn \
  --i-classifier taxonomy/gg-13-8-99-515-806-nb-classifier.qza \
  --i-reads seqs/rep-seqs.qza \
  --p-n-jobs -1 \
  --o-classification taxonomy/taxonomy-gg-99.qza

qiime metadata tabulate \
  --m-input-file taxonomy/taxonomy-gg-99.qza \
  --o-visualization taxonomy/taxonomy-gg-99.qzv

### Filter feature table of mitochondria and chloroplast and keep only bacteria
qiime taxa filter-table \
 --i-table feature_tables/table.qza \
 --i-taxonomy taxonomy/taxonomy-gg-99.qza \
 --p-include bacteria \
 --p-exclude mitochondria,chloroplast \
 --o-filtered-table feature_tables/table-gg-99-no-chlo-mito.qza

### Filter features based on frequency to remove features less than 10 times present and not in at least 2 samples
qiime feature-table filter-features \
 --i-table feature_tables/table-gg-99-no-chlo-mito.qza \
 --p-min-frequency 10 \
 --p-min-samples 2 \
 --o-filtered-table feature_tables/final-table-w-con.qza

qiime feature-table summarize \
  --i-table feature_tables/final-table-w-con.qza \
  --o-visualization feature_tables/final-table-w-con.qzv \
  --m-sample-metadata-file metadata/metadata.txt

### Create taxa barplot
qiime taxa barplot \
  --i-table feature_tables/final-table-w-con.qza \
  --i-taxonomy taxonomy/taxonomy-gg-99.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization taxonomy/taxa-bar-plots-gg-99.qzv

### Create control only table
qiime feature-table filter-samples \
  --i-table feature_tables/final-table-w-con.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "sample_type='control'" \
  --o-filtered-table feature_tables/control-table.qza

qiime feature-table summarize \
  --i-table feature_tables/control-table.qza \
  --o-visualization feature_tables/control-table.qzv \
  --m-sample-metadata-file metadata/metadata.txt

### Create taxa barplot of controls
qiime taxa barplot \
  --i-table feature_tables/control-table.qza \
  --i-taxonomy taxonomy/taxonomy-gg-99.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization taxonomy/control-taxa-bar-plots-gg-99.qzv

### Remove controls from table
qiime feature-table filter-samples \
  --i-table feature_tables/final-table-w-con.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "sample_type='control' OR treatment='NA'" \
  --p-exclude-ids \
  --o-filtered-table feature_tables/final-table.qza

qiime feature-table summarize \
  --i-table feature_tables/final-table.qza \
  --o-visualization feature_tables/final-table.qzv \
  --m-sample-metadata-file metadata/metadata.txt
  
### Create day 0 taxa plot
qiime feature-table filter-samples \
  --i-table feature_tables/final-table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "day='0'" \
  --p-min-frequency 3000 \
  --o-filtered-table feature_tables/final-table-day0-3000.qza
  
qiime taxa barplot \
  --i-table feature_tables/final-table-day0-3000.qza \
  --i-taxonomy taxonomy/taxonomy-gg-99.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization taxonomy/taxa-bar-plots-gg-99-day0-3000.qzv

### Create taxa barplot
qiime feature-table filter-samples \
  --i-table feature_tables/final-table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-min-frequency 3000 \
  --o-filtered-table feature_tables/final-table-3000.qza
  
qiime taxa barplot \
  --i-table feature_tables/final-table-3000.qza \
  --i-taxonomy taxonomy/taxonomy-gg-99.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization taxonomy/taxa-bar-plots-gg-99-3000.qzv

############## STOP TO CHECK FEATURE TABLE AND PERFORM RAREFACTION   
  
### Perform alpha rarefaction to determine potential rarefaction depth
qiime diversity alpha-rarefaction \
  --i-table feature_tables/final-table.qza \
  --i-phylogeny trees/fragment_insertion_out/tree.qza \
  --p-max-depth 30000 \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization rarefaction/alpha-rarefaction-30000.qzv  
  
############## STOP TO CHECK RAREFACTION AND PERFORM FILTER AT APPROPIATE DEPTH

#### Core metrics at 3000 rarefaction
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny trees/fragment_insertion_out/tree.qza \
  --i-table feature_tables/final-table.qza \
  --p-sampling-depth 3000 \
  --m-metadata-file metadata/metadata.txt \
  --output-dir core-metrics-results-3000 

mkdir core-metrics-results-3000/alpha_diversity
mkdir core-metrics-results-3000/alpha_diversity/group_signif
mkdir core-metrics-results-3000/alpha_diversity/correlation
mkdir core-metrics-results-3000/beta_diversity
mkdir core-metrics-results-3000/beta_diversity/group_signif
mkdir core-metrics-results-3000/beta_diversity/mantel

mv core-metrics-results-3000/*_vector.qza core-metrics-results-3000/alpha_diversity
mv core-metrics-results-3000/*_emperor.qzv core-metrics-results-3000/beta_diversity
mv core-metrics-results-3000/*_pcoa*.qza core-metrics-results-3000/beta_diversity
mv core-metrics-results-3000/*_matrix.qza core-metrics-results-3000/beta_diversity

## Create day 0 and no day 0 rarified tables
qiime feature-table filter-samples \
  --i-table core-metrics-results-3000/rarefied_table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "day='0'" \
  --o-filtered-table core-metrics-results-3000/day0_rarefied_table.qza

qiime taxa barplot \
  --i-table core-metrics-results-3000/day0_rarefied_table.qza \
  --i-taxonomy taxonomy/taxonomy-gg-99.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization taxonomy/taxa-bar-plots-gg-99-day0-rarefied.qzv

qiime feature-table filter-samples \
  --i-table core-metrics-results-3000/rarefied_table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "day='0'" \
  --p-exclude-ids \
  --o-filtered-table core-metrics-results-3000/no_day0_rarefied_table.qza

#### DAY 0 Core metrics at 3000 rarefaction
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny trees/fragment_insertion_out/tree.qza \
  --i-table core-metrics-results-3000/day0_rarefied_table.qza \
  --p-sampling-depth 3000 \
  --m-metadata-file metadata/metadata.txt \
  --output-dir core-metrics-results-3000/day0_only 

mkdir core-metrics-results-3000/day0_only/alpha_diversity
mkdir core-metrics-results-3000/day0_only/alpha_diversity/group_signif
mkdir core-metrics-results-3000/day0_only/alpha_diversity/correlation
mkdir core-metrics-results-3000/day0_only/beta_diversity
mkdir core-metrics-results-3000/day0_only/beta_diversity/group_signif
mkdir core-metrics-results-3000/day0_only/beta_diversity/mantel

mv core-metrics-results-3000/day0_only/*_vector.qza core-metrics-results-3000/day0_only/alpha_diversity
mv core-metrics-results-3000/day0_only/*_emperor.qzv core-metrics-results-3000/day0_only/beta_diversity
mv core-metrics-results-3000/day0_only/*_pcoa*.qza core-metrics-results-3000/day0_only/beta_diversity
mv core-metrics-results-3000/day0_only/*_matrix.qza core-metrics-results-3000/day0_only/beta_diversity

## Alpha group significance
# Faith's pd
qiime diversity alpha-group-significance \
  --i-alpha-diversity  core-metrics-results-3000/day0_only/alpha_diversity/faith_pd_vector.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization  core-metrics-results-3000/day0_only/alpha_diversity/group_signif/faith-pd-group-significance.qzv

# Peilou's evenness
qiime diversity alpha-group-significance \
  --i-alpha-diversity  core-metrics-results-3000/day0_only/alpha_diversity/evenness_vector.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization  core-metrics-results-3000/day0_only/alpha_diversity/group_signif/evenness-significance.qzv

# Shannon
qiime diversity alpha-group-significance \
  --i-alpha-diversity  core-metrics-results-3000/day0_only/alpha_diversity/shannon_vector.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization  core-metrics-results-3000/day0_only/alpha_diversity/group_signif/shannon-significance.qzv

# Observed OTUs (richness)
qiime diversity alpha-group-significance \
  --i-alpha-diversity  core-metrics-results-3000/day0_only/alpha_diversity/observed_features_vector.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization  core-metrics-results-3000/day0_only/alpha_diversity/group_signif/observed_otus_significance.qzv

## Beta Diversity Group Significance
# Treatment
qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results-3000/day0_only/beta_diversity/unweighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-column treatment \
  --o-visualization core-metrics-results-3000/day0_only/beta_diversity/group_signif/treatment-unweighted-unifrac-significance.qzv \
  --p-pairwise

qiime diversity beta-group-significance \
  --i-distance-matrix core-metrics-results-3000/day0_only/beta_diversity/weighted_unifrac_distance_matrix.qza \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-column treatment \
  --o-visualization core-metrics-results-3000/day0_only/beta_diversity/group_signif/treatment-weighted-unifrac-significance.qzv \
  --p-pairwise  

## ANCOM
# day 0 table
qiime feature-table filter-samples \
  --i-table feature_tables/final-table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "day='0'" \
  --o-filtered-table feature_tables/day0-final-table.qza

### Create control only table
qiime feature-table filter-samples \
  --i-table feature_tables/day0-final-table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-min-frequency 3000 \
  --o-filtered-table feature_tables/day0-final-table-3000.qza
  
# Species
qiime taxa collapse \
 --i-table feature_tables/day0-final-table-3000.qza \
 --i-taxonomy taxonomy/taxonomy-gg-99.qza \
 --p-level 7 \
 --o-collapsed-table feature_tables/species-day0-final-table-3000.qza


qiime composition add-pseudocount \
  --i-table feature_tables/day0-final-table-3000.qza \
  --o-composition-table feature_tables/day0-final-comp-table-3000.qza

qiime composition add-pseudocount \
  --i-table feature_tables/species-day0-final-table-3000.qza \
  --o-composition-table feature_tables/species-day0-final-comp-table-3000.qza

mkdir ancom

qiime composition ancom \
  --i-table feature_tables/day0-final-comp-table-3000.qza \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-column treatment \
  --o-visualization ancom/ancom_day0_treatment-3000.qzv

qiime composition ancom \
  --i-table feature_tables/species-day0-final-comp-table-3000.qza \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-column treatment \
  --o-visualization ancom/species-ancom_day0_treatment-3000.qzv


#### NO DAY 0 Core metrics at 3000 rarefaction
qiime diversity core-metrics-phylogenetic \
  --i-phylogeny trees/fragment_insertion_out/tree.qza \
  --i-table core-metrics-results-3000/no_day0_rarefied_table.qza \
  --p-sampling-depth 3000 \
  --m-metadata-file metadata/metadata.txt \
  --output-dir core-metrics-results-3000/no_day0 

mkdir core-metrics-results-3000/no_day0/alpha_diversity
mkdir core-metrics-results-3000/no_day0/alpha_diversity/group_signif
mkdir core-metrics-results-3000/no_day0/alpha_diversity/correlation
mkdir core-metrics-results-3000/no_day0/beta_diversity
mkdir core-metrics-results-3000/no_day0/beta_diversity/group_signif
mkdir core-metrics-results-3000/no_day0/beta_diversity/mantel

mv core-metrics-results-3000/no_day0/*_vector.qza core-metrics-results-3000/no_day0/alpha_diversity
mv core-metrics-results-3000/no_day0/*_emperor.qzv core-metrics-results-3000/no_day0/beta_diversity
mv core-metrics-results-3000/no_day0/*_pcoa*.qza core-metrics-results-3000/no_day0/beta_diversity
mv core-metrics-results-3000/no_day0/*_matrix.qza core-metrics-results-3000/no_day0/beta_diversity

### Longitudinal
## Collapse rarefied table at species levels
# Species
qiime taxa collapse \
 --i-table core-metrics-results-3000/no_day0_rarefied_table.qza \
 --i-taxonomy taxonomy/taxonomy-gg-99.qza \
 --p-level 7 \
 --o-collapsed-table core-metrics-results-3000/species_no_day0_rarefied_table.qza

## Feature volatility
# Species - no day0
qiime longitudinal feature-volatility \
  --i-table core-metrics-results-3000/species_no_day0_rarefied_table.qza  \
  --m-metadata-file metadata/metadata.txt \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --p-estimator 'RandomForestRegressor' \
  --p-parameter-tuning \
  --p-importance-threshold 'q1' \
  --p-feature-count 100 \
  --p-n-estimators 1000 \
  --p-random-state 999 \
  --p-n-jobs -1 \
  --output-dir longitudinal/no_day0/species-feature-volatility

## Collapse unrarefied table at species levels
# Species
qiime taxa collapse \
 --i-table feature_tables/final-table.qza \
 --i-taxonomy taxonomy/taxonomy-gg-99.qza \
 --p-level 7 \
 --o-collapsed-table feature_tables/species-final-table.qza
 
## Create time groups for linear models
# Filter time series to day 2+
qiime feature-table filter-samples \
  --i-table feature_tables/species-final-table.qza \
  --m-metadata-file metadata/metadata.txt \
  --p-where "day='0'" \
  --p-exclude-ids \
  --o-filtered-table feature_tables/no_day0-species-final-table.qza

# Convert to relative abundances
qiime feature-table relative-frequency \
	--i-table feature_tables/no_day0-species-final-table.qza \
	--o-relative-frequency-table feature_tables/no_day0-species-final-relfreq-table.qza

### LME models
mkdir longitudinal/no_day0/lme longitudinal/all/lme

## PCoA-based volatility
# Unweighted UniFrac
qiime longitudinal volatility \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-file core-metrics-results-3000/no_day0/beta_diversity/unweighted_unifrac_pcoa_results.qza \
  --p-state-column day \
  --p-default-metric 'Axis 1' \
  --p-default-group-column treatment \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/pcoa-vol-unwunifrac.qzv

# Weighted UniFrac
qiime longitudinal volatility \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-file core-metrics-results-3000/no_day0/beta_diversity/weighted_unifrac_pcoa_results.qza \
  --p-state-column day \
  --p-default-metric 'Axis 1' \
  --p-default-group-column treatment \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/pcoa-vol-wunifrac.qzv

## PCOA Axis 1 LME
# Unweighted 
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-file core-metrics-results-3000/no_day0/beta_diversity/unweighted_unifrac_pcoa_results.qza \
  --p-metric 'Axis 1' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/unwunifrac-pc1-distances-LME.qzv

# Weighted 
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-file core-metrics-results-3000/no_day0/beta_diversity/weighted_unifrac_pcoa_results.qza \
  --p-metric 'Axis 1' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/wunifrac-pc1-distances-LME.qzv
  
## Richness
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-file core-metrics-results-3000/no_day0/alpha_diversity/observed_features_vector.qza \
  --p-metric 'observed_features' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/observed_features-LME.qzv

# Shannon's  
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --m-metadata-file core-metrics-results-3000/no_day0/alpha_diversity/shannon_vector.qza \
  --p-metric 'shannon_entropy' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/shannon-LME.qzv



######################################################################
### LMEs with CLR transformation
######################################################################
mkdir longitudinal/no_day0/lme/clr

#import phyloseq biom
biom convert -i feature_tables/species-no_day0-3000-final-table-clr.tsv -o feature_tables/species-no_day0-3000-final-table-clr.biom --table-type="OTU table" --to-hdf5

qiime tools import \
  --input-path feature_tables/species-no_day0-3000-final-table-clr.biom \
  --type 'FeatureTable[RelativeFrequency]' \ # not actually RelFreq but making Q2 think it is so LME runs
  --input-format BIOMV210Format \
  --output-path feature_tables/species-no_day0-3000-final-table-clr.qza

## GBS
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;s__agalactiae' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/GBS-clr-lme.qzv

## Akkerrmansia muciniphila
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Verrucomicrobia;c__Verrucomicrobiae;o__Verrucomicrobiales;f__Verrucomicrobiaceae;g__Akkermansia;s__muciniphila' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Akkermansia_muciniphila-clr-lme.qzv

## k__Bacteria;p__Bacteroidetes;c__Bacteroidia;o__Bacteroidales;f__S24-7;g__;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Bacteroidetes;c__Bacteroidia;o__Bacteroidales;f__S24-7;g__;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Bacteroidales_S24_7-clr-lme.qzv
  
## k__Bacteria;p__Firmicutes;c__Clostridia;o__Clostridiales;f__Peptococcaceae;g__rc4-4;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Clostridia;o__Clostridiales;f__Peptococcaceae;g__rc4-4;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Peptococcaceae_rc4_4-clr-lme.qzv
  
## k__Bacteria;p__Firmicutes;c__Bacilli;o__Bacillales;f__Staphylococcaceae;g__Staphylococcus;__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Bacillales;f__Staphylococcaceae;g__Staphylococcus;__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Staphylococcus-clr-lme.qzv
  
## k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacteriales;f__Enterobacteriaceae;__;__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacteriales;f__Enterobacteriaceae;__;__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Enterobacteriaceae-clr-lme.qzv

## k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Enterococcaceae;g__Enterococcus;__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Enterococcaceae;g__Enterococcus;__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Enterococcus-clr-lme.qzv
  
## k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacteriales;f__Enterobacteriaceae;g__Proteus;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacteriales;f__Enterobacteriaceae;g__Proteus;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Proteus-clr-lme.qzv

## k__Bacteria;p__Actinobacteria;c__Actinobacteria;o__Bifidobacteriales;f__Bifidobacteriaceae;g__Bifidobacterium;s__pseudolongum
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Actinobacteria;c__Actinobacteria;o__Bifidobacteriales;f__Bifidobacteriaceae;g__Bifidobacterium;s__pseudolongum' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Bifidobacterium_pseudolongum-clr-lme.qzv
  
## k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Lactobacillaceae;g__Lactobacillus;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Lactobacillaceae;g__Lactobacillus;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Lactobacillus-clr-lme.qzv
  
## k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Lactobacillaceae;g__Lactobacillus;s__salivarius
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Lactobacillaceae;g__Lactobacillus;s__salivarius' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Lactobacillus_salivarius-clr-lme.qzv
  
## k__Bacteria;p__Firmicutes;c__Bacilli;o__Bacillales;f__Bacillaceae;g__Bacillus;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Bacillales;f__Bacillaceae;g__Bacillus;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Bacillus-clr-lme.qzv

## k__Bacteria;p__Firmicutes;c__Clostridia;o__Clostridiales;f__Ruminococcaceae;g__;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Clostridia;o__Clostridiales;f__Ruminococcaceae;g__;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Ruminococcaceae-clr-lme.qzv
  
## k__Bacteria;p__Actinobacteria;c__Actinobacteria;o__Actinomycetales;f__Corynebacteriaceae;g__Corynebacterium;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Actinobacteria;c__Actinobacteria;o__Actinomycetales;f__Corynebacteriaceae;g__Corynebacterium;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Corynebacterium-clr-lme.qzv
  
## k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Streptococcaceae;g__Streptococcus;__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Streptococcus-clr-lme.qzv
  
## k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacteriales;f__Enterobacteriaceae;g__Morganella;s__morganii
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__Enterobacteriales;f__Enterobacteriaceae;g__Morganella;s__morganii' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Morganella_morganii-clr-lme.qzv

## k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Enterococcaceae;g__Enterococcus;s__
qiime longitudinal linear-mixed-effects \
  --m-metadata-file metadata/metadata.txt \
  --i-table feature_tables/species-no_day0-3000-final-table-clr.qza \
  --p-metric 'k__Bacteria;p__Firmicutes;c__Bacilli;o__Lactobacillales;f__Enterococcaceae;g__Enterococcus;s__' \
  --p-group-columns treatment \
  --p-state-column day \
  --p-individual-id-column mouseid \
  --o-visualization longitudinal/no_day0/lme/clr/Enterococcus_sp-clr-lme.qzv
  





















