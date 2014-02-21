require 'spec_helper'

describe MixSet, "#play" do
  before(:each) do
    @player = MixSet::MixSet.new
    @play_success = @player.play
  end

  it "is_playing? is changed according to mix availability" do
    @player.playing?.should eq @play_success
  end

  it "current track is changed according to mix availability" do
    @player.current_track.nil?.should_not eq @play_success
  end

  it "playing is tracked" do
    @player.tracking?.should eq @play_success
  end
end


describe MixSet do
  describe "#stop" do
    before(:each) do
      @player = MixSet::MixSet.new
    end

    it "stops playing if player was playing" do
      if @player.play
        @player.stop
        @player.playing?.should be_false
      end
    end

    it "stops tracking if player was playing" do
      if @player.play
        @player.stop
        @player.tracking?.should be_false
      end
    end


    it "does nothing if player wasn't playing" do
      was_playing = @player.playing?
      was_tracking = @player.tracking?

      @player.stop

      @player.playing?.should eq was_playing
      @player.tracking?.should eq was_tracking
    end
  end
end

describe MixSet do
  describe "#login" do
    before(:each) do
      @player = MixSet::MixSet.new
    end

    it "should return username when used with correct username and password" do
      @player.login(TEST_USERNAME, TEST_PASSWORD).should eq TEST_USERNAME
    end

    it "should return false when used with wrong username or password" do
      @player.login(TEST_USERNAME, "nil").should be_false
    end

    it "should raise error when invoked with less than two params" do 
      lambda { @player.login TEST_USERNAME }.should raise_error(ArgumentError)
    end

    it "should raise error when invoked with more than two params" do 
      lambda { @player.login TEST_USERNAME, TEST_PASSWORD, TEST_USERNAME }.should raise_error(ArgumentError)
    end

    it "should set current user when authorized successfully" do
      @player.login(TEST_USERNAME, TEST_PASSWORD)
      @player.current_user.should equal TEST_USERNAME
    end
  end
end