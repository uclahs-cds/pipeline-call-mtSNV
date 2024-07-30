String indexFile(String file_name) {
    def index_extension_map = [
        '.bam' : '.bai',
        '.cram' : '.crai'
        ]
    def base_name = file_name.substring(0, file_name.lastIndexOf('.'))
    def file_extension = file_name - base_name
    if (!index_extension_map.containsKey(file_extension)){
        log.error "Invalid file type. ${file_name} is not supported"
        throw new Exception()
        }
    def index_extension = index_extension_map[file_extension]
    def index_file_name = file_name+index_extension

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
        def err_msg = "Index file for ${file_name} not found."
        log.error err_msg
        throw new Exception(err_msg)
        }
    }
