module SimpleCov
  module ArrayMergeHelper
    # Merges an array of coverage results with self
    def merge_resultset(array)
      new_array = dup
      array.each_with_index do |element, i|
        if element.nil? && new_array[i].nil?
          new_array[i] = nil
        else
          local_value = element || 0
          other_value = new_array[i] || 0
          new_array[i] = local_value + other_value
        end
      end
      new_array
    end
  end
end

module SimpleCov
  module HashMergeHelper
    # Merges the given Coverage.result hash with self
    def merge_resultset(hash)
      new_resultset = {}
      (keys + hash.keys).each do |filename|
        new_resultset[filename] = []
      end

      new_resultset.each_key do |filename|
        new_resultset[filename] = (self[filename] || []).merge_resultset(hash[filename] || [])
      end
      new_resultset
    end
  end
end

Array.send :include, SimpleCov::ArrayMergeHelper
Hash.send :include, SimpleCov::HashMergeHelper
