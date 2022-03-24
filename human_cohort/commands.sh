
### import paired end sequences
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path raw/manifest.txt \
  --output-path seqs/paired-end-demux.qza \
  --input-format PairedEndFastqManifestPhred33V2
  
qiime demux summarize \
  --i-data seqs/paired-end-demux.qza \
  --o-visualization seqs/paired-end-demux.qzv

### Join paired end sequences
qiime vsearch join-pairs \
  --i-demultiplexed-seqs seqs/paired-end-demux.qza \
  --p-maxmergelen 260 \
  --o-joined-sequences seqs/joined-seqs.qza \
  --verbose

### Deblur denoise
qiime deblur denoise-16S \
  --i-demultiplexed-seqs seqs/joined-seqs.qza \
  --p-trim-length 250 \
  --o-representative-sequences seqs/rep-seqs.qza \
  --o-table feature_tables/table.qza \
  --p-sample-stats \
  --p-jobs-to-start 24 \
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

mkdir trees
mv sepp-refs-gg-13-8.qza trees/

qiime fragment-insertion sepp \
  --i-representative-sequences seqs/rep-seqs.qza \
  --i-reference-database trees/sepp-refs-gg-13-8.qza \
  --p-threads 24 \
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
  --p-n-jobs 24 \
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
 --o-filtered-table feature_tables/final-table.qza

qiime feature-table summarize \
  --i-table feature_tables/final-table.qza \
  --o-visualization feature_tables/final-table.qzv \
  --m-sample-metadata-file metadata/metadata.txt

### Create taxa barplot
qiime taxa barplot \
  --i-table feature_tables/final-table.qza \
  --i-taxonomy taxonomy/taxonomy-gg-99.qza \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization taxonomy/taxa-bar-plots-gg-99.qzv

### Perform alpha rarefaction to determine potential rarefaction depth
mkdir rarefaction
qiime diversity alpha-rarefaction \
  --i-table feature_tables/final-table.qza \
  --i-phylogeny trees/fragment_insertion_out/tree.qza \
  --p-max-depth 80000 \
  --p-min-depth 10000 \
  --m-metadata-file metadata/metadata.txt \
  --o-visualization rarefaction/alpha-rarefaction-80000.qzv  

### Filter samples with <40k features
qiime feature-table filter-samples \
  --i-table feature_tables/final-table.qza \
  --p-min-frequency 40000 \
  --o-filtered-table feature_tables/final-table-40000.qza

qiime feature-table summarize \
  --i-table feature_tables/final-table-40000.qza \
  --o-visualization feature_tables/final-table-40000.qzv \
  --m-sample-metadata-file metadata/metadata.txt

### Create species level tables
qiime taxa collapse \
 --i-table feature_tables/final-table-40000.qza \
 --i-taxonomy taxonomy/taxonomy-gg-99.qza \
 --p-level 7 \
 --o-collapsed-table feature_tables/species-final-table-40000.qza



