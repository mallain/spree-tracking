require File.dirname(__FILE__) + '/../../spec_helper'

describe Admin::TrackingHelper do
  
  #Delete this example and add some real ones or delete this file
  it "should include the Admin::TrackingHelper" do
    included_modules = self.metaclass.send :included_modules
    included_modules.should include(Admin::TrackingHelper)
  end
  
end
