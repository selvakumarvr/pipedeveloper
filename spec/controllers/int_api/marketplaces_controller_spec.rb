# encoding: utf-8

require 'spec_helper'

# Override the API with test API
require_relative '../../services/plan_service/api/api'

class TransactionMailer; end

describe IntApi::MarketplacesController do

  let(:listings_api) { ListingService::API::Api }

  def expect_trial_plan(cid)
    # Create trial plan
    plan = PlanService::API::Api.plans.get_current(community_id: cid).data
    expect(plan[:plan_level]).to eq(0)
    expect(plan[:expires_at]).not_to eq(nil)
  end

  describe "#create" do
    it "should create a marketplace and an admin user" do
      post :create, {admin_email: "eddie.admin@example.com",
                     admin_first_name: "Eddie",
                     admin_last_name: "Admin",
                     admin_password: "secret_word",
                     marketplace_country: "FI",
                     marketplace_language: "fi",
                     marketplace_name: "ImaginationTraders",
                     marketplace_type: "product"}

      expect(response.status).to eql 201

      r = JSON.parse(response.body)
      expect(r["marketplace_url"]).to eql "http://imaginationtraders.#{APP_CONFIG.domain}?auth=#{AuthToken.last.token}"

      c = Community.where(ident: "imaginationtraders").first
      expect(c).to_not be_nil
      expect(c.country).to eql "FI"
      expect(c.locales.first).to eql "fi"
      expect(c.name("fi")).to eql "ImaginationTraders"
      expect(c.ident).to eql "imaginationtraders"
      s = listings_api.shapes.get(community_id: c.id).data.first
      expect(s[:price_enabled]).to eql true
      expect(s[:units].empty?).to eql true

      payment_settings = TransactionService::API::Api.settings.get_active(community_id: c.id)
      expect(payment_settings[:data][:payment_gateway]).to eql :paypal
      expect(payment_settings[:data][:payment_process]).to eql :preauthorize

      p = c.admins.first
      expect(p).to_not be_nil
      expect(p.given_name).to eql "Eddie"
      expect(p.family_name).to eql "Admin"
      expect(p.username).to eql "eddiea"
      expect(p.locale).to eql "fi"
      expect(p.emails.first.address).to eql "eddie.admin@example.com"

      expect_trial_plan(c.id)
    end

    it "should handle emails starting with info@" do
      post :create, {admin_email: "info@example.com",
                     admin_first_name: "Eddiè",
                     admin_last_name: "Admin",
                     admin_password: "secret_word",
                     marketplace_country: "FI",
                     marketplace_language: "fi",
                     marketplace_name: "ImaginationTraders",
                     marketplace_type: "product"}

      response.status.should == 201

      r = JSON.parse(response.body)
      expect(r["marketplace_url"]).to eql "http://imaginationtraders.#{APP_CONFIG.domain}?auth=#{AuthToken.last.token}"

      c = Community.where(ident: "imaginationtraders").first
      expect(c).to_not be_nil
      expect(c.country).to eql "FI"
      expect(c.locales.first).to eql "fi"
      expect(c.name("fi")).to eql "ImaginationTraders"
      expect(c.ident).to eql "imaginationtraders"
      s = listings_api.shapes.get(community_id: c.id).data.first
      expect(s[:price_enabled]).to eql true
      expect(s[:units].empty?).to eql true

      p = c.admins.first
      expect(p).to_not be_nil
      expect(p.given_name).to eql "Eddiè"
      expect(p.family_name).to eql "Admin"
      expect(p.username).to eql "eddiea"
      expect(p.locale).to eql "fi"
      expect(p.emails.first.address).to eql "info@example.com"

      expect_trial_plan(c.id)
    end

    it "should handle short emails like fo@barbar.com" do
      post :create, {admin_email: "fo@example.com",
                     admin_first_name: "Eddie_",
                     admin_last_name: "Admin",
                     admin_password: "secret_word",
                     marketplace_country: "FI",
                     marketplace_language: "fi",
                     marketplace_name: "ImaginationTraders",
                     marketplace_type: "product"}

      response.status.should == 201

      r = JSON.parse(response.body)
      expect(r["marketplace_url"]).to eql "http://imaginationtraders.#{APP_CONFIG.domain}?auth=#{AuthToken.last.token}"

      c = Community.where(ident: "imaginationtraders").first
      expect(c).to_not be_nil
      expect(c.country).to eql "FI"
      expect(c.locales.first).to eql "fi"
      expect(c.name("fi")).to eql "ImaginationTraders"
      expect(c.ident).to eql "imaginationtraders"
      s = listings_api.shapes.get(community_id: c.id).data.first
      expect(s[:price_enabled]).to eql true
      expect(s[:units].empty?).to eql true

      p = c.admins.first
      expect(p).to_not be_nil
      expect(p.given_name).to eql "Eddie_"
      expect(p.family_name).to eql "Admin"
      expect(p.username).to eql "eddiea"
      expect(p.locale).to eql "fi"
      expect(p.emails.first.address).to eql "fo@example.com"

      expect_trial_plan(c.id)
    end

    it "should handle short first + last names" do
      post :create, {admin_email: "fo@example.com",
                     admin_first_name: "E",
                     admin_last_name: "McT",
                     admin_password: "secret_word",
                     marketplace_country: "FI",
                     marketplace_language: "fi",
                     marketplace_name: "ImaginationTraders",
                     marketplace_type: "product"}

      response.status.should == 201

      r = JSON.parse(response.body)
      expect(r["marketplace_url"]).to eql "http://imaginationtraders.#{APP_CONFIG.domain}?auth=#{AuthToken.last.token}"

      c = Community.where(ident: "imaginationtraders").first
      expect(c).to_not be_nil
      expect(c.country).to eql "FI"
      expect(c.locales.first).to eql "fi"
      expect(c.name("fi")).to eql "ImaginationTraders"
      expect(c.ident).to eql "imaginationtraders"
      s = listings_api.shapes.get(community_id: c.id).data.first
      expect(s[:price_enabled]).to eql true
      expect(s[:units].empty?).to eql true

      p = c.admins.first
      expect(p).to_not be_nil
      expect(p.given_name).to eql "E"
      expect(p.family_name).to eql "McT"
      expect(p.username).to eql "em1"
      expect(p.locale).to eql "fi"
      expect(p.emails.first.address).to eql "fo@example.com"

      expect_trial_plan(c.id)
    end

  end

  describe "#check_email_availability" do
    it "should return correct availability info when email is available" do
      get :check_email_availability, {:email => "something.not.used@example.com" }

      expect(response.status).to eql 200
      r = JSON.parse(response.body)

      expect(r["email"]).to eql "something.not.used@example.com"
      expect(r["available"]).to eql true

      expect(ProspectEmail.last.email).to eql "something.not.used@example.com"
    end

    it "should return correct availability info when email is not available" do

      FactoryGirl.create(:email, :address => "occupied@email.com")
      get :check_email_availability, {:email => "occupied@email.com"}

      expect(response.status).to eql 200
      r = JSON.parse(response.body)
      expect(r["email"]).to eql "occupied@email.com"
      expect(r["available"]).to eql false

      expect(ProspectEmail.last.email).to eql "occupied@email.com"
    end

  end
end
