// we can share here

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

    ch_input = channel.fromSRA(params.data)
        | view

    ch_reference = channel.fromSRA(params.reference)
        | view    
}

process fetch_reference {
    input:
      val accession

    output:
      path "foo.txt"

    script:
    """
    esearch -db nucleotide -query "$accession" \\
        | efetch -format fasta > "${accession}.fasta"
    """
}
 

