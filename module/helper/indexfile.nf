def indexFile(Object given_file) {
    def index_extension_map = [
        '.bam' : '.bai',
        '.cram' : '.crai'
    ]
    def base_name = given_file.substring(0, given_file.lastIndexOf('.'))
    def file_extension = given_file - base_name
    if (!index_extension_map.containsKey(file_extension)){
        log.error "Invalid file type. ${given_file} is not supported"
        throw new Exception()
        }
    def index_extension = index_extension_map[file_extension]
    def index_file_name = given_file+index_extension

    def index_file = new File(index_file_name)
    if(index_file.exists()) {
        return index_file_name
        }

    index_file_name = base_name+index_extension
    index_file = new File(index_file_name)
    if(index_file.exists()) {
        return index_file_name
        }
    else {
        log.error "Index file for ${given_file} not found."
        throw new Exception()
    }
    }