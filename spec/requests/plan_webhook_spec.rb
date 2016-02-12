require 'spec_helper'

# Override the API with test API
require_relative '../services/plan_service/api/api'

describe "plan provisioning" do

  let(:log_target) {
    PlanService::API::Api.log_target
  }

  before(:each) do
    log_target.clear!
  end

  let(:token) {
    # The token is result of: JWT.encode({}, "test_secret")
    "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.e30._FFJneyyiPmeCSEQdh2KPyIW84tXdjY1bhbc41LkRxw"
  }

  describe "security" do
    it "returns 401 if token doesn't match" do
      post "http://webhooks.sharetribe.com/webhooks/plans", {plans: []}.to_json
      expect(response.status).to eq(401)

      error_log = log_target.parse_log(:error)
      expect(error_log)
        .to eq([{tag: "external_plan_service", free: "Unauthorized", structured: {"error" => "token_missing", "token"=>nil}}])
    end

    it "returns 200 if authorized" do
      post "http://webhooks.sharetribe.com/webhooks/plans?token=#{token}", {plans: []}.to_json
      expect(response.status).to eq(200)
    end
  end

  describe "invalid JSON" do
    it "returns 400 Bad request, if JSON is invalid" do
      post "http://webhooks.sharetribe.com/webhooks/plans?token=#{token}", "invalid JSON"
      expect(response.status).to eq(400)

      error_log = log_target.parse_log(:error)
      expect(error_log.first[:free]).to include("Error while parsing JSON")
    end
  end

  describe "not in use" do
    before(:each) {
      PlanService::API::Api.reset!
      PlanService::API::Api.set_environment(active: false)
    }

    after(:each) {
      PlanService::API::Api.reset!
      PlanService::API::Api.set_environment(active: true)
    }

    it "returns 404 if external plan service is not in use" do
      post "http://webhooks.sharetribe.com/webhooks/plans?token=#{token}", {plans: []}.to_json
      expect(response.status).to eq(404)
    end
  end

  describe "plans" do

    it "creates new plans" do
      body = '{
        "plans": [
          {
            "marketplace_id": 1234,
            "plan_level": 2
          },
          {
            "marketplace_id": 5555,
            "plan_level": 5,
            "expires_at": "2015-10-15 15:00:00"
          }
        ]
      }'

      post "http://webhooks.sharetribe.com/webhooks/plans?token=#{token}", body

      plan1234 = PlanService::API::Api.plans.get_current(community_id: 1234).data

      expect(plan1234.slice(:community_id, :plan_level, :expires_at)).to eq({
                               community_id: 1234,
                               plan_level: 2,
                               expires_at: nil
                             })

      plan5555 = PlanService::API::Api.plans.get_current(community_id: 5555)
                 .data

      expect(plan5555.slice(:community_id, :plan_level, :expires_at)).to eq({
                               community_id: 5555,
                               plan_level: 5,
                               expires_at: Time.utc(2015, 10, 15, 15, 0, 0)
                             })

      expect(response.status).to eq(200)
      expect(JSONUtils.symbolize_keys(JSON.parse(response.body))[:plans].map { |plan| plan[:marketplace_plan_id] })
              .to eq([plan1234[:id], plan5555[:id]])

      expect(log_target.parse_log(:info).map { |entry| entry[:free] })
        .to eq([
                 "Received plan notification",
                 "Parsed plan notification",
                 "Created new plans based on the notification"
               ])
    end
  end

  describe "trials" do

    context "success" do

      it "fetches trials after given time" do
        id111 = nil
        id222 = nil
        id333 = nil

        Timecop.freeze(Time.utc(2015, 9, 15)) {
          id111 = PlanService::API::Api.plans.create_initial_trial(community_id: 111, plan: {plan_level: 0}).data[:id]
        }

        Timecop.freeze(Time.utc(2015, 10, 15)) {
          id222 = PlanService::API::Api.plans.create_initial_trial(community_id: 222, plan: {plan_level: 0}).data[:id]
        }

        Timecop.freeze(Time.utc(2015, 11, 15)) {
          id333 = PlanService::API::Api.plans.create_initial_trial(community_id: 333, plan: {plan_level: 0}).data[:id]
        }

        after = Time.utc(2015, 10, 1).to_i

        get "http://webhooks.sharetribe.com/webhooks/trials?token=#{token}&after=#{after}"

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              plans: [
                                {
                                  marketplace_plan_id: id222,
                                  marketplace_id: 222,
                                  plan_level: 0,
                                  created_at: Time.utc(2015, 10, 15),
                                  updated_at: Time.utc(2015, 10, 15),
                                  expires_at: nil,
                                },
                                {
                                  marketplace_plan_id: id333,
                                  marketplace_id: 333,
                                  plan_level: 0,
                                  created_at: Time.utc(2015, 11, 15),
                                  updated_at: Time.utc(2015, 11, 15),
                                  expires_at: nil,
                                }
                              ]
                            }.to_json))

        log_entry = log_target.parse_log(:info).first
        expect(log_entry[:free]).to eq("Fetching plans that are created after 2015-10-01 00:00:00 UTC")
        expect(log_entry[:structured]).to eq({"after" => "2015-10-01T00:00:00Z", "limit" => 1000})
        log_entry = log_target.parse_log(:info).second
        expect(log_entry[:free]).to eq("Returned 2 plans")
        expect(log_entry[:structured]).to eq({"count" => 2})
      end

      it "supports pagination" do
        id111 = nil
        id222 = nil
        id333 = nil

        Timecop.freeze(Time.utc(2015, 9, 15)) {
          id111 = PlanService::API::Api.plans.create_initial_trial(community_id: 111, plan: {plan_level: 0}).data[:id]
        }

        Timecop.freeze(Time.utc(2015, 10, 15)) {
          id222 = PlanService::API::Api.plans.create_initial_trial(community_id: 222, plan: {plan_level: 0}).data[:id]
        }

        Timecop.freeze(Time.utc(2015, 11, 15)) {
          id333 = PlanService::API::Api.plans.create_initial_trial(community_id: 333, plan: {plan_level: 0}).data[:id]
        }

        after = Time.utc(2015, 9, 1).to_i
        get "http://webhooks.sharetribe.com/webhooks/trials?token=#{token}&after=#{after}&limit=1"

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              plans: [
                                {
                                  marketplace_plan_id: id111,
                                  marketplace_id: 111,
                                  plan_level: 0,
                                  created_at: Time.utc(2015, 9, 15),
                                  updated_at: Time.utc(2015, 9, 15),
                                  expires_at: nil,
                                }
                              ],
                              next_after: Time.utc(2015, 10, 15).to_i
                            }.to_json))

        after = Time.utc(2015, 10, 15).to_i
        get "http://webhooks.sharetribe.com/webhooks/trials?token=#{token}&after=#{after}&limit=2"

        expect(response.status).to eq(200)
        expect(JSON.parse(response.body))
          .to eq(JSON.parse({
                              plans: [
                                {
                                  marketplace_plan_id: id222,
                                  marketplace_id: 222,
                                  plan_level: 0,
                                  created_at: Time.utc(2015, 10, 15),
                                  updated_at: Time.utc(2015, 10, 15),
                                  expires_at: nil,
                                },
                                {
                                  marketplace_plan_id: id333,
                                  marketplace_id: 333,
                                  plan_level: 0,
                                  created_at: Time.utc(2015, 11, 15),
                                  updated_at: Time.utc(2015, 11, 15),
                                  expires_at: nil,
                                }
                              ]
                            }.to_json))
      end
    end
  end
end
