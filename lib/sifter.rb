unless nil.respond_to? :instance_exec
  class Object
    module InstanceExecHelper; end
    include InstanceExecHelper
    def instance_exec(*args, &block)
      begin
        old_critical, Thread.critical = Thread.critical, true
        n = 0
        n += 1 while respond_to?(mname="__instance_exec#{n}")
        InstanceExecHelper.module_eval{ define_method(mname, &block) }
      ensure
        Thread.critical = old_critical
      end
      begin
        ret = send(mname, *args)
      ensure
        InstanceExecHelper.module_eval{ remove_method(mname) } rescue nil
      end
      ret
    end
  end
end

module Sifter
  
  module ClassMethods
    
    attr_reader :mappings, :afters, :befores
    
    def mappings
      @mappings ||= []
    end
    
    def afters
      @afters ||= []
    end
    
    def after &block
      afters << block
    end
    
    def befores
      @befores ||= []
    end
    
    def before &block
      befores << block
    end
    
    def method_missing name, *args, &block
      unless instance_methods.include?(name.to_s)
        super
      else
        mappings << [name, args, block]
      end
    end
    
    def load_mapping file
      instance_eval File.read file
    end
    
  end
  
  def self.included base
    base.extend ClassMethods
    base.send :include, InstanceMethods
  end
  
  module InstanceMethods
    
    attr :collection
    attr :current
    attr :index
    
    def initialize collection
      @collection = collection
      @index = 0
    end
    
    # the default mapper method
    # accepts a range of arguments or a block - but not both
    # if a block is given, the block is executed
    def map *args, &block
      raise "Block or arguments, not both" if block and args.size > 0
      if block
        instance_eval &block
      else
        # if the first argument is a Symbol,
        # call that method on the @current object
        # and send all arguments
        if args.first.is_a?(Symbol)
          self.current.send *args
        # if only one arg, is it as the value
        # else send everything as the value
        else
          args.size == 1 ? args.first : args
        end
      end
    end
    
    def process &block
      collection.each_with_index do |item, index|
        @current, @index = item, index
        # pass each object to the before blocks
        self.class.befores.each do |before_block|
          instance_exec item, &before_block
        end
        # prepare the mapped doc
        mapped_doc = {}
        # run through the mappings
        self.class.mappings.each do |(mapper_method_name, method_args, method_block)|
          field = method_args.first
          result = send mapper_method_name, *method_args[1..-1], &method_block
          mapped_doc[field] = result
        end
        # pass each mapped hash to the after blocks
        self.class.afters.each do |after_block|
          instance_exec mapped_doc, &after_block
        end
        # yield the mapped hash
        yield mapped_doc
      end
    end
    
  end
  
end