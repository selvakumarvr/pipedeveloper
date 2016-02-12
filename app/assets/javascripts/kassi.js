// Custom Javascript functions for Sharetribe
// Add custom validation methods

function add_validator_methods() {

  /**
    Take string representing number with either dot (.) or comma (,)
    as decimal separator and get back number
  */
  function toNumber(numberStr) {
    return Number(numberStr.replace(",", "."));
  }

  function numberVal(el) {
    return toNumber(el.val());
  }

  // If some element is required, it should be validated even if it's hidden
  $.validator.setDefaults({ ignore: [] });

  $.validator.
    addMethod("accept",
      function(value, element, param) {
        return value.match(new RegExp(/(\.jpe?g|\.gif|\.png|^$)/i));
      }
    );

  $.validator.
    addMethod( "valid_username",
      function(value, element, param) {
        return value.match(new RegExp("(^[A-Za-z0-9_]*$)"));
      }
    );

  $.validator.
    addMethod("regex",
      function(value, element, regexp) {
        var re = new RegExp(regexp);
        return re.test(value);
      }
  );
  $.validator.
    addMethod("email_list",
      function(value, element, param) {
        var emails = value.split(',');
        var re = new RegExp(/^[A-Z0-9._%\-\+\~\/]+@([A-Z0-9-]+\.)+[A-Z]+$/i);
        for (var i = 0; i < emails.length; i++) {
          if (!re.test($.trim(emails[i]))) {
            return false;
          }
        }
        return true;
      }
  );

  $.validator.
    addMethod("min_date",
      function(value, element, is_rideshare) {
        if (is_rideshare == "true") {
          return get_datetime_from_datetime_select() > new Date();
        } else {
          return get_date_from_date_select() > new Date();
        }
       }
    );

  $.validator.
    addMethod("max_date",
      function(value, element) {
        var current_time = new Date();
        var maximum_date = new Date(new Date(current_time).setMonth(current_time.getMonth()+6));
        return get_date_from_date_select() < maximum_date;
       }
    );

  $.validator.
    addMethod( "captcha",
      function(value, element, param) {
        challengeField = $("input#recaptcha_challenge_field").val();
        responseField = $("input#recaptcha_response_field").val();

        var resp = $.ajax({
              type: "GET",
              url: "signup/check_captcha",
              data: "recaptcha_challenge_field=" + challengeField + "&amp;recaptcha_response_field=" + responseField,
              async: false
        }).responseText;

        if (resp == "success") {
          return true;
        } else {
          Recaptcha.reload();
          return false;
        }
      }
    );

  $.validator.
    addMethod("required_when_not_neutral_feedback",
      function(value, element, param) {
        if (value == "") {
          var radioButtonArray = new Array("1", "2", "4", "5");
          for (var i = 0; i < radioButtonArray.length; i++) {
            if ($('#grade-' + radioButtonArray[i]).is(':checked')) {
              return false;
            }
          }
        }
        return true;
       }
    );

  $.validator.
    addMethod( "positive_integer",
      function(value, element, param) {
        var n = ~~Number(value);
        return String(n) === value && n >= 0;
      }
    );

  $.validator.
    addMethod( "minimum_price_required",
      function(value, element, params) {
        minimum_price = _.first(params) || "";
        subunit_to_unit = _.first(_.rest(params));

        if (minimum_price == "") {
          return true
        } else {
          return minimum_price <= ST.paymentMath.parseSubunitFloatFromFieldValue(value, subunit_to_unit);
        }
      }
    );

  $.validator.
    addMethod( "money",
      function(value, element, minimum_price) {
        var regex = /^\d*((\.|\,)\d{1,2})?$/;
        return value && regex.test(value);
      }
    );

  $.validator.
    addMethod("max_bound",
      function(value, element, otherName) {
        var $otherInput = ST.utils.findElementByName(otherName);
        return Number(toNumber(value)) > numberVal($otherInput);
      }
    );

  $.validator.
    addMethod("min_bound",
      function(value, element, otherName) {
        var $otherInput = ST.utils.findElementByName(otherName);
        return Number(toNumber(value)) < numberVal($otherInput);
      }
    );
  $.validator.
    addMethod("number_conditional_decimals",
      function(value, element, decimalCheckbox) {
        var $otherInput = ST.utils.findElementByName(decimalCheckbox);
        var allowDecimals = $otherInput.is(':checked');
        var numberRegex  = /^\d+?$/;
        var decimalRegex  = /^\d+((\.|\,)\d+)?$/;

        var regexp = allowDecimals ? decimalRegex : numberRegex;

        return regexp.test(value);
      }
    );

  $.validator.addClassRules("required", {
    required: true
  });

  $.validator.addClassRules("number-no-decimals", {
    "number_no_decimals": true
  });

  $.validator.addClassRules("number-decimals", {
    "number_decimals": true
  });

  $.validator.addClassRules("url", {
    url: true
  });


  $.validator.
    addMethod("number_no_decimals", function(value, element, opts) {
      var numberRegex  = /^\d+?$/;
      return value.length === 0 ? true : numberRegex.test(value)
    });

  $.validator.
    addMethod("number_decimals", function(value, element) {
      var decimalRegex  = /^\d+((\.|\,)\d+)?$/;
      return value.length === 0 ? true : decimalRegex.test(value)
    });

  $.validator.
    addMethod("number_min", function(value, element, min) {
      return value.length === 0 ? true : toNumber(value) >= min;
    });

  $.validator.
    addMethod("number_max", function(value, element, max) {
      return value.length === 0 ? true : toNumber(value) <= max;
    });
}

function report_analytics_event(params_array) {
  if (typeof _gaq != 'undefined') {
    _gaq.push(['_trackEvent'].concat(params_array));
    if (typeof secondary_analytics_in_use != 'undefined' && secondary_analytics_in_use) {
      _gaq.push(['b._trackEvent'].concat(params_array));
    }
  }
}

// Initialize code that is needed for every view
function initialize_defaults(locale) {
  add_validator_methods();
  translate_validation_messages(locale);
  $('.flash-notifications').click(function() {
    $('.flash-notifications').fadeOut('slow');
  });
  $('.ajax-notification').click(function() {
    $('.ajax-notification').fadeOut('slow');
  });
  $('#login-toggle-button').click(function() {
    $('#upper_person_login').focus();
  });
}

function initialize_network_defaults(required_message, email_message) {
  enableSamePageScroll();
}

function initialize_admin_edit_price($form, min_name, max_name, locale) {
  translate_validation_messages(locale);

  rules = {};
  rules[min_name] = {
    min_bound: max_name
  };
  rules[max_name] = {
    max_bound: min_name
  };

  $form.validate({rules: rules})
}

var hideNotice = function() {
  $('.flash-notifications').fadeOut('slow');
}

function initialize_user_feedback_form() {
  form_id = "#new_feedback";
  $(form_id).validate({
    rules: {
      "feedback[email]": {required: false, email: true},
      "feedback[content]": {required: true, minlength: 1}
    }
  });
}

function initialize_email_members_form() {
  form_id = "#new_member_email";
  auto_resize_text_areas("email_members_text_area");
  $(form_id).validate({
    rules: {
      "email[subject]": {required: true, minlength: 2},
      "email[content]": {required: true, minlength: 2}
    }
  });
}

function initialize_login_form(password_forgotten) {
  if (password_forgotten == true) {
    $('#password_forgotten').slideDown('fast');
    $("html, body").animate({ scrollTop: $(document).height() }, 1000);
    $('input.request_password').focus();
  }
  $('#password_forgotten_link').click(function() {
    $('#password_forgotten').slideToggle('fast');
    $("html, body").animate({ scrollTop: $(document).height() }, 1000);
    $('input.request_password').focus();
  });
  $('#login_form input.text_field:first').focus();
}

function initialize_payments_form(locale) {
  var form_id = "#payment_settings_form";
  $(form_id).validate({
    rules: {
      // regex validation here kept failing always, so relying on backend validation for the ID
      "checkout_account_form[company_id_or_personal_id]": {required: true, minlength: 9, maxlength: 11},
      "checkout_account_form[phone_number]": {required: true, maxlength: 25},
      "checkout_account_form[organization_address]": {required: true, minlength: 6}
    },
    messages: {
    },
    onkeyup: false, //Only do validations when form focus changes
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
  });
}

function initialize_braintree_account_form(locale) {
  var form_id = "#braintree_account_form";
  $(form_id).validate({
    rules: {
      "braintree_account[first_name]": {required: true},
      "braintree_account[last_name]": {required: true},
      "braintree_account[email]": {required: true, email: true},
      "braintree_account[phone]": {required: true},
      "braintree_account[address_street_address]": {required: true},
      "braintree_account[address_postal_code]": {required: true, minlength: 2, maxlength: 6},
      "braintree_account[address_locality]": {required: true},
      "braintree_account[address_region]": {required: true},
      "braintree_account[date_of_birth]": {required: true},
      "braintree_account[routing_number]": {required: true, minlength: 9, maxlength: 9},
      "braintree_account[account_number]": {required: true},
    },
    messages: {
    },
    onkeyup: false, //Only do validations when form focus changes
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
  });
}

function initialize_send_message_form(locale) {
  auto_resize_text_areas("text_area");
  $('textarea').focus();
  var form_id = "#new_listing_conversation";
  $(form_id).validate({
    rules: {
      "listing_conversation[title]": {required: true, minlength: 1, maxlength: 120},
      "listing_conversation[content]": {required: true, minlength: 1}
    },
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
      report_analytics_event(["message", "sent"]);
    }
  });
}

function initialize_send_person_message_form(locale) {
  auto_resize_text_areas("text_area");
  $('textarea').focus();
  var form_id = "#new_conversation";
  $(form_id).validate({
    rules: {
      "conversation[message_attributes][content]": {required: true, minlength: 1}
    },
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
      report_analytics_event(["message", "sent"]);
    }
  });
}

function initialize_reply_form(locale) {
  auto_resize_text_areas("reply_form_text_area");
  $('textarea').focus();
  prepare_ajax_form(
    "#new_message",
    locale,
    {"message[content]": {required: true, minlength: 1}}
  );
}

function initialize_listing_view(locale) {
  $('#listing-image-link').click(function() { $('#listing-image-lightbox').lightbox_me({centered: true, zIndex: 1000000}); });
  auto_resize_text_areas("listing_comment_content_text_area");
  $('textarea').focus();
  prepare_ajax_form(
    "#new_comment",
    locale,
    {"comment[content]": {required: true, minlength: 1}}
  );

  $('#send_comment_button').click(function() {
    report_analytics_event(["listing", "commented"]);
  });
}

function initialize_accept_transaction_form(
  commission_percentage,
  service_fee_vat,
  form_type,
  form_id,
  minimum_price,
  subunit_to_unit,
  minimum_price_message) {

  auto_resize_text_areas("text_area");
  style_action_selectors();

  if (commission_percentage != null) {
    if (form_type === "simple") {
      $(".trigger-focusout").keyup(function(value) {
	update_simple_form_price_fields(commission_percentage);
      });
      $(form_id).validate({
	rules: {
          "listing_conversation[payment_attributes][sum]": {money: true, minimum_price_required: [minimum_price, subunit_to_unit]}
        },
        messages: {
          "listing_conversation[payment_attributes][sum]": {minimum_price_required: minimum_price_message}
        },
      });
    } else {
      function update() {
        update_complex_form_price_fields(commission_percentage, service_fee_vat);
      }

      $(".trigger-focusout").focusout(update);
      update();
    }

  }
}

function updateSellerGetsValue(priceInputSelector, displayTargetSelector, currencySelector, communityCommissionPercentage, minCommission, showReversed) {
  // true == Show the fee instead of what's left after the fee
  showReversed = showReversed || false;

  $display = $(displayTargetSelector);
  $input = $(priceInputSelector);
  $currency = $(currencySelector);

  function updateYouWillGet() {
    var sum = ST.paymentMath.parseFloatFromFieldValue($input.val());

    var displaySum;
    if (showReversed) {
      displaySum = ST.paymentMath.totalCommission(sum, communityCommissionPercentage, minCommission);
    } else {
      displaySum = sum - ST.paymentMath.totalCommission(sum, communityCommissionPercentage, minCommission);
    }

    $display.text(
      [ST.paymentMath.displayMoney(Math.max(0, displaySum)),
       $currency.val()]
        .join(" "));
  }

  $input.keyup(updateYouWillGet);
  $currency.change(updateYouWillGet);

  // Run once immediately
  updateYouWillGet();
}

function update_simple_form_price_fields(commission_percentage) {
  var sum = ST.paymentMath.parseFloatFromFieldValue($(".invoice-sum-field").val());
  var service_fee_sum = ST.paymentMath.totalCommission(sum, commission_percentage, 0, 0);
  var seller_sum = sum - service_fee_sum;
  $("#service-fee").text(ST.paymentMath.displayMoney(service_fee_sum));
  $("#payment-to-seller").text(ST.paymentMath.displayMoney(seller_sum));
}

function update_complex_form_price_fields(commissionPercentage, serviceFeeVat) {
  var euro = '\u20AC'

  var rows = $(".field-row").toArray().map(function(row) {
    var row = $(row);
    var sumEl = row.find(".payment-row-sum-field");
    var vatEl = row.find(".payment-row-vat-field");
    var totalEl = row.find(".total-label");
    var sum = ST.paymentMath.parseFloatFromFieldValue(sumEl.val());
    var vat = ST.paymentMath.parseFloatFromFieldValue(vatEl.val());

    vat = Math.min(Math.max(vat, 0), 100);
    var sumWithVat = sum + (sum * vat / 100);

    return {
      totalEl: totalEl,
      sumWithVat: sumWithVat
    };
  });

  var total = rows.reduce(function(total, rowObj) {
    return total + rowObj.sumWithVat;
  }, 0);

  var totalFee = ST.paymentMath.totalCommission(total, commissionPercentage);
  var totalFeeWithoutVat = totalFee / (1 + serviceFeeVat / 100);
  var youWillGet = total - totalFee;

  rows.forEach(function(rowObj) {
    rowObj.totalEl.text(rowObj.sumWithVat.toFixed(2) + euro);
  });

  $("#service-fee-sum").text(totalFeeWithoutVat.toFixed(2) + euro);
  $("#service-fee-total").text(totalFee.toFixed(2) + euro);

  $("#total").text(youWillGet.toFixed(2) + euro);
}

function initialize_confirm_transaction_form() {
  style_action_selectors();
}

function style_action_selectors() {
  $(".conversation-action").each(function() {
    $(this).find('label').hide();
    $(this).find('.conversation-action').each(
      function() {
        $(this).removeClass('hidden');
        $(this).click(
          function() {
            var action = $(this).attr('id');
            $(this).siblings().removeClass('accept').removeClass('reject').removeClass('confirm').removeClass('cancel');

            // Show or hide description text
            $(".confirm-description").addClass('hidden');
            $(".cancel-description").addClass('hidden');
            $("." + action + "-description").removeClass('hidden');

            // Show or hide price field
            $(".conversation-price").addClass('hidden');
            $("." + action +  "-price").removeClass('hidden');

            // Show or hide payout details missing information
            $(".hidden-accept-form").addClass('hidden');
            $(".visible-when-" + action).removeClass('hidden');

            $(this).addClass(action);
            $(".conversation-action").find('input:radio[id=' + $(this).attr('name') + ']').attr('checked', true);
            $("#conversation_message_attributes_action").val(action);
            $("#conversation_status").val(action + 'ed');
          }
        );
      }
    );
  });
}

function initialize_give_feedback_form(locale, grade_error_message, text_error_message) {
  auto_resize_text_areas("text_area");
  $('textarea').focus();
  style_grade_selectors();
  var form_id = "#new_testimonial";
  $(form_id).validate({
    errorPlacement: function(error, element) {
      if (element.attr("name") == "testimonial[grade]") {
        error.appendTo(element.parent().parent());
      }  else {
        error.insertAfter(element);
      }
    },
    rules: {
      "testimonial[grade]": {required: true},
      "testimonial[text]": {required: true}
    },
    messages: {
      "testimonial[grade]": { required: grade_error_message }
    },
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
  });
}

function style_grade_selectors() {
  $(".feedback-grade").each(function() {
    $(this).find('label').hide();
    $(this).find('.grade').each(
      function() {
        $(this).removeClass('hidden');
        $(this).click(
          function() {
            $(this).siblings().removeClass('negative').removeClass('positive');
            $(this).addClass($(this).attr('id'));
            $(".feedback-grade").find('input:radio[id=' + $(this).attr('name') + ']').attr('checked', true);
          }
        );
      }
    );
  });
}

function initialize_signup_form(locale, username_in_use_message, invalid_username_message, email_in_use_message, captcha_message, invalid_invitation_code_message, name_required, invitation_required) {
  $('#help_invitation_code_link').click(function(link) {
    //link.preventDefault();
    $('#help_invitation_code').lightbox_me({centered: true, zIndex: 1000000 });
  });
  $('#terms_link').click(function(link) {
    link.preventDefault();
    $('#terms').lightbox_me({ centered: true, zIndex: 1000000 });
  });
  var form_id = "#new_person";
  //name_required = (name_required == 1) ? true : false
  $(form_id).validate({
    errorPlacement: function(error, element) {
      if (element.attr("name") == "person[terms]") {
        error.appendTo(element.parent().parent());
      } else if (element.attr("name") == "recaptcha_response_field") {
        error.appendTo(element.parent().parent().parent().parent().parent().parent().parent().parent().parent());
      } else {
        error.insertAfter(element);
      }
    },
    rules: {
      "person[username]": {required: true, minlength: 3, maxlength: 20, valid_username: true, remote: "/people/check_username_availability"},
      "person[given_name]": {required: name_required, maxlength: 30},
      "person[family_name]": {required: name_required, maxlength: 30},
      "person[email]": {required: true, email: true, remote: "/people/check_email_availability_and_validity"},
      "person[terms]": "required",
      "person[password]": { required: true, minlength: 4 },
      "person[password2]": { required: true, minlength: 4, equalTo: "#person_password1" },
      "recaptcha_response_field": {required: true, captcha: true },
      "invitation_code": {required: invitation_required, remote: "/people/check_invitation_code"}
    },
    messages: {
      "recaptcha_response_field": { captcha: captcha_message },
      "person[username]": { valid_username: invalid_username_message, remote: username_in_use_message },
      "person[email]": { remote: email_in_use_message },
      "invitation_code": { remote: invalid_invitation_code_message }
    },
    onkeyup: false, //Only do validations when form focus changes to avoid exessive ASI calls
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
      report_analytics_event(['user', "signed up", "normal form"]);
    }
  });
}

function initialize_terms_form() {
  $('#terms_link').click(function(link) {
    link.preventDefault();
    $('#terms').lightbox_me({ centered: true, zIndex: 1000000 });
  });
}

function initialize_payment_gateway_terms_lightbox(gateway_name) {
  $('#' + gateway_name + '_terms_link').click(function(link) {
    link.preventDefault();
    $('#' + gateway_name + '_terms').lightbox_me({ centered: true, zIndex: 1000001 });
  });
}

function initialize_update_profile_info_form(locale, person_id, name_required) {
  auto_resize_text_areas("update_profile_description_text_area");
  $('input.text_field:first').focus();
  var form_id = "#edit_person_" + person_id;
  $(form_id).validate({
    rules: {
      "person[street_address]": {required: false, address_validator: true},
      "person[given_name]": {required: name_required, maxlength: 30},
      "person[family_name]": {required: name_required, maxlength: 30},
      "person[phone_number]": {required: false, maxlength: 25},
      "person[image]": { accept: "(jpe?g|gif|png)" }
    },
    onkeyup: false,
    onclick: false,
    onfocusout: false,
    onsubmit: true,
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
  });
}

function initialize_update_notification_settings_form(locale, person_id) {
  var form_id = "#edit_person_" + person_id;
  $(form_id).validate({
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
  });
}

function initialize_update_account_info_form(locale, change_text, cancel_text, email_in_use_message, one_email_must_receive_notifications_message) {
  $('.account-new-email-link').click(
    function(event) {
      event.preventDefault();
      $('.account-new-email-link').hide();
      $('.account-settings-hidden-email-form').show();
      $("#person_email_attributes_address").removeAttr("disabled");
      $("#person_email_attributes_send_notifications").removeAttr("disabled");
    }
  );
  $('.account-hide-new-email-link').click(
    function(event) {
      event.preventDefault();
      $('.account-new-email-link').show();
      $('.account-settings-hidden-email-form').hide();
      $("#person_email_attributes_address").attr("disabled", "disabled");
      $("#person_email_attributes_send_notifications").attr("disabled", "disabled");
    }
  );
  $('#account_password_link').toggle(
    function() {
      $('#account_password_form').show();
      $(this).text(cancel_text);
      $('#person_password').focus();
    },
    function() {
      $('#account_password_form').hide();
      $(this).text(change_text);
    }
  );
  var email_form_id = "#email_form";
  $(email_form_id).validate({
    errorPlacement: function(error, element) {
      if (element.attr("name") == "person[send_notifications][]") {
        error.insertAfter($("#account-settings-email-content-rows"));
      } else {
        error.insertAfter(element);
      }
    },
    rules: {
      "person[email_attributes][address]": {required: true, email: true, remote: "/people/check_email_availability"},
      "person[send_notifications][]": {required: true}
    },
    messages: {
      "person[email_attributes][address]": { remote: email_in_use_message },
      "person[send_notifications][]": { required: one_email_must_receive_notifications_message }
    },
    submitHandler: function(form) {
      disable_and_submit(email_form_id, form, "false", locale);
    }
  });
  var password_form_id = "#password_form";
  $(password_form_id).validate({
    rules: {
      "person[password]": { required: true, minlength: 4 },
      "person[password2]": { required: true, minlength: 4, equalTo: "#person_password" }
    },
    submitHandler: function(form) {
      disable_and_submit(password_form_id, form, "false", locale);
    }
  });
}

function initialize_reset_password_form() {
  var password_form_id = "#new_person";
  $(password_form_id).validate({
    errorPlacement: function(error, element) {
      error.insertAfter(element);
    },
    rules: {
      "person[password]": { required: true, minlength: 4 },
      "person[password_confirmation]": { required: true, minlength: 4, equalTo: "#person_password" }
    },
    submitHandler: function(form) {
      disable_and_submit(password_form_id, form, "false", locale);
    }
  });
}

function initialize_profile_view(profile_id) {
  $('#load-more-listings a').on("click", function() {
    var request_path = $(this).data().url;
    $.get(request_path, function(data) {
      $('#profile-listings-list').html(data);
    });
    return false;
  });

  $('#load-more-followed-people').on(
      "ajax:complete", function(element, xhr) {
          $("#profile-followed-people-list").html(xhr.responseText);
          $(this).hide();
      });

  $('#load-more-testimonials').click(function() {
    request_path = profile_id + "/testimonials";
    $.get(request_path, {per_page: 200, page: 1}, function(data) {
      $('#profile-testimonials-list').html(data);
    });
    return false;
  });


  // The code below is not used in early 3.0 version, but part of it will probably be used again soon, so kept here.
  $('#description_preview_link').click(function() {
    $('#profile_description_preview').hide();
    $('#profile_description_full').show();
  });
  $('#description_full_link').click(function() {
    $('#profile_description_preview').show();
    $('#profile_description_full').hide();
  });
  $('#trustcloud_description_link').click(function() { $('#trustcloud_description').lightbox_me({centered: true}); });
}

function initialize_homepage() {
  // make map/list button change the value in the filter form and submit the form
  // in order to keep all filter values combinable and remembered
  $('.map-button').click(
    function() {
      $("#hidden-map-toggle").val(true);
      $("#homepage-filters").submit();
      return false;
    }
  );
  $('.list-button').click(
    function() {
      $("#hidden-map-toggle").val(undefined);
      $("#homepage-filters").submit();
      return false;
    }
  );
}

function initialize_invitation_form(locale, email_error_message, invitation_limit) {
  $.validator.addMethod(
    "max_invitations",
    function(value) {
      return value.split(",").length < invitation_limit;
    },
    $.validator.format(email_error_message)
  );

  $("#new_invitation").validate({
    rules: {
      "invitation[email]": {required: true, email_list: true, max_invitations: true},
      "invitation[message]": {required: false, maxlength: 5000}
    },
    messages: {
      "invitation[email]": { email_list: email_error_message}
    },
    onkeyup: false,
    onclick: false,
    onfocusout: false,
    onsubmit: true,
    submitHandler: function(form) {
      disable_and_submit("#new_invitation", form, "false", locale);
    }
  });
}

function initialize_private_community_defaults(locale, feedback_default_text) {
  add_validator_methods();
  translate_validation_messages(locale);
  $('select.language_select').selectmenu({style: 'dropdown', width: "100px"});
  $('#close_notification_link').click(function() { $('#notifications').slideUp('fast'); });
  // Make sure that Sharetribe cannot be used if js is disabled
  $('.wrapper').addClass('js_enabled');
}

function initialize_admin_edit_tribe_form(locale, community_id) {
  auto_resize_text_areas("new_tribe_text_area");
  translate_validation_messages(locale);
  $('#invite_only_help_text_link').click(function() { $('#invite_only_help_text').lightbox_me({centered: true}); });
  var form_id = "#edit_community_" + community_id;
  $(form_id).validate({
     rules: {
       "community[name]": {required: true, minlength: 2, maxlength: 50},
       "community[slogan]": {required: true, minlength: 2, maxlength: 100},
       "community[description]": {required: true, minlength: 2}
     },
     submitHandler: function(form) {
       disable_and_submit(form_id, form, "false", locale);
     }
   });
}

function initialize_admin_edit_tribe_look_and_feel_form(locale, community_id, invalid_color_code_message) {
  translate_validation_messages(locale);
  var form_id = "#edit_community_" + community_id;
  $(form_id).validate({
     rules: {
       "community[custom_color1]": {required: false, minlength: 6, maxlength: 6, regex: "^([a-fA-F0-9]+)?$"}
     },
     messages: {
      "community[custom_color1]": { regex: invalid_color_code_message }
    },
     submitHandler: function(form) {
       disable_and_submit(form_id, form, "false", locale);
     }
   });
}

function initialize_admin_social_media_form(locale, community_id, invalid_twitter_handle_message, invalid_facebook_connect_id_message, invalid_facebook_connect_secret_message) {
  translate_validation_messages(locale);
  var form_id = "#edit_community_" + community_id;
  $(form_id).validate({
     rules: {
       "community[twitter_handle]": {required: false, minlength: 1, maxlength: 15, regex: "^([A-Za-z0-9_]+)?$"},
       "community[facebook_connect_id]": {required: false, minlength: 1, maxlength: 16, regex: "^([0-9]+)?$"},
       "community[facebook_connect_secret]": {required: false, minlength: 32, maxlength: 32, regex: "^([a-f0-9]+)?$"}
     },
     messages: {
      "community[twitter_handle]": { regex: invalid_twitter_handle_message },
      "community[facebook_connect_id]": {regex: invalid_facebook_connect_id_message },
      "community[facebook_connect_secret]": {regex: invalid_facebook_connect_secret_message }
    },
     submitHandler: function(form) {
       disable_and_submit(form_id, form, "false", locale);
     }
   });
}

function initialize_admin_listing_field_form_view(locale, form_id, option_count, min_count) {
  translate_validation_messages(locale);

  var $form = $(form_id);
  var CATEGORY_CHECKBOX_NAME = "custom_field[category_attributes][][category_id]";
  var MIN_NAME = "custom_field[min]";
  var MAX_NAME = "custom_field[max]";
  var DECIMAL_CHECKBOX = "custom_field[allow_decimals]";

  var rules = {}
  rules[CATEGORY_CHECKBOX_NAME] = {
    required: true
  };
  rules[MIN_NAME] = {
    min_bound: MAX_NAME,
    number_conditional_decimals: DECIMAL_CHECKBOX
  };
  rules[MAX_NAME] = {
    max_bound: MIN_NAME,
    number_conditional_decimals: DECIMAL_CHECKBOX
  };

  $(form_id).validate({
    rules: rules,
    errorPlacement: function(error, element) {
      // Custom placement for checkbox group
      if (element.attr("name") === CATEGORY_CHECKBOX_NAME) {
        var container = $("#custom-field-categories-container")
        error.insertAfter(container);
      } else {
        error.insertAfter(element);
      }
    },
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
   });

  // Create ST namespace if not exist
  window.ST = window.ST || {}
  ST.newOptionAdded = (function removeLinkEnabledState(initialCount, minCount, containerSelector, linkSelector) {
    var enabled;
    var count = initialCount;
    update();

    $(containerSelector).on("click", linkSelector, function(event) {
      event.preventDefault();

      if(enabled) {
        var el = $(event.currentTarget);
        var container = el.closest(".custom-field-option-container");
        container.remove();
        ST.customFieldOptionOrder.remove(container.data("field-id"));
        count -= 1;
        update();
      }
    });

    function update() {
      enabled = count > minCount;

      $links = $(linkSelector);
      $links.addClass(enabled ? "enabled" : "disabled");
      $links.removeClass(!enabled ? "enabled" : "disabled");
    }

    return {
      add: function() {
        count += 1;
        update();
      }
    };

  })(option_count, min_count, "#options", ".custom-field-option-remove").add;
}

function initialize_admin_category_form_view(locale, form_id) {
  translate_validation_messages(locale);

  var $form = $(form_id);
  var LISTING_SHAPE_CHECKBOX_NAME = "category[listing_shapes][][listing_shape_id]";

  var rules = {}
  rules[LISTING_SHAPE_CHECKBOX_NAME] = {
    required: true
  };

  $(form_id).validate({
    rules: rules,
    errorPlacement: function(error, element) {
      // Custom placement for checkbox group
      if (element.attr("name") === LISTING_SHAPE_CHECKBOX_NAME) {
        var container = $("#category-listing-shapes-container");
        error.insertAfter(container);
      } else {
        error.insertAfter(element);
      }
    },
    submitHandler: function(form) {
      disable_and_submit(form_id, form, "false", locale);
    }
   });

}

function initialize_new_community_membership_form(email_invalid_message, invitation_required, invalid_invitation_code_message) {
  $('#help_invitation_code_link').click(function(link) {
    $('#help_invitation_code').lightbox_me({centered: true, zIndex: 1000000 });
  });
  $('#terms_link').click(function(link) {
    link.preventDefault();
    $('#terms').lightbox_me({ centered: true, zIndex: 1000000 });
  });
  $('#new_community_membership').validate({
    errorPlacement: function(error, element) {
      if (element.attr("name") == "community_membership[consent]") {
        error.appendTo(element.parent().parent());
      } else {
        error.insertAfter(element);
      }
    },
    rules: {
      "community_membership[email]": {required: true, email: true, remote: "/people/check_email_availability_and_validity"},
      "community_membership[consent]": {required: true},
      "invitation_code": {required: invitation_required, remote: "/people/check_invitation_code"}
    },
    messages: {
      "community_membership[email]": { remote: email_invalid_message },
      "invitation_code": { remote: invalid_invitation_code_message }
    },
  });
}

function initialize_braintree_preauthorize_form(locale, beforeSubmit) {
  $('#transaction-agreement-read-more').click(function() { $('#transaction-agreement-content').lightbox_me({centered: true, zIndex: 1000000}); });

  var opts = {
    errorPlacement: function(error, element) {
      if (element.attr("name") == "listing_conversation[contract_agreed]") {
        error.appendTo(element.parent().parent());
      } else {
        error.insertAfter(element);
      }
    }
  }

  validateBraintreeForm(locale, beforeSubmit, opts);
}

function initialize_braintree_payment_form(locale, beforeSubmit) {
  validateBraintreeForm(locale, beforeSubmit);
}

function validateBraintreeForm(locale, beforeSubmit, opts) {
  opts = opts || {};
  beforeSubmit = beforeSubmit || function(callback) { callback() };

  var form_id = "#braintree-payment-form";

  var defaultValidationOptions = {
    rules: {
      "braintree_payment[cardholder_name]": {required: true, minlength: 2, maxlength: 50},
      "braintree_payment[credit_card_number]": {required: true, creditcard: true},
      "braintree_payment[cvv]": {required: true, digits: true, minlength: 3, maxlength: 4},
    },
    submitHandler: function(form) {
      beforeSubmit(function() {
        disable_and_submit(form_id, form, "false", locale);
      });
    }
  }

  var validationOptions = _.defaults(opts, defaultValidationOptions);

  $(form_id).validate(validationOptions);
}

function set_textarea_maxlength() {
  var ignore = [8,9,13,33,34,35,36,37,38,39,40,46];
  var eventName = 'keypress';
  $('textarea[maxlength]')
    .live(eventName, function(event) {
      var self = $(this),
          maxlength = self.attr('maxlength'),
          code = $.data(this, 'keycode');
      if (maxlength && maxlength > 0) {
        return ( self.val().length < maxlength
                 || $.inArray(code, ignore) !== -1 );

      }
    })
    .live('keydown', function(event) {
      $.data(this, 'keycode', event.keyCode || event.which);
    });
}

function get_date_from_date_select() {
  year = $('#listing_valid_until_1i').val();
  month = $('#listing_valid_until_2i').val();
  day = $('#listing_valid_until_3i').val();
  date = new Date(year,month-1,day,"23","59","58");
  return date;
}

function get_datetime_from_datetime_select() {
  year = $('#listing_valid_until_1i').val();
  month = $('#listing_valid_until_2i').val();
  day = $('#listing_valid_until_3i').val();
   hours= $('#listing_valid_until_4i').val();
  minutes = $('#listing_valid_until_5i').val();
  date = new Date(year,month-1,day,hours,minutes);
  return date;
}

function enableSamePageScroll() {
  function filterPath(string) {
  return string
    .replace(/^\//,'')
    .replace(/(index|default).[a-zA-Z]{3,4}$/,'')
    .replace(/\/$/,'');
  }
  var locationPath = filterPath(location.pathname);
  var scrollElem = scrollableElement('html', 'body');

  $('a[href*=#]').each(function() {
    var thisPath = filterPath(this.pathname) || locationPath;
    if (  locationPath == thisPath
    && (location.hostname == this.hostname || !this.hostname)
    && this.hash.replace(/#/,'') ) {
      var $target = $(this.hash), target = this.hash;
      if (target) {
        var targetOffset = $target.offset().top;
        $(this).click(function(event) {
          event.preventDefault();
          $(scrollElem).animate({scrollTop: targetOffset}, 400, function() {
            location.hash = target;
          });
        });
      }
    }
  });

  // use the first element that is "scrollable"
  function scrollableElement(els) {
    for (var i = 0, argLength = arguments.length; i <argLength; i++) {
      var el = arguments[i],
          $scrollElement = $(el);
      if ($scrollElement.scrollTop()> 0) {
        return el;
      } else {
        $scrollElement.scrollTop(1);
        var isScrollable = $scrollElement.scrollTop()> 0;
        $scrollElement.scrollTop(0);
        if (isScrollable) {
          return el;
        }
      }
    }
    return [];
  }
}
