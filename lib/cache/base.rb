module Cache
  class Base

    class << self

      def respond_to_missing?(method, include_all = false)
        super || instance.respond_to?(method)
      end

      def method_missing(method, *args, &block)
        if instance.respond_to?(method)
          instance.send(method, *args, &block)
        else
          super
        end
      end

      def instance
        @instance ||= new
      end
    end

    def fetch(key)
      trkey = transform_cache_key(key)
      trobj = cache_store.read(trkey, cache_store_call_options)

      unless trobj # No object in cache, load new one
        trobj = transform_cache_object(load_object(key))
        cache_store.write(trkey, trobj, cache_store_call_options)
      end

      transform_value_object(trobj)
    end

    def fetch_multi(*keys)
      # Build key - cache_key map
      cache_key_map = Hash[keys.map{ |key| [key, transform_cache_key(key)] }]

      # Load objects from cache
      cache_results = cache_store.read_multi(*cache_key_map.values, cache_store_call_options)

      # Build result hash
      result = cache_key_map.each_with_object Hash.new do |(key, cache_key), r|
        r[key] = transform_value_object cache_results[cache_key] if cache_results.key? cache_key
      end

      # Load missed objects and cache them in store
      unless (missed_keys = keys.reject{ |key| cache_results.key? cache_key_map[key] }).empty?
        load_objects(missed_keys).each do |key, obj|
          trobj = transform_cache_object(obj)

          cache_store.write(cache_key_map[key], trobj, cache_store_call_options)

          result[key] = transform_value_object trobj
        end
      end

      result
    end

    def update(key, object = nil)
      cache_store.write(transform_cache_key(key), transform_cache_object(object || load_object(key)), cache_store_call_options)
    end

    def invalidate(key)
      cache_store.delete(transform_cache_key(key), cache_store_call_options)
    end

    private

    # Load multiple objects at once
    # This method is implemented in terms of load_object, so at least one of them should be redefined
    def load_objects(keys)
      keys.each_with_object(Hash.new) do |key, objects_hash|
        objects_hash[key] = load_object(key)
      end
    end

    # Load single object
    # This method is implemented in terms of load_objects, so at least one of them should be redefined
    def load_object(key)
      load_objects([key])[key]
    end

    def transform_cache_key(key)
      key
    end

    def transform_cache_object(obj)
      obj
    end

    def transform_value_object(obj)
      obj
    end

    def cache_store
      raise StandardError, "Cache store not set"
    end

    def cache_store_call_options
      {}
    end

  end
end
