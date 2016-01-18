require '/home/oraadmin/ora-hydra/lib/ora/add_large_file.rb'
include Ora


module Ora

  module_function

  # Adds a large file to the UUID of the specified record in ORA
  # Params:

  def addLargeFiletoUUID(pid, filepath)
    addLargeFile(pid,filepath)
    print "File Uploaded successfully!"
  end #addLargeFiletoUUID

end #module ORA
