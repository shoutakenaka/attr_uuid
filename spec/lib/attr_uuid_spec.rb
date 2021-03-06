require "spec_helper"
require "active_record"
require "attr_uuid"
require "json"

config_json = File.open(File.join("spec", "config", "database.json")).read
config = JSON.parse(config_json, :symbolize_keys => true)
ActiveRecord::Base.establish_connection(config)

class Model1
  include AttrUuid
  attr_uuid :uuid
  attr_accessor :uuid
  def initialize(uuid)
    @uuid = UUIDTools::UUID.parse(uuid).raw
  end
end

class Model2
  include AttrUuid
  attr_uuid 1
end

class Model3
  include AttrUuid
  attr_uuid :uuid, :column_name => 1
end

describe AttrUuid do
  context "when PORO" do
    subject(:model) { Model1.new("faea220a-e94e-442c-9ca0-5b39753e3549") }

    describe ".attr_uuid" do
      context "when argument is String" do
        it { is_expected.to respond_to :formatted_uuid }
        it { is_expected.to respond_to :formatted_uuid= }
        it { is_expected.to respond_to :hex_uuid }
        it { is_expected.to respond_to :hex_uuid= }
      end

      context "when argument is neither String nor Symbol" do
        subject(:model) { Model2.new }
        it { is_expected.not_to respond_to :formatted_1 }
        it { is_expected.not_to respond_to :formatted_1= }
        it { is_expected.not_to respond_to :hex_1 }
        it { is_expected.not_to respond_to :hex_1= }
      end

      context "when column alias name is neither String nor Symbol" do
        subject(:model) { Model3.new }
        it { is_expected.not_to respond_to :formatted_1 }
        it { is_expected.not_to respond_to :formatted_1= }
        it { is_expected.not_to respond_to :hex_1 }
        it { is_expected.not_to respond_to :hex_1= }
      end
    end

    describe "#formatted_xxx" do
      it "returns formatted attribute value" do
        expect(model.formatted_uuid).to eq "faea220a-e94e-442c-9ca0-5b39753e3549"
      end

      context "when uuid is nil" do
        before { model.uuid = nil }
        it { expect(model.formatted_uuid).to be_nil }
      end
    end

    describe "#formatted_xxx=" do
      it "updates original attribute" do
        o = UUIDTools::UUID.parse("d8354fff-f782-4b86-b4a7-7db46a5426d7")
        model.formatted_uuid = o.to_s
        expect(model.uuid).to eq o.raw
      end
    end

    describe "#hex_xxx" do
      it "returns hex digested attribute value" do
        expect(model.hex_uuid).to eq "faea220ae94e442c9ca05b39753e3549"
      end

      context "when uuid is nil" do
        before { model.uuid = nil }
        it { expect(model.hex_uuid).to be_nil }
      end
    end

    describe "#hex_xxx=" do
      it "updates original attribute" do
        o = UUIDTools::UUID.parse("d8354fff-f782-4b86-b4a7-7db46a5426d7")
        model.hex_uuid = o.hexdigest
        expect(model.uuid).to eq o.raw
      end
    end
  end

  context "when ActiveRecord" do
    context "when disable autofill" do
      with_model :dummy do
        table do |t|
          t.binary :uuid
        end

        model do
          include AttrUuid
          attr_uuid :uuid
        end
      end

      context "when save without uuid" do
        subject(:model) { Dummy.create! }
        it { expect(model.uuid).to be_nil }
      end

      let(:model) do
        id = UUIDTools::UUID.parse("faea220a-e94e-442c-9ca0-5b39753e3549")
        Dummy.new {|o| o.uuid = id.raw }
      end

      describe ".attr_uuid" do
        subject { model }
        it { is_expected.to respond_to :formatted_uuid }
        it { is_expected.to respond_to :formatted_uuid= }
        it { is_expected.to respond_to :hex_uuid }
        it { is_expected.to respond_to :hex_uuid= }
        it { expect(Dummy).to respond_to :find_all_by_formatted_uuid }
        it { expect(Dummy).to respond_to :find_all_by_hex_uuid }
        it { expect(Dummy).to respond_to :find_by_formatted_uuid }
        it { expect(Dummy).to respond_to :find_by_hex_uuid }
      end

      describe ".find_by_formatted_xxx" do
        subject(:result) { Dummy.find_by_formatted_uuid(uuid) }

        before { model.save! }

        context "when uuid matched" do
          let(:uuid) { "faea220a-e94e-442c-9ca0-5b39753e3549" }
          it { expect(result).to eq model }
        end

        context "when no uuid matched" do
          let(:uuid) { "00000000-e94e-442c-9ca0-5b39753e3549" }
          it { expect(result).to be_nil }
        end

        context "when uuid is nil" do
          let(:uuid) { nil }
          it { expect(result).to be_nil }
        end

        context "when uuid isn't String" do
          let(:uuid) { 1 }
          it { expect(result).to be_nil }
        end

        context "when uuid format is invalid" do
          let(:uuid) { "invalid" }
          it { expect(result).to be_nil }
        end
      end

      describe ".find_all_by_formatted_xxx" do
        subject(:result) { Dummy.find_all_by_formatted_uuid(uuid) }

        let!(:model1) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse("faea220a-e94e-442c-9ca0-5b39753e3549").raw }.tap(&:save!) }
        let!(:model2) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse("e7a8d36b-9bca-4a82-bebb-5fbd08cac267").raw }.tap(&:save!) }
        let!(:model3) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse("fd7d3422-450d-4066-8810-5970281879b4").raw }.tap(&:save!) }
        let!(:model4) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse("97fceb6b-db8d-42fb-b842-4b4371f8e795").raw }.tap(&:save!) }
        let!(:model5) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse("84ce3004-753f-4667-a9fa-b1177b37d989").raw }.tap(&:save!) }

        context "when uuid matched" do
          let(:uuid) { ["faea220a-e94e-442c-9ca0-5b39753e3549", "fd7d3422-450d-4066-8810-5970281879b4", "97fceb6b-db8d-42fb-b842-4b4371f8e795" ] }
          it { expect(result).to eq [model1, model3, model4] }
        end

        context "when no uuid matched" do
          let(:uuid) { ["00000000-e94e-442c-9ca0-5b39753e3549"] }
          it { expect(result).to eq [] }
        end

        context "when uuid is nil" do
          let(:uuid) { nil }
          it { expect(result).to eq [] }
        end

        context "when uuid isn't String" do
          let(:uuid) { 1 }
          it { expect(result).to eq [] }
        end

        context "when uuid format is invalid" do
          let(:uuid) { ["invalid"] }
          it { expect(result).to eq [] }
        end
      end

      describe ".find_all_by_hex_xxx" do
        subject(:result) { Dummy.find_all_by_hex_uuid(uuid) }

        let!(:model1) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse_hexdigest("faea220ae94e442c9ca05b39753e3549").raw }.tap(&:save!) }
        let!(:model2) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse_hexdigest("e7a8d36b9bca4a82bebb5fbd08cac267").raw }.tap(&:save!) }
        let!(:model3) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse_hexdigest("fd7d3422450d406688105970281879b4").raw }.tap(&:save!) }
        let!(:model4) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse_hexdigest("97fceb6bdb8d42fbb8424b4371f8e795").raw }.tap(&:save!) }
        let!(:model5) { Dummy.new {|o| o.uuid = UUIDTools::UUID.parse_hexdigest("84ce3004753f4667a9fab1177b37d989").raw }.tap(&:save!) }

        context "when uuid matched" do
          let(:uuid) { ["faea220ae94e442c9ca05b39753e3549", "fd7d3422450d406688105970281879b4", "97fceb6bdb8d42fbb8424b4371f8e795" ] }
          it { expect(result).to eq [model1, model3, model4] }
        end

        context "when no uuid matched" do
          let(:uuid) { ["00000000e94e442c9ca05b39753e3549"] }
          it { expect(result).to eq [] }
        end

        context "when uuid is nil" do
          let(:uuid) { nil }
          it { expect(result).to eq [] }
        end

        context "when uuid isn't String" do
          let(:uuid) { 1 }
          it { expect(result).to eq [] }
        end

        context "when uuid format is invalid" do
          let(:uuid) { ["invalid"] }
          it { expect(result).to eq [] }
        end
      end

      describe ".find_by_hex_xxx" do
        before { model.save! }
        subject(:result) { Dummy.find_by_hex_uuid(uuid) }

        context "when uuid matched" do
          let(:uuid) { "faea220ae94e442c9ca05b39753e3549" }
          it { expect(result).to eq model }
        end

        context "when no uuid matched" do
          let(:uuid) { "00000000e94e442c9ca05b39753e3549" }
          it { expect(result).to be_nil }
        end

        context "when uuid is nil" do
          let(:uuid) { nil }
          it { expect(result).to be_nil }
        end

        context "when uuid isn't String" do
          let(:uuid) { 1 }
          it { expect(result).to be_nil }
        end

        context "when uuid format is invalid" do
          let(:uuid) { "invalid" }
          it { expect(result).to be_nil }
        end
      end
    end

    context "when column name alias enabled" do
      with_model :dummy do
        table do |t|
          t.binary :x_uuid
        end

        model do
          include AttrUuid
          attr_uuid :uuid, :column_name => "x_uuid"
        end
      end

      context "when save without uuid" do
        subject(:model) { Dummy.create! }
        it { expect(model.x_uuid).to be_nil }
      end

      subject(:model) do
        id = UUIDTools::UUID.parse("faea220a-e94e-442c-9ca0-5b39753e3549")
        Dummy.new {|o| o.x_uuid = id.raw }
      end

      describe ".attr_uuid" do
        it { is_expected.to respond_to :formatted_uuid }
        it { is_expected.to respond_to :formatted_uuid= }
        it { is_expected.to respond_to :hex_uuid }
        it { is_expected.to respond_to :hex_uuid= }
        it { expect(Dummy).to respond_to :find_by_formatted_uuid }
        it { expect(Dummy).to respond_to :find_by_hex_uuid }
      end

      describe ".find_by_formatted_xxx" do
        before { model.save! }
        subject(:result) { Dummy.find_by_formatted_uuid(uuid) }

        context "when uuid matched" do
          let(:uuid) { "faea220a-e94e-442c-9ca0-5b39753e3549" }
          it { expect(result).to eq model }
        end

        context "when no uuid matched" do
          let(:uuid) { "00000000-e94e-442c-9ca0-5b39753e3549" }
          it { expect(result).to be_nil }
        end
      end

      describe ".find_by_hex_xxx" do
        before { model.save! }
        subject(:result) { Dummy.find_by_hex_uuid(uuid) }

        context "when uuid matched" do
          let(:uuid) { "faea220ae94e442c9ca05b39753e3549" }
          it { expect(result).to eq model }
        end

        context "when no uuid matched" do
          let(:uuid) { "00000000e94e442c9ca05b39753e3549" }
          it { expect(result).to be_nil }
        end
      end
    end

    context "when enable autofill" do
      with_model :dummy do
        table do |t|
          t.binary :uuid
        end

        model do
          include AttrUuid
          attr_uuid :uuid, :autofill => true
        end
      end

      context "when uuid is nil" do
        before do
          @uuid = UUIDTools::UUID.parse("080cd5cb-9556-4c07-9af3-a4559cf52627")
          UUIDTools::UUID.stub(:timestamp_create).and_return(@uuid)
        end
        subject(:model) { Dummy.create! }
        it { expect(model.uuid).to eq @uuid.raw }
      end

      context "when uuid is empty" do
        before do
          @uuid = UUIDTools::UUID.parse("40d5fafe-ff68-4606-9de7-554eae0d77a3")
          UUIDTools::UUID.stub(:timestamp_create).and_return(@uuid)
        end
        subject(:model) { Dummy.create! {|o| o.uuid = ""} }
        it { expect(model.uuid).to eq @uuid.raw }
      end

      context "when uuid is set" do
        subject(:model) do
          @uuid = UUIDTools::UUID.parse("3e1fe985-2fbf-44ce-a5fb-d1b3db49260d")
          Dummy.create! {|o| o.uuid = @uuid.raw }
        end
        it { expect(model.uuid).to eq @uuid.raw }
      end
    end
  end
end
