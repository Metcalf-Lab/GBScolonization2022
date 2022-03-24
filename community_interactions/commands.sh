# Create metabolic models using CarveME from NCBI RefSeq genomes
carve AM_genome_assemblies_prot_fasta/ncbi-genomes-2022-01-13/GCF_000020225.1_ASM2022v1_protein.faa -o AM_model.xml -u gramneg
carve GBS_genome_assemblies_prot_fasta/ncbi-genomes-2022-01-13/GCF_015221735.2_ASM1522173v2_protein.faa -o GBS_model.xml -u grampos

# Run SMETANA to compute cooperation and competition metrics
smetana AM_model.xml GBS_model.xml -g -v --molweight  --exclude inorganic.txt 
smetana AM_model.xml GBS_model.xml -d -v --molweight  --exclude inorganic.txt 

