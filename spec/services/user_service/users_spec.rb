class TransactionMailer; end

describe UserService::API::Users do

  include UserService::API::Users

  include EmailSpec::Helpers
  include EmailSpec::Matchers

  PERSON_HASH = {
    given_name: "Raymond",
    family_name: "Xperiment",
    email: "Ray@example.com",
    password: "test",
    locale: "fr"
  }

  describe "#create_user" do

    it "should create a user" do
      u = create_user(PERSON_HASH)
      expect(u[:given_name]).to eql "Raymond"
      expect(Person.find_by_username("raymondx").family_name).to eql "Xperiment"
      expect(u[:locale]).to eql "fr"
    end

    it "should fail if email is taken" do
      u1 = create_user(PERSON_HASH)
      expect{create_user(PERSON_HASH)}.to raise_error(ArgumentError, /Email Ray@example.com is already in use/)
    end

  end

  describe "#create_user_with_membership" do

    before { ActionMailer::Base.deliveries = [] }

    before (:each) do
      expect(ActionMailer::Base.deliveries).to be_empty
      @community = FactoryGirl.create(:community)
    end

    it "should send the confirmation email" do
      u = create_user_with_membership(PERSON_HASH.merge({:locale => "en"}), @community.id)
      expect(ActionMailer::Base.deliveries).not_to be_empty

      email = ActionMailer::Base.deliveries.first
      expect(email).to have_subject "Confirmation instructions"
      # simple check that link to right community exists
      expect(email.body).to match @community.full_domain
      expect(email.body).to match "Sharetribe Team"
    end

    it "should send the confirmation email in right language" do
      u = create_user_with_membership(PERSON_HASH.merge({:locale => "fr"}), @community.id)
      expect(ActionMailer::Base.deliveries).not_to be_empty

      email = ActionMailer::Base.deliveries.first
      expect(email).to have_subject "Instructions de confirmation"
    end

  end

  describe "#delete_user" do
    let(:user) { FactoryGirl.create(:person) }
    let!(:membership) { FactoryGirl.create(:community_membership, person: user) }
    let!(:braintree_account) { FactoryGirl.create(:braintree_account, person: user) }
    let!(:checkout_account) { FactoryGirl.create(:checkout_account, person: user) }
    let!(:auth_token) { FactoryGirl.create(:auth_token, person: user) }
    let!(:follower) { FactoryGirl.create(:person) }
    let!(:followed) { FactoryGirl.create(:person) }
    let!(:follower_relationship) { FactoryGirl.create(:follower_relationship, person: user, follower: follower) }
    let!(:followed_relationship) { FactoryGirl.create(:follower_relationship, person: followed, follower: user) }

    it "removes user data and adds deleted flag" do
      new_user = Person.find(user.id)

      expect(new_user.given_name).not_to be_nil
      expect(new_user.family_name).not_to be_nil
      expect(new_user.emails).not_to be_empty
      expect(new_user.community_memberships).not_to be_empty
      expect(new_user.braintree_account).not_to be_nil
      expect(new_user.checkout_account).not_to be_nil
      expect(new_user.auth_tokens).not_to be_nil
      expect(new_user.follower_relationships.length).to eql(1)
      expect(new_user.inverse_follower_relationships.length).to eql(1)

      # flag
      expect(new_user.deleted).not_to eql(true)

      delete_user(user.id)

      deleted_user = Person.find(user.id)
      expect(deleted_user.given_name).to be_nil
      expect(deleted_user.family_name).to be_nil
      expect(deleted_user.emails).to be_empty
      expect(deleted_user.community_memberships.map(&:status).all? { |status| status == "deleted_user" }).to eq(true)
      expect(deleted_user.braintree_account).to be_nil
      expect(deleted_user.checkout_account).to be_nil
      expect(deleted_user.auth_tokens).to be_empty
      expect(deleted_user.follower_relationships.length).to eql(0)
      expect(deleted_user.inverse_follower_relationships.length).to eql(0)

      expect(deleted_user.deleted).to eql(true)
    end
  end

end
