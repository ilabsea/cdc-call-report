require 'rails_helper'

RSpec.describe SmsBroadcast, type: :model do
  include ActiveJob::TestHelper

  let(:sms_broadcaster) { SmsBroadcast.new('Testing') }
  let!(:channel) { create(:channel, name: 'fake-channel', is_enable: true) }

  describe "#broadcast_to" do
    context "ignore adding sms to queue when there is no any users" do
      it {
        expect(SmsQueueJob).to receive(:perform_later).with({receivers: ['1000'], body: 'Testing'}).never

        sms_broadcaster.broadcast_to []

        expect(enqueued_jobs.size).to eq(0)
      }
    end

    context "adding a sms to queue for every user who has phone number when it has active channels" do
      let!(:default_channel) { create(:channel, is_default: true) }

      let(:user) { build(:user, phone: '1000') }
      let(:user_without_phone_number) { build(:user, phone: nil) }
      let(:users) { [user, user_without_phone_number] }
      let(:log_type) { create(:log_type, name: :broadcast) }
      let(:sms) { Sms::Message.new('1000', 'Testing', 'fake-channel', log_type) }

      before(:each) do
        allow(Channel).to receive(:has_active?).and_return(true)
        allow_any_instance_of(Channel).to receive(:connected?).and_return(true)
        allow(Sms::Message).to receive(:new).with('1000', 'Testing', default_channel, log_type).and_return(sms)
      end

      it {
        sms_broadcaster.broadcast_to users

        expect(enqueued_jobs.size).to eq(1)
        first_queued = enqueued_jobs.first[:args].first.delete_if { |k, v| k === '_aj_symbol_keys' }
        expect(first_queued).to eq({ 'to' => '1000', 'body' => 'Testing', 'suggested_channel' => 'fake-channel', 'type' => { '_aj_globalid' => "gid://#{ENV['APP_NAME'].split(' ').join("-").downcase}/LogType/#{log_type.id}" } })
      }
    end
  end
end
