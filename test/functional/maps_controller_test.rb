require 'test_helper'

class MapsControllerTest < ActionController::TestCase
  test "should get all" do
    get :all
    assert_response :success
  end

end
