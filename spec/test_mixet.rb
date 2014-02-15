require 'spec_helper'

describe Mixet, "#show_description" do
  it "shows description of gem" do
    Mixet.show_description.should eq("Nice 8tracks music player")
  end
end

describe Mixet, "#list+next" do
    it "increment page" do
        Mixet.list(:next)
        ApiClient.instance.current_page.should eq(1)
    end
end