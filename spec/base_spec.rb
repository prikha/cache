require 'spec_helper'

class TestBaseCache < Cache::Base

  def transform_cache_key(key)
    [:test_cache, key]
  end

  def cache_store
    @cache_store ||= Object.new
  end

  def cache_store_call_options
    {some: :option}
  end

  def transform_value_object(obj)
    raise StandardError, "No object" if obj.nil?
    obj
  end

end

describe TestBaseCache, "class" do

  subject { TestBaseCache }

  %w[invalidate update fetch fetch_multi].each do |method|
    it "should delegate ##{method} to instance" do
      arg = double("arg")
      result = double("result")

      expect(subject.instance).to receive(method).with(arg).and_return(result)

      expect(subject.send(method, arg)).to be result
    end
  end

end

describe TestBaseCache do

  describe "#invalidate" do

    it 'should remove cache key from store' do
      key = double

      expect(subject.cache_store).to receive(:delete).with([:test_cache, key], subject.cache_store_call_options)

      subject.invalidate(key)
    end

  end

  describe "#update" do

    it 'should write given object to store' do
      key = double
      object = double

      expect(subject.cache_store).to receive(:write).with([:test_cache, key], object, subject.cache_store_call_options)

      subject.update(key, object)
    end

    it 'should write loaded object to store with load_object' do
      key = double
      object = double

      expect(subject).to receive(:load_object).with(key).and_return(object)
      expect(subject.cache_store).to receive(:write).with([:test_cache, key], object, subject.cache_store_call_options)

      subject.update(key)
    end

    it 'should write loaded object to store with load_objects' do
      key = double
      object = double

      expect(subject).to receive(:load_objects).with([key]).and_return(key => object)
      expect(subject.cache_store).to receive(:write).with([:test_cache, key], object, subject.cache_store_call_options)

      subject.update(key)
    end

  end

  describe "#fetch" do

    it 'should return cached object' do
      key = double("key")
      object = double("object")
      transformed = double("transformed object")

      expect(subject.cache_store).to receive(:read).with([:test_cache, key], subject.cache_store_call_options).and_return(object)
      expect(subject).to receive(:transform_value_object).with(object).and_return(transformed)

      expect(subject.fetch(key)).to eq transformed
    end

    it 'should load missed object with load_object' do
      key = double("key")
      object = double("object")
      transformed = double("transformed object")

      expect(subject.cache_store).to receive(:read).with([:test_cache, key], subject.cache_store_call_options).and_return(nil)
      expect(subject).to receive(:load_object).with(key).and_return(object)
      expect(subject.cache_store).to receive(:write).with([:test_cache, key], object, subject.cache_store_call_options)
      expect(subject).to receive(:transform_value_object).with(object).and_return(transformed)

      expect(subject.fetch(key)).to eq transformed
    end

    it 'should load missed object with load_objects' do
      key = double("key")
      object = double("object")
      transformed = double("transformed object")

      expect(subject.cache_store).to receive(:read).with([:test_cache, key], subject.cache_store_call_options).and_return(nil)
      expect(subject).to receive(:load_objects).with([key]).and_return(key => object)
      expect(subject.cache_store).to receive(:write).with([:test_cache, key], object, subject.cache_store_call_options)
      expect(subject).to receive(:transform_value_object).with(object).and_return(transformed)

      expect(subject.fetch(key)).to eq transformed
    end
  end

  describe "#fetch_multi" do

    it 'should return all cached objects' do
      keys = [double, double]
      objects = [double, double]

      store_keys = keys.map{ |key| [:test_cache, key] }

      expect(subject.cache_store).to receive(:read_multi).with(*store_keys, subject.cache_store_call_options).and_return(Hash[store_keys.zip(objects)])

      expect(subject.fetch_multi(*keys)).to eq Hash[keys.zip(objects)]
    end

    it 'should load all missed objects with load_objects' do
      keys = [double, double, double]
      objects = [double, double, double]

      store_keys = keys.map{ |key| [:test_cache, key] }

      expect(subject.cache_store).to receive(:read_multi).with(*store_keys, subject.cache_store_call_options).and_return(store_keys[0] => objects[0])
      expect(subject).to receive(:load_objects).with(keys[1..-1]).and_return(Hash[keys[1..-1].zip(objects[1..-1])])
      expect(subject.cache_store).to receive(:write).with(store_keys[1], objects[1], subject.cache_store_call_options)
      expect(subject.cache_store).to receive(:write).with(store_keys[2], objects[2], subject.cache_store_call_options)

      expect(subject.fetch_multi(*keys)).to eq Hash[keys.zip(objects)]
    end

       it 'should load all missed objects with load_object' do
      keys = [double, double, double]
      objects = [double, double, double]

      store_keys = keys.map{ |key| [:test_cache, key] }

      expect(subject.cache_store).to receive(:read_multi).with(*store_keys, subject.cache_store_call_options).and_return(store_keys[0] => objects[0])
      expect(subject).to receive(:load_object).with(keys[1]).and_return(objects[1])
      expect(subject).to receive(:load_object).with(keys[2]).and_return(objects[2])
      expect(subject.cache_store).to receive(:write).with(store_keys[1], objects[1], subject.cache_store_call_options)
      expect(subject.cache_store).to receive(:write).with(store_keys[2], objects[2], subject.cache_store_call_options)

      expect(subject.fetch_multi(*keys)).to eq Hash[keys.zip(objects)]
    end
  end

end
