require File.dirname(__FILE__) + '/../spec_helper'

describe Tracking do
  before(:each) do
    @tracking = Tracking.new
  end

  it "should be valid" do
    @tracking.should be_valid
  end
end
