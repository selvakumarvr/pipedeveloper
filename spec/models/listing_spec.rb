# == Schema Information
#
# Table name: listings
#
#  id                              :integer          not null, primary key
#  community_id                    :integer          not null
#  author_id                       :string(255)
#  category_old                    :string(255)
#  title                           :string(255)
#  times_viewed                    :integer          default(0)
#  language                        :string(255)
#  created_at                      :datetime
#  updates_email_at                :datetime
#  updated_at                      :datetime
#  last_modified                   :datetime
#  sort_date                       :datetime
#  listing_type_old                :string(255)
#  description                     :text
#  origin                          :string(255)
#  destination                     :string(255)
#  valid_until                     :datetime
#  delta                           :boolean          default(TRUE), not null
#  open                            :boolean          default(TRUE)
#  share_type_old                  :string(255)
#  privacy                         :string(255)      default("private")
#  comments_count                  :integer          default(0)
#  subcategory_old                 :string(255)
#  old_category_id                 :integer
#  category_id                     :integer
#  share_type_id                   :integer
#  listing_shape_id                :integer
#  transaction_process_id          :integer
#  shape_name_tr_key               :string(255)
#  action_button_tr_key            :string(255)
#  organization_id                 :integer
#  price_cents                     :integer
#  currency                        :string(255)
#  quantity                        :string(255)
#  unit_type                       :string(32)
#  quantity_selector               :string(32)
#  unit_tr_key                     :string(64)
#  unit_selector_tr_key            :string(64)
#  deleted                         :boolean          default(FALSE)
#  require_shipping_address        :boolean          default(FALSE)
#  pickup_enabled                  :boolean          default(FALSE)
#  shipping_price_cents            :integer
#  shipping_price_additional_cents :integer
#  deposit_cents                   :integer
#  quantity_available              :integer
#
# Indexes
#
#  homepage_query                      (community_id,open,sort_date,deleted)
#  homepage_query_valid_until          (community_id,open,valid_until,sort_date,deleted)
#  index_listings_on_category_id       (old_category_id)
#  index_listings_on_community_id      (community_id)
#  index_listings_on_listing_shape_id  (listing_shape_id)
#  index_listings_on_new_category_id   (category_id)
#  index_listings_on_open              (open)
#  person_listings                     (community_id,author_id)
#  updates_email_listings              (community_id,open,updates_email_at)
#

require 'spec_helper'

describe Listing do

  before(:each) do
    @listing = FactoryGirl.build(:listing, listing_shape_id: 123)
  end

  it "is valid with valid attributes" do
    @listing.should be_valid
  end

  it "is not valid without a title" do
    @listing.title = nil
    @listing.should_not be_valid
  end

  it "is not valid with a too short title" do
    @listing.title = "a"
    @listing.should_not be_valid
  end

  it "is not valid with a too long title" do
    @listing.title = "0" * 101
    @listing.should_not be_valid
  end

  it "is valid without a description" do
    @listing.description = nil
    @listing.should be_valid
  end

  it "is not valid if description is longer than 5000 characters" do
    @listing.description = "0" * 5001
    @listing.should_not be_valid
  end

  it "is not valid without an author" do
    @listing.author = nil
    @listing.should_not be_valid
  end

  it "is not valid without category" do
    @listing.category = nil
    @listing.should_not be_valid
  end

  it "should not be valid when valid until date is before current date" do
    @listing.valid_until = DateTime.now - 1.day - 1.minute
    @listing.should_not be_valid
  end

  it "should not be valid when valid until is more than one year after current time" do
    @listing.valid_until = DateTime.now + 1.year + 2.days
    @listing.should_not be_valid
  end

  describe "#visible_to?" do
    let(:community) { FactoryGirl.create(:community, private: true) }
    let(:community2) { FactoryGirl.create(:community) }
    let(:person) { FactoryGirl.create(:person, communities: [community, community2]) }
    let(:listing) { FactoryGirl.create(:listing, community_id: community.id, listing_shape_id: 123) }

    it "is not visible, if the listing doesn't belong to the given community" do
      listing.visible_to?(person, community2).should be_falsey
    end

    it "is visible, if user is a member of the given community in which the listing belongs" do
      listing.visible_to?(person, community).should be_truthy
    end

    it "is visible, if user is not logged in and the listing and community are public" do
      community.update_attribute(:private, false)

      listing.visible_to?(nil, community).should be_truthy
    end

    it "is not visible, if user is not logged in but the community is private" do
      community.update_attribute(:private, true)

      listing.visible_to?(nil, community).should be_falsey
    end

    it "is not visible, if the listing is closed" do
      listing.update_attribute(:open, false)

      listing.visible_to?(person, community).should be_falsey
      listing.visible_to?(nil, community).should be_falsey
    end
  end

  context "with listing type 'offer'" do

    it "should be valid when there is no valid until" do
      @listing.valid_until = nil
      @listing.should be_valid
    end

  end
end
