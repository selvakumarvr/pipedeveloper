module CommunitySteps

  def use_payment_gateway(community_ident, gateway_name, commission)
    gateway_name ||= "Checkout"
    commission ||= "8"

    community = Community.where(ident: community_ident).first
    community.update_attributes(:vat => "24", :commission_from_seller => commission.to_i)

    if gateway_name == "Checkout"
      FactoryGirl.create(:checkout_payment_gateway, :community => community, :type => gateway_name)
    else
      FactoryGirl.create(:braintree_payment_gateway, :community => community, :type => gateway_name)
    end

    listings_api = ListingService::API::Api
    shapes = listings_api.shapes.get(community_id: community.id)[:data]

    shapes.select { |s| s[:price_enabled] }.each { |s|
      TransactionProcess.find(s[:transaction_process_id]).update_attribute(:process, :postpay)
    }
  end

  def save_name_and_action(community_id, groups)
    created_translations = TranslationService::API::Api.translations.create(community_id, groups)
    created_translations[:data].map { |translation| translation[:translation_key] }
  end
end

World(CommunitySteps)

Given /^there are following communities:$/ do |communities_table|
  communities_table.hashes.each do |hash|
    ident = hash[:community]
    existing_community = Community.where(ident: ident).first
    existing_community.destroy if existing_community
    @hash_community = FactoryGirl.create(:community, :ident => ident, :settings => {"locales" => ["en", "fi"]})

    attributes_to_update = hash.except('community')
    @hash_community.update_attributes(attributes_to_update) unless attributes_to_update.empty?
  end
end

Given /^the test community has following available locales:$/ do |locale_table|
  @locales = []
  locale_table.hashes.each do |hash|
    @locales << hash['locale']
  end

  #here is expected that the first community is the test community where the subdomain is pointing by default
  community = Community.first
  community.update_attributes({:settings => { "locales" => @locales }})
  community.locales.each do |locale|
    unless community.community_customizations.find_by_locale(locale)
      community.community_customizations.create(:locale => locale, :name => "Sharetribe")
    end
  end
end

Given /^the terms of community "([^"]*)" are changed to "([^"]*)"$/ do |community, terms|
  Community.where(ident: community).first.update_attribute(:consent, terms)
end

Given /^"(.*?)" is a member of community "(.*?)"$/ do |username, community_name|
  community = Community.where(ident: community_name).first
  person = Person.find_by_username!(username)
  membership = FactoryGirl.create(:community_membership, :person => person, :community => community)
  membership.save!
end

Then /^Most recently created user should be member of "([^"]*)" community with(?: status "(.*?)" and)? its latest consent accepted(?: with invitation code "([^"]*)")?$/ do |community_ident, status, invitation_code|
    # Person.last seemed to return unreliable results for some reason
    # (kassi_testperson1 instead of the actual newest person, so changed
    # to look for the latest CommunityMembership)
    status ||= "accepted"

    community = Community.where(ident: community_ident).first
    CommunityMembership.last.community.should == community
    CommunityMembership.last.consent.should == community.consent
    CommunityMembership.last.status.should == status
    CommunityMembership.last.invitation.code.should == invitation_code if invitation_code.present?
end

Given /^given name and last name are not required in community "([^"]*)"$/ do |community|
  Community.where(ident: community).first.update_attribute(:real_name_required, 0)
end

Given /^community "([^"]*)" requires invite to join$/ do |community|
  Community.where(ident: community).first.update_attribute(:join_with_invite_only, true)
end

Given /^community "([^"]*)" does not require invite to join$/ do |community|
  Community.where(ident: community).first.update_attribute(:join_with_invite_only, false)
end

Given /^community "([^"]*)" requires users to have an email address of type "(.*?)"$/ do |community, email|
  Community.where(ident: community).first.update_attribute(:allowed_emails, email)
end

Given /^the community has payments in use(?: via (\w+))?(?: with seller commission (\w+))?$/ do |gateway_name, commission|
  use_payment_gateway(@current_community.ident, gateway_name, commission)
end

Given /^community "([^"]*)" has payments in use(?: via (\w+))?(?: with seller commission (\w+))?$/ do |community_ident, gateway_name, commission|
  use_payment_gateway(community_ident, gateway_name, commission)
end

Given /^users (can|can not) invite new users to join community "([^"]*)"$/ do |verb, community|
  can_invite = verb == "can"
  Community.where(ident: community).first.update_attribute(:users_can_invite_new_users, can_invite)
end

Given /^there is an invitation for community "([^"]*)" with code "([^"]*)"(?: with (\d+) usages left)?$/ do |community, code, usages_left|
  inv = Invitation.new(:community => Community.where(ident: community).first, :code => code, :inviter_id => @people.first[1].id)
  inv.usages_left = usages_left if usages_left.present?
  inv.save
end

Then /^Invitation with code "([^"]*)" should have (\d+) usages_left$/ do |code, usages|
  Invitation.find_by_code(code).usages_left.should == usages.to_i
end

When /^I move to community "([^"]*)"$/ do |community|
  Capybara.default_host = "#{community}.lvh.me"
  Capybara.app_host = "http://#{community}.lvh.me:9887"
  @current_community = Community.where(ident: community).first
end

When /^I arrive to sign up page with the link in the invitation email with code "(.*?)"$/ do |code|
  visit "/en/signup?code=#{code}"
end

Given /^there is an existing community with "([^"]*)" in allowed emails and with slogan "([^"]*)"$/ do |email_ending, slogan|
  @existing_community = FactoryGirl.create(:community, :allowed_emails => email_ending, :slogan => slogan, :category => "company")
end

Given /^show me existing community$/ do
  puts "Email ending: #{@existing_community.allowed_emails}"
end

Then /^community "(.*?)" should require invite to join$/ do |community|
   Community.where(ident: community).first.join_with_invite_only.should be_truthy
end

Then /^community "(.*?)" should not require invite to join$/ do |community|
   Community.where(ident: community).first.join_with_invite_only.should_not be_truthy
end

Given /^community "(.*?)" is private$/ do |community_ident|
  Community.where(ident: community_ident).first.update_attributes({:private => true})
end

Given /^this community is private$/ do
  @current_community.private = true
  @current_community.save!
end

Given /^community "(.*?)" has following category structure:$/ do |community, categories|
  current_community = Community.where(ident: community).first
  old_category_ids = current_community.categories.collect(&:id)

  current_community.categories = categories.hashes.map do |hash|
    category = current_community.categories.create!
    category.translations.create!(:name => hash['fi'], :locale => 'fi')
    category.translations.create!(:name => hash['en'], :locale => 'en')

    shape = ListingService::API::Api.shapes.get(community_id: current_community.id)[:data].first
    CategoryListingShape.create!(category_id: category.id, listing_shape_id: shape[:id])

    if hash['category_type'].eql?("main")
      @top_level_category = category
    else
      category.update_attribute(:parent_id, @top_level_category.id)
    end
    category
  end

  # Clean old
  current_community.categories.select do |category|
    old_category_ids.include? category.id
  end.each do |category|
    category.destroy!
  end
end

Given /^community "(.*?)" has following listing shapes enabled:$/ do |community, listing_shapes|
  current_community = Community.where(ident: community).first
  # TODO Add DELETE to Listing shape API
  ListingShape.where(community_id: current_community.id).destroy_all

  process_id = TransactionProcess.where(community_id: current_community.id, process: :none).first.id

  listing_shapes.hashes.map do |hash|
    name_tr_key, action_button_tr_key = save_name_and_action(current_community.id, [
      {translations: [ {locale: 'fi', translation: hash['fi']}, {locale: 'en', translation: hash['en']} ]},
      {translations: [ {locale: 'fi', translation: (hash['button'] || 'Action')}, {locale: 'en', translation: (hash['button'] || 'Action')} ]}
    ])

    ListingService::API::Api.shapes.create(
      community_id: current_community.id,
      opts: {
        price_enabled: true,
        shipping_enabled: false,
        name_tr_key: name_tr_key,
        action_button_tr_key: action_button_tr_key,
        transaction_process_id: process_id,
        basename: hash['en'],
        units: [ {type: :hour, quantity_selector: :number} ]
      }
    )
  end

  current_community.reload
end

Given /^the community has listing shape Rent with name "(.*?)" and action button label "(.*?)"$/ do |name, action_button_label|
  process_id = TransactionProcess.where(community_id: @current_community.id, process: [:preauthorize, :postpay]).first.id
  defaults = TransactionTypeCreator::DEFAULTS["Rent"]

  name_tr_key, action_button_tr_key = save_name_and_action(@current_community.id, [
    {translations: [{locale: "en", translation: name}]},
    {translations: [{locale: "en", translation: (action_button_label || "Action")}]}
  ])

  shape_res = ListingService::API::Api.shapes.create(
    community_id: @current_community.id,
    opts: {
      price_enabled: true,
      shipping_enabled: false,
      name_tr_key: name_tr_key,
      action_button_tr_key: action_button_tr_key,
      transaction_process_id: process_id,
      basename: name,
      units: [ {type: :day, quantity_selector: :day} ]
    }
  )

  @shape = shape_res.data
end

Given /^the community has listing shape Sell with name "(.*?)" and action button label "(.*?)"$/ do |name, action_button_label|
  process_id = TransactionProcess.where(community_id: @current_community.id, process: [:preauthorize, :postpay]).first.id
  defaults = TransactionTypeCreator::DEFAULTS["Sell"]

  name_tr_key, action_button_tr_key = save_name_and_action(@current_community.id, [
    {translations: [{locale: "en", translation: name}]},
    {translations: [{locale: "en", translation: (action_button_label || "Action")}]}
  ])

  shape_res = ListingService::API::Api.shapes.create(
    community_id: @current_community.id,
    opts: {
      price_enabled: true,
      shipping_enabled: false,
      name_tr_key: name_tr_key,
      action_button_tr_key: action_button_tr_key,
      transaction_process_id: process_id,
      basename: name,
      units: [ {type: :hour, quantity_selector: :number} ]
    }
  )

  @shape = shape_res.data
end

Given /^that listing shape shows the price of listing per day$/ do
  @shape = ListingService::API::Api.shapes.update(
    community_id: @current_community.id,
    listing_shape_id: @shape[:id],
    opts: {
      units: [type: :day, quantity_selector: :day]})
end

Given /^that transaction uses payment preauthorization$/ do
  TransactionProcess.find(@shape[:transaction_process_id]).update_attribute(:process, :preauthorize)
end

Given /^that transaction does not use payment preauthorization$/ do
  TransactionProcess.find(@shape[:transaction_process_id]).update_attribute(:process, :postpay)
end

Given /^that transaction belongs to category "(.*?)"$/ do |category_name|
  category = find_category_by_name(category_name)
  CategoryListingShape.where(category_id: category.id, listing_shape_id: @shape[:id]).first_or_create!
  category.reload
end

Given /^listing publishing date is shown in community "(.*?)"$/ do |community_ident|
  Community.where(ident: community_ident).first.update_attributes({:show_listing_publishing_date => true})
end

Given /^current community requires users to be verified to post listings$/ do
  @current_community.update_attribute(:require_verification_to_post_listings, true)
end

Given(/^this community has price filter enabled with min value (\d+) and max value (\d+)$/) do |min, max|
  @current_community.show_price_filter = true
  @current_community.price_filter_min = min.to_i * 100 # Cents
  @current_community.price_filter_max = max.to_i * 100 # Cents
  @current_community.save!
end

Given /^current community has (free|starter|basic|growth|scale) plan$/ do |plan|
  case plan
  when "free"
    plan_level = 0
  when "starter"
    plan_level = 1
  when "basic"
    plan_level = 2
  when "growth"
    plan_level = 3
  when "scale"
    plan_level = 4
  end
  # N.B. community_plans are changed manually atm.
  MarketplaceService::API::Marketplaces.Helper.create_community_plan(@current_community, {plan_level: plan_level})
end

When /^community updates get delivered$/ do
  CommunityMailer.deliver_community_updates
end

Given(/^this community does not send automatic newsletters$/) do
  @current_community.update_attribute(:automatic_newsletters, false)
end

Given(/^community emails are sent from name "(.*?)" and address "(.*?)"$/) do |name, email|
  EmailService::API::Api.addresses.create(
    community_id: @current_community.id,
    address: {
      name: name,
      email: email,
      verification_status: :verified
    }
  )
end
