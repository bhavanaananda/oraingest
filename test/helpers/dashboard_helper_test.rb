class UserHelperTest < ActionView::TestCase
  include DashboardHelper

  test "should return the correct status tag for composite statuses" do
    assert_equal( get_status_tag('DOI registered'), 'tag-doi-registered')
  end

  test "should return the correct status tag for simple statuses" do
    assert_equal( get_status_tag('Submitted'), 'tag-submitted')
  end

  test "should return the correct type tag for composite types" do
    assert_equal( get_type_tag('Tech Report'), 'tag-tech-report')
  end

  test "should return the correct type tag for simple types" do
    assert_equal( get_type_tag('Thesis'), 'tag-thesis')
  end

  test "should return the trimmed text" do
    txt = 'this is a test'
    assert_equal( trim_text(txt, 9), 'this is a...')
  end

  test "should return the non-trimmed text" do
    txt = 'this is a test'
    assert_equal( trim_text(txt, 30), txt)
  end

  test "should return the published date" do
    item = {'desc_metadata__datePublished_tesim' => ['04/2013']}
    result = determine_date(item)
    assert_equal( result[0], 'published')
    assert_equal( result[1], '04/2013')
  end  

  test "should return the published date too" do
    item = {'desc_metadata__datePublished_tesim' => ['04/2013'],
    		'desc_metadata__dateAccepted_tesim' => ['12/2008']}
    result = determine_date(item)
    assert_equal( result[0], 'published')
    assert_equal( result[1], '04/2013')
  end    

  test "should return the accepted date" do
    item = {'desc_metadata__dateAccepted_tesim' => ['04/2013']}
    result = determine_date(item)
    assert_equal( result[0], 'accepted')
    assert_equal( result[1], '04/2013')
  end  

  test "should return nil date" do
    item = {'desc_metadata__dateTest_tesim' => ['04/2013']}
    result = determine_date(item)
    assert_equal( result[0], 'not_found')
    assert_nil( result[1] )
  end    



end
