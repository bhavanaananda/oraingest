require 'test_helper'

class SolrDocTest < ActiveSupport::TestCase

  SOLR_DOCS_FIXTURE_SIZE = 111

  #load fixtures file containing 1 solr doc
  file1 ||= File.open("test/fixtures/solr_doc", "rb")
  solr_test_data = eval(file1.read)
  file1.close
  raise TypeError, "solr_test_data isn't a Hash" unless solr_test_data.is_a? Hash
  @@solr_doc ||= SolrDoc.new(solr_test_data)

  #load fixtures file containing 111 solr docs
  file2 ||= File.open("test/fixtures/solr_data", "rb")
  solr_data = eval(file2.read)
  file2.close
  raise TypeError, "solr_data isn't a Hash" unless solr_data.is_a? Hash
  @@batch_solr_docs ||= solr_data['response']['docs']


  test "solr hash succesfully converts to SolrDoc object" do
    assert_not_nil @@solr_doc
  end

  test "ID attribute set correctly" do
    assert_equal 'uuid:d1c45722-8466-441b-8e4f-0aefa3b95b87', @@solr_doc.id
  end


  test "Status attribute set correctly" do
    assert_equal 'Draft', @@solr_doc.status
  end

  test "Title attribute set correctly" do
    assert_equal 'Elton Archive Arctic expedition 1923', @@solr_doc.title
  end

  test "Type attribute set correctly" do
    assert_equal 'Article', @@solr_doc.type
  end

  test "Creator attribute set correctly" do
    assert_equal 'Andrew Bonnie,Sally Rumsey', @@solr_doc.creator
  end

  test "Depositor attribute set correctly" do
    assert_equal 'bodl0933', @@solr_doc.depositor
  end

  test "Contributor attribute set correctly" do
    assert_equal 'bodl1087', @@solr_doc.contributor
  end

  test "Current Reviewer attribute set correctly" do
    assert_equal 'bodl2421', @@solr_doc.current_reviewer
  end

  test "Date Published attribute set correctly" do
    assert_equal '2014', @@solr_doc.date_published
  end

  test "Date Accepted attribute set correctly" do
    assert_equal '10/03/2015', @@solr_doc.date_accepted
  end

  test "Subject attribute set correctly" do
    assert_includes @@solr_doc.subject, 'Religion'
    assert_includes @@solr_doc.subject, 'Forced migration'
  end

  #TODO: test "Abstract attribute set correctly" do


end
