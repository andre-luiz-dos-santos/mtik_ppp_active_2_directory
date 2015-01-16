# coding: utf-8

module MtikPppActive2Directory
  module Log
    module_function

    # Call #output to replace this method.
    def info
    end

    # Set the logging method.
    def output(&block)
      define_singleton_method(:info) do |&message|
        block.call(message.call)
      end
    end
  end
end
