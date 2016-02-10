require 'test_helper'

class UsersControllerTest <  ActionController::TestCase

  setup do
    @user = users(:reviewer)
  end

  test 'reviewing user must be valid' do
    assert @user.valid?
  end

end
