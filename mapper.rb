#
# Example:
#
# summary = Mapper.new do
#   
#   def simplify val
#     val.downcase.underscore.gsub(/\W+/, '').gsub(/ /, '').gsub(/\.xml/, '').gsub(/^ +| $/, '')
#   end
#   
#   filter :language_facet do |all|
#     all.map{|l| simplify l }
#   end
#   
#   filter do |doc|
#     doc.each_pair do |key,val|
#       next if val.nil?
#       val.is_a?(Array) ? val.map!{|v|v.strip} : doc[key]=val.strip
#     end
#   end
#   
#   var :title do |xml|
#     xml.xpath('//archdesc[@level="collection"]/did/unittitle').first.text rescue
#       xml.xpath('//archdesc/did/unittitle').first.text rescue
#         'Untitled'
#   end
#   
#   set :format_code_t, 'ead'
#   
# end
# 
# f = 'ead-example.xml'
# doc = Nokogiri::XML(open(f))
# summary.map doc.xpath('//eadheader') do |doc|
#   # result...
# end
#
class Mapper
  
  attr :block
  attr :out
  
  def initialize parent=nil, &b
    @parent = parent
    @block = b
  end
  
  def sets
    @sets ||= []
  end
  
  def map source_items, defaults = {}
    source_items = [source_items] unless source_items.is_a?(Array)
    instance_eval &@block
    @out = []
    source_items.each do |source|
      exec_setups source
      exec_vars source
      @out << item = defaults.dup
      exec_sets source, item
      exec_filters item
      yield item if block_given?
    end
    @out
  end
  
  def exec_filters doc
    filters.each do |args, f|
      if args.empty?
        f.call doc
      else
        args.each do |field|
          doc[field] = f.call(doc[field])
        end
      end
    end
  end
  
  def exec_sets source, item
    sets.each_with_index do |(keys, val), index|
      keys = [keys] unless keys.is_a?(Array)
      keys.each do |key|
        case val
          when Proc
            item[key] = val.arity == 1 ? val.call(source) : val.call
          else
            item[key] = val
          end
      end
    end
  end
  
  def exec_vars source
    vars.each do |(name, val)|
      case val
      when Proc
        instance_variable_set "@#{name}", (val.arity == 1 ? val.call(source) : val.call)
      else
        instance_variable_set "@#{name}", val
      end
    end
  end
  
  def exec_setups source
    setups.each do |blk|
      blk.arity == 1 ? blk.call(source) : blk.call
    end
  end
  
  def setups
    @setups ||= []
  end
  
  def setup &blk
    setups << blk
  end
  
  def vars
    @vars ||= []
  end
  
  def var name, val=nil, &blk
    raise "Only value or block should be provided" if val and block_given?
    vars << [name, (val || blk)]
  end
  
  def set key, val=nil, &blk
    raise "Only value or block should be provided" if val and block_given?
    sets << [key, (val || blk)]
    sets.last
  end
  
  def get key
    @out.last[key]
  end
  
  def filters
    @filters ||= []
  end
  
  def filter *args, &blk
    filters << [args, blk]
  end
  
end