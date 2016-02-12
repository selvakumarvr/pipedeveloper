# encoding: utf-8
# == Schema Information
#
# Table name: communities
#
#  id                                         :integer          not null, primary key
#  ident                                      :string(255)
#  domain                                     :string(255)
#  use_domain                                 :boolean          default(FALSE), not null
#  created_at                                 :datetime
#  updated_at                                 :datetime
#  settings                                   :text
#  consent                                    :string(255)
#  transaction_agreement_in_use               :boolean          default(FALSE)
#  email_admins_about_new_members             :boolean          default(FALSE)
#  use_fb_like                                :boolean          default(FALSE)
#  real_name_required                         :boolean          default(TRUE)
#  feedback_to_admin                          :boolean          default(TRUE)
#  automatic_newsletters                      :boolean          default(TRUE)
#  join_with_invite_only                      :boolean          default(FALSE)
#  use_captcha                                :boolean          default(FALSE)
#  allowed_emails                             :text
#  users_can_invite_new_users                 :boolean          default(TRUE)
#  private                                    :boolean          default(FALSE)
#  label                                      :string(255)
#  show_date_in_listings_list                 :boolean          default(FALSE)
#  all_users_can_add_news                     :boolean          default(TRUE)
#  custom_frontpage_sidebar                   :boolean          default(FALSE)
#  event_feed_enabled                         :boolean          default(TRUE)
#  slogan                                     :string(255)
#  description                                :text
#  category                                   :string(255)      default("other")
#  country                                    :string(255)
#  members_count                              :integer          default(0)
#  user_limit                                 :integer
#  monthly_price_in_euros                     :float
#  logo_file_name                             :string(255)
#  logo_content_type                          :string(255)
#  logo_file_size                             :integer
#  logo_updated_at                            :datetime
#  cover_photo_file_name                      :string(255)
#  cover_photo_content_type                   :string(255)
#  cover_photo_file_size                      :integer
#  cover_photo_updated_at                     :datetime
#  small_cover_photo_file_name                :string(255)
#  small_cover_photo_content_type             :string(255)
#  small_cover_photo_file_size                :integer
#  small_cover_photo_updated_at               :datetime
#  custom_color1                              :string(255)
#  custom_color2                              :string(255)
#  stylesheet_url                             :string(255)
#  stylesheet_needs_recompile                 :boolean          default(FALSE)
#  service_logo_style                         :string(255)      default("full-logo")
#  available_currencies                       :text
#  facebook_connect_enabled                   :boolean          default(TRUE)
#  vat                                        :integer
#  commission_from_seller                     :integer
#  minimum_price_cents                        :integer
#  testimonials_in_use                        :boolean          default(TRUE)
#  hide_expiration_date                       :boolean          default(FALSE)
#  facebook_connect_id                        :string(255)
#  facebook_connect_secret                    :string(255)
#  google_analytics_key                       :string(255)
#  name_display_type                          :string(255)      default("first_name_with_initial")
#  twitter_handle                             :string(255)
#  use_community_location_as_default          :boolean          default(FALSE)
#  preproduction_stylesheet_url               :string(255)
#  show_category_in_listing_list              :boolean          default(FALSE)
#  default_browse_view                        :string(255)      default("grid")
#  wide_logo_file_name                        :string(255)
#  wide_logo_content_type                     :string(255)
#  wide_logo_file_size                        :integer
#  wide_logo_updated_at                       :datetime
#  only_organizations                         :boolean
#  listing_comments_in_use                    :boolean          default(FALSE)
#  show_listing_publishing_date               :boolean          default(FALSE)
#  require_verification_to_post_listings      :boolean          default(FALSE)
#  show_price_filter                          :boolean          default(FALSE)
#  price_filter_min                           :integer          default(0)
#  price_filter_max                           :integer          default(100000)
#  automatic_confirmation_after_days          :integer          default(14)
#  favicon_file_name                          :string(255)
#  favicon_content_type                       :string(255)
#  favicon_file_size                          :integer
#  favicon_updated_at                         :datetime
#  default_min_days_between_community_updates :integer          default(7)
#  listing_location_required                  :boolean          default(FALSE)
#  custom_head_script                         :text
#  follow_in_use                              :boolean          default(TRUE), not null
#  logo_processing                            :boolean
#  wide_logo_processing                       :boolean
#  cover_photo_processing                     :boolean
#  small_cover_photo_processing               :boolean
#  favicon_processing                         :boolean
#  dv_test_file_name                          :string(64)
#  dv_test_file                               :string(64)
#  deleted                                    :boolean
#
# Indexes
#
#  index_communities_on_domain  (domain)
#  index_communities_on_ident   (ident)
#

require 'spec_helper'

describe Community do

  before(:each) do
    @community = FactoryGirl.build(:community)
  end

  it "is valid with valid attributes" do
    @community.should be_valid
  end

  it "is not valid without proper ident" do
    @community.ident = "test_community-9"
    @community.should be_valid
    @community.ident = nil
    @community.should_not be_valid
    @community.ident = "a"
    @community.should_not be_valid
    @community.ident = "a" * 51
    @community.should_not be_valid
    @community.ident = "´?€"
    @community.should_not be_valid
  end

  it "validates twitter handle" do
    @community.twitter_handle = "abcdefghijkl"
    @community.should be_valid
    @community.twitter_handle = "abcdefghijklmnopqr"
    @community.should_not be_valid
    @community.twitter_handle = "@abcd"
    @community.should_not be_valid
    @community.twitter_handle = "AbCd1"
    @community.should be_valid
  end


  describe "#get_new_listings_to_update_email" do

    def get_listing(created_at, updates_email_at)
      FactoryGirl.create(:listing,
        :created_at => created_at.days.ago,
        :updates_email_at => updates_email_at.days.ago,
        :listing_shape_id => 123,
        :community_id => @community.id)
    end

    before(:each) do
      @p1 = FactoryGirl.create(:person, :emails => [ FactoryGirl.create(:email, :address => "update_tester@example.com") ])
      @p1.communities << @community
      @l1 = get_listing(2,2)
      @l2 = get_listing(3,3)
      @l3 = get_listing(12,12)
      @l4 = get_listing(13,3)
    end

    it "should contain latest and picked listings" do
      listings_to_email = @community.get_new_listings_to_update_email(@p1)

      listings_to_email.should include(@l1, @l2, @l4)
      listings_to_email.should_not include(@l3)
    end

    it "should prioritize picked listings" do
      @l5 = get_listing(13,3)
      @l6 = get_listing(13,3)
      @l7 = get_listing(13,3)
      @l8 = get_listing(13,3)
      @l9 = get_listing(13,3)
      @l10 = get_listing(13,3)
      @l11 = get_listing(13,3)
      @l12 = get_listing(13,3)

      listings_to_email = @community.get_new_listings_to_update_email(@p1)

      listings_to_email.should include(@l1, @l4, @l5, @l6, @l7, @l8, @l9, @l10, @l11, @l12)
      listings_to_email.should_not include(@l2, @l3)
    end
    it "should order listings using updates_email_at" do
      @l5 = get_listing(13,3)
      @l6 = get_listing(13,4)
      @l7 = get_listing(13,5)
      @l8 = get_listing(13,6)
      @l9 = get_listing(13,6)
      @l10 = get_listing(13,6)
      @l11 = get_listing(13,6)
      @l12 = get_listing(13,6)

      listings_to_email = @community.get_new_listings_to_update_email(@p1)

      correct_order = true

      listings_to_email.each_cons(2) do |consecutive_listings|
        first, last = consecutive_listings
        if first.updates_email_at < last.updates_email_at
          correct_order = false
        end
      end

      correct_order.should be_truthy
    end

    it "should include just picked listings" do
      @l5 = get_listing(13,3)
      @l6 = get_listing(13,3)
      @l7 = get_listing(13,3)
      @l8 = get_listing(13,3)
      @l9 = get_listing(13,3)
      @l10 = get_listing(13,3)
      @l11 = get_listing(13,3)
      @l12 = get_listing(13,3)
      @l13 = get_listing(13,3)
      @l14 = get_listing(13,3)

      listings_to_email = @community.get_new_listings_to_update_email(@p1)

      listings_to_email.should include(@l4, @l5, @l6, @l7, @l8, @l9, @l10, @l11, @l12, @l13,@l14)
      listings_to_email.should_not include(@l1, @l2, @l3)
    end
  end
end

