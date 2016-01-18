require "test_helper"

class ReviewerViewsRelevantItemsTest < Capybara::Rails::TestCase
  include Warden::Test::Helpers
  Warden.test_mode!

  setup do
    Capybara.use_default_driver       
    login_as users(:archivist)
  end

  teardown do
    Warden.test_reset!
  end

  test "sanity" do
  	visit '/dash'
  assert_raises(CanCan::AccessDenied) {page}

 # ability = Ability.new(user)
  # assert ability.can?(:destroy, Project.new(:user => user))
  # assert ability.cannot?(:destroy, Project.new)    
  #   assert_content page, "You do not have permission to review"
  end


end
