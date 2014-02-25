require 'spec_helper'

module MixSet
  module ApiCommunication
    describe SmartId, "#smart_id" do

      it "construct smart id by given single type" do
        SmartId.smart_id(type: "listened", values: ["param1", "param2"]).should eq "listened"
        SmartId.smart_id(type: "listened").should eq "listened"
        SmartId.smart_id(type: "recommended").should eq "recommended"
        SmartId.smart_id(type: "recommended", values: ["param1", "param2"]).should eq "recommended"
        SmartId.smart_id(type: "liked").should eq "liked"
        SmartId.smart_id(type: "liked", values: ["param1", "param2"]).should eq "liked"
      end

      it "construct smart id by given smart type" do
        SmartId.smart_id(type: "tags").should eq "all"
        SmartId.smart_id(type: "tags", values: ["param1", "param2"]).should eq "tags:param1+param2"
        SmartId.smart_id(type: "keyword").should eq "all"
        SmartId.smart_id(type: "keyword", values: ["param1", "param2"]).should eq "keyword:param1+param2"
        SmartId.smart_id(type: "artist").should eq "all"
        SmartId.smart_id(type: "artist", values: ["param1", "param2"]).should eq "artist:param1+param2"
      end

      it "construct default smart id when type is not present" do
        SmartId.smart_id(type: "key", values: ["param1", "param2"]).should eq "all"
        SmartId.smart_id(type: "key", sort: "hot").should eq "all:hot"
        SmartId.smart_id(type: "key", sort: "hot1").should eq "all"
      end

      it "escapes params" do
        SmartId.smart_id(type: "tags", values: ["param_1", "param_2"]).should eq "tags:param__1+param__2"
        SmartId.smart_id(type: "tags", values: ["param 1", "param 2"]).should eq "tags:param_1+param_2"
        SmartId.smart_id(type: "tags", values: ["param/1", "param/2"]).should eq "tags:param\\1+param\\2"
        SmartId.smart_id(type: "tags", values: ["param.1", "param.2"]).should eq "tags:param^1+param^2"
      end

      it "escapes params" do
        SmartId.url_param_from_string("param 1").should eq "param_1"
        SmartId.url_param_from_string("param/1").should eq "param\\1"
        SmartId.url_param_from_string("param.1").should eq "param^1"
        SmartId.url_param_from_string("param_1").should eq "param__1"
      end

      it "can add sorting" do
        SmartId.smart_id(type: "listened", values: ["param1", "param2"], sort: "recent").should eq "listened:recent"
        SmartId.smart_id(type: "tags", values: ["param1", "param2"], sort: "recent").should eq "tags:param1+param2:recent"
        SmartId.smart_id(sort: "hot").should eq "all:hot"
      end

    end
  end
end