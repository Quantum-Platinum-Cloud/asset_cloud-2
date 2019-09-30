# frozen_string_literal: true
# rubocop:disable RSpec/FilePath, Lint/MissingCopEnableDirective

require 'spec_helper'
require 'google/cloud/storage'

class RemoteGCSCloud < AssetCloud::Base
  attr_accessor :gcs_connection
  bucket :tmp, AssetCloud::GCSBucket

  def gcs_bucket
    gcs_connection.bucket(ENV['GCS_BUCKET'])
  end
end

describe AssetCloud::GCSBucket, if: ENV['GCS_PROJECT_ID'] && ENV['GCS_KEY_FILEPATH'] && ENV['GCS_BUCKET'] do
  directory = File.dirname(__FILE__) + '/files'

  before(:all) do
    @cloud = RemoteGCSCloud.new(directory, 'assets/files')

    @cloud.gcs_connection = Google::Cloud::Storage.new(
        project_id: ENV['GCS_PROJECT_ID'],
        credentials: ENV['GCS_KEY_FILEPATH']
      )
    @bucket = @cloud.buckets[:tmp]
  end

  after(:all) do
    @bucket.clear
  end

  it "#ls with no arguments returns all files in the bucket" do
    expect_any_instance_of(Google::Cloud::Storage::Bucket).to receive(:files).with(no_args)
    expect do
      @bucket.ls
    end.not_to raise_error
  end

  it "#ls with arguments returns the file" do
    local_path = "#{directory}/products/key.txt"
    key = 'test/ls.txt'

    @bucket.write(key, local_path)

    file = @bucket.ls(key)
    expect(file.name).to eq("s#{@cloud.url}/#{key}")
  end

  it "#write writes a file into the bucket" do
    local_path = "#{directory}/products/key.txt"
    key = 'test/key.txt'

    @bucket.write(key, local_path)
  end

  it "#delete removes the file from the bucket" do
    key = 'test/key.txt'

    expect do
      @bucket.delete(key)
    end.not_to raise_error
  end

  it "#delete raises AssetCloud::AssetNotFoundError if the file is not found" do
    key = 'tmp/not_found.txt'
    expect do
      @bucket.delete(key)
    end.to raise_error(AssetCloud::AssetNotFoundError)
  end

  it "#read returns the data of the file" do
    value = 'hello world'
    key = 'tmp/new_file.txt'
    @bucket.write(key, StringIO.new(value))

    data = @bucket.read(key)
    data.should == value
  end

  it "#read raises AssetCloud::AssetNotFoundError if the file is not found" do
    key = 'tmp/not_found.txt'
    expect do
      @bucket.read(key)
    end.to raise_error(AssetCloud::AssetNotFoundError)
  end

  it "#stats returns metadata of the asset" do
    value = 'hello world'
    key = 'tmp/new_file.txt'
    @bucket.write(key, StringIO.new(value))

    stats = @bucket.stat(key)

    expect(stats.size).not_to be_nil
    expect(stats.created_at).not_to be_nil
    expect(stats.updated_at).not_to be_nil
  end
end