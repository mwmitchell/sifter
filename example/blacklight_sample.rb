require '../lib/sifter'
require 'marc_helpers'

class BlacklightSample
  
  # the main mapper lib
  include Sifter
  # custom mapper methods
  include MarcHelpers::MapperMethods
  
  # add custom methods to each MARC::Record object
  before { |marc| marc.extend MarcHelpers::Record }
  
  # an "after" event handler for each mapped hash.
  # this removes empty fields,
  # and strips all other values.
  after { |mapped|
    mapped.each_pair { |field,value|
      mapped.delete field and next if value.to_s.empty?
      mapped[field] = clean value
    }
  }
  
  # the following mappings could be pushed into a separate file
  # and loaded via "load_mapping 'my_mappings.rb'" etc,
  
  # stock #map method
  map :source_facet, "Blacklight's MARC test data"
  map :id, :control_code
  map :marc_display, :to_xml
  map :isbn_t, :isbn
  map :language_facet, :languages
  map :format_facet, :format
  map :format_code_t, :format_code
  
  # custom marc mapper from MarcHelpers::MapperMethods
  marc :title_t, %w[245a]
  marc :sub_title_t, %w[245b]
  marc :alt_titles_t, %w[240b 700t 710t 711t 440a 490a 505a 830a]
  marc :title_added_entry_t, %w[700t]
  marc :title_sort, '245a'
  marc :author_t, %w[100a 110a 111a 130a 700a 710a 711a]
  marc :published_t, %w[260a]
  marc :material_type_t, %w[300a]
  marc :subject_t, %w[600a 610a 611a 630a 650a 651a 655a 690a]
  marc :subject_era_facet, %w[650d 650y 651y 655y]
  marc :geographic_subject_facet, %w[650c 650z 651a 651x 651z 655z]
  marc :vern_t, %w[880a 880b 880c 880e 880f 880p 880t]
  
end