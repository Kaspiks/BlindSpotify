# frozen_string_literal: true

require "rails_helper"

RSpec.describe MusicBrainz::OriginalReleaseYearService do
  let(:client) { instance_double(MusicBrainz::Client) }
  subject(:service) { described_class.new(client: client) }

  describe "#call" do
    context "when isrc is blank" do
      it "returns nil without calling the client" do
        allow(client).to receive(:recording_by_isrc)

        expect(service.call("")).to be_nil
        expect(service.call(nil)).to be_nil
        expect(client).not_to have_received(:recording_by_isrc)
      end
    end

    context "when MusicBrainz returns no recordings" do
      before do
        allow(client).to receive(:recording_by_isrc).and_return("recordings" => [])
      end

      it "returns nil" do
        expect(service.call("USRC17607839")).to be_nil
      end
    end

    context "when MusicBrainz returns recordings with no official dated releases" do
      before do
        allow(client).to receive(:recording_by_isrc).and_return(
          "recordings" => [
            { "releases" => [{ "status" => "Promotional", "date" => "2015" }] }
          ]
        )
      end

      it "returns nil" do
        expect(service.call("USRC17607839")).to be_nil
      end
    end

    context "when MusicBrainz returns recordings with first-release-date" do
      before do
        allow(client).to receive(:recording_by_isrc).and_return(
          "recordings" => [
            { "first-release-date" => "2017-07-23" }
          ]
        )
      end

      it "returns the year from first-release-date" do
        expect(service.call("FR96X1712690")).to eq(2017)
      end
    end

    context "when MusicBrainz returns official releases with dates (no first-release-date)" do
      before do
        allow(client).to receive(:recording_by_isrc).and_return(
          "recordings" => [
            {
              "releases" => [
                { "status" => "Official", "date" => "2019-06-14" },
                { "status" => "Official", "date" => "2017-01-01" },
                { "status" => "Official", "date" => "2018" }
              ]
            }
          ]
        )
      end

      it "returns the earliest release year" do
        expect(service.call("USRC17607839")).to eq(2017)
      end
    end

    context "when the client raises a network error" do
      before do
        allow(client).to receive(:recording_by_isrc).and_raise(Net::ReadTimeout)
      end

      it "returns nil" do
        expect(service.call("USRC17607839")).to be_nil
      end
    end
  end
end
