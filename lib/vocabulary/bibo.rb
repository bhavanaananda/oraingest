module RDF
  class BIBO < RDF::Vocabulary("http://purl.org/ontology/bibo/")  
    property :abstract  
    property :identifier  
    property :edition  
    property :editor  
    property :doi  
    property :issn  
    property :isbn  
    property :eissn  
    property :pmid  
    property :numPages  
    property :pages  
    property :pageStart  
    property :pageEnd  
    property :Note  
    property :uri  
    property :number  
    property :Journal  
    property :Book  
    property :volume  
    property :issue  
    property :Series  
    property :status  
    property :DocumentStatus  
    property :Document  
    property :Periodical  
    property :annotates  
    property :owner
    property :Proceedings
    property :presentedAt
    property :Organizer
    property :Conference
  end
end
