require 'test_helper'

class ReviewingControllerTest < ActionController::TestCase

  Filter = Struct.new(:facet, :value, :predicate)

  setup do
    @filter_list = []
  end

  test "build query builds default search query" do
    result = "!#{SolrFacets.lookup(:STATUS)}:Claimed"
    @filter_list << Filter.new(:STATUS, :Claimed, :NOT)
    assert_equal result, @controller.send(:build_query, @filter_list)
  end


  test "build query builds backup search query" do
    result = "#{SolrFacets.lookup(:STATUS)}:Claimed AND #{SolrFacets.lookup(:CURRENT_REVIEWER)}:Joe+Bloggs"
    @filter_list << Filter.new(:STATUS, :Claimed)
    @filter_list << Filter.new(:CURRENT_REVIEWER, 'Joe Bloggs')
    assert_equal result, @controller.send(:build_query, @filter_list)
  end

  teardown do
    @filter_list.clear
  end
end
