// we can share here
// bash line: nextflow run main.nf  --reference NC_000913.3 --data "data/samples/*_R{1,2}.fq"

params.reference = null
params.data = null
// sets a default out directory
params.out = "data_out"


workflow {
    if (params.reference == null) {
        println ("reference NULL")
        exit 1
    }

    if (params.data == null) {
        println ("data NULL")
        exit 1
    }

    println("$params.reference, $params.data, $params.out")

    // def ch_input = channel.fromSRA(params.data, apiKey: "d5822ef54698cb072e0cf866736fd5f6ab08")
        
    def ch_reference = fetch_reference(params.reference)

    def ch_input = channel.fromFilePairs(params.data) | view
        
    fastp(ch_input).sample_ID  
        | view      
}
// process to fetch ref seq
process fetch_reference {
    conda "bioconda::entrez-direct=24.0"

    input:
      val accession

    output:
      path "${accession}.fasta"

    script:
    """
    esearch -db nucleotide -query "$accession" \\
        | efetch -format fasta > "${accession}.fasta"
    """
    
}

process fetch_data {
conda "bioconda::sra-tools=3.2.1"

input:
val sra_num

output:
path "*.fastq.gz"

script:
"""
prefetch "$sra_num"
"""
}

// process to make fastp trimming
process fastp {
    //conda "bioconda::fastp=1.1.0"
    input:
        val sample_data

    output:
        path "*.trimmed.fq.gz" , emit: sample_ID //tuple (val(sample_ID), path("*.trimmed.fq.gz)) suggested output name
        path "*.html" , emit: html_reports
        path "*.json" , emit: json_reports

    script:
    //unpack gz with groovey script
    // [sample_ID,[R1.R2]]
    
    sample_ID = sample_data[0]
    read1 = sample_data[1][0]
    read2 = sample_data[1][1]

    """
      
    fastp --in1 ${read1} --in2 ${read2} --out1 ${sample_ID}_R1.trimmed.fq.gz --out2 ${sample_ID}_R2.trimmed.fq.gz
    """
}


//process to fastqc
process fastqc{
    conda "bioconda::fastqc=0.12.1"

    input: 
        val fastq_data
    //tuple (val (fastq_data), path('*.fastq.gz'))

    output:
        path "fastqc_reports"

    script:
    sample_id = fastq_data[0]
    read1 = fastq_data[1][0]
    read2 = fastq_data[1][1]
    
    """
    fastqc ${read1} ${read2} --outdir fastqc_reports/${sample_id}.html
    """
}


 