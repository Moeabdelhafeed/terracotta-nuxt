// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Cancel`
  String get common_cancel {
    return Intl.message('Cancel', name: 'common_cancel', desc: '', args: []);
  }

  /// `Done`
  String get common_done {
    return Intl.message('Done', name: 'common_done', desc: '', args: []);
  }

  /// `OK`
  String get common_ok {
    return Intl.message('OK', name: 'common_ok', desc: '', args: []);
  }

  /// `Error`
  String get common_error {
    return Intl.message('Error', name: 'common_error', desc: '', args: []);
  }

  /// `Success`
  String get common_success {
    return Intl.message('Success', name: 'common_success', desc: '', args: []);
  }

  /// `Retry`
  String get common_retry {
    return Intl.message('Retry', name: 'common_retry', desc: '', args: []);
  }

  /// `Loading...`
  String get common_loading {
    return Intl.message(
      'Loading...',
      name: 'common_loading',
      desc: '',
      args: [],
    );
  }

  /// `Select Time`
  String get common_select_time {
    return Intl.message(
      'Select Time',
      name: 'common_select_time',
      desc: '',
      args: [],
    );
  }

  /// `Sign In`
  String get auth_sign_in {
    return Intl.message('Sign In', name: 'auth_sign_in', desc: '', args: []);
  }

  /// `Keep me signed in`
  String get auth_remember_me {
    return Intl.message(
      'Keep me signed in',
      name: 'auth_remember_me',
      desc: '',
      args: [],
    );
  }

  /// `Sign Out`
  String get auth_sign_out {
    return Intl.message('Sign Out', name: 'auth_sign_out', desc: '', args: []);
  }

  /// `Register`
  String get auth_register {
    return Intl.message('Register', name: 'auth_register', desc: '', args: []);
  }

  /// `Forgot Password?`
  String get auth_forgot_password {
    return Intl.message(
      'Forgot Password?',
      name: 'auth_forgot_password',
      desc: '',
      args: [],
    );
  }

  /// `Enter the {digits}-digit code sent to your phone`
  String auth_enter_otp(int digits) {
    return Intl.message(
      'Enter the $digits-digit code sent to your phone',
      name: 'auth_enter_otp',
      desc: '',
      args: [digits],
    );
  }

  /// `Welcome back, {name}`
  String auth_welcome_back(String name) {
    return Intl.message(
      'Welcome back, $name',
      name: 'auth_welcome_back',
      desc: '',
      args: [name],
    );
  }

  /// `First Name`
  String get auth_first_name_field_title {
    return Intl.message(
      'First Name',
      name: 'auth_first_name_field_title',
      desc: '',
      args: [],
    );
  }

  /// `Last Name`
  String get auth_last_name_field_title {
    return Intl.message(
      'Last Name',
      name: 'auth_last_name_field_title',
      desc: '',
      args: [],
    );
  }

  /// `Phone Number`
  String get auth_phone_number_field_title {
    return Intl.message(
      'Phone Number',
      name: 'auth_phone_number_field_title',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get auth_password_field_title {
    return Intl.message(
      'Password',
      name: 'auth_password_field_title',
      desc: '',
      args: [],
    );
  }

  /// `Confirm Password`
  String get auth_confirm_password_field_title {
    return Intl.message(
      'Confirm Password',
      name: 'auth_confirm_password_field_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter your first name`
  String get auth_enter_first_name_hint {
    return Intl.message(
      'Enter your first name',
      name: 'auth_enter_first_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter your last name`
  String get auth_enter_last_name_hint {
    return Intl.message(
      'Enter your last name',
      name: 'auth_enter_last_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter your phone number`
  String get auth_enter_phone_number_hint {
    return Intl.message(
      'Enter your phone number',
      name: 'auth_enter_phone_number_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter your middle name`
  String get auth_enter_middle_name_hint {
    return Intl.message(
      'Enter your middle name',
      name: 'auth_enter_middle_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter your father's name`
  String get auth_enter_father_name_hint {
    return Intl.message(
      'Enter your father\'s name',
      name: 'auth_enter_father_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter your full name`
  String get auth_enter_full_name_hint {
    return Intl.message(
      'Enter your full name',
      name: 'auth_enter_full_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter your password`
  String get auth_enter_password_hint {
    return Intl.message(
      'Enter your password',
      name: 'auth_enter_password_hint',
      desc: '',
      args: [],
    );
  }

  /// `Confirm your password`
  String get auth_enter_confirm_password_hint {
    return Intl.message(
      'Confirm your password',
      name: 'auth_enter_confirm_password_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{Your cart is empty} one{{count} item} other{{count} items}}`
  String cart_items(int count) {
    return Intl.plural(
      count,
      zero: 'Your cart is empty',
      one: '$count item',
      other: '$count items',
      name: 'cart_items',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =0{No new notifications} one{{count} new notification} other{{count} new notifications}}`
  String notifications_count(int count) {
    return Intl.plural(
      count,
      zero: 'No new notifications',
      one: '$count new notification',
      other: '$count new notifications',
      name: 'notifications_count',
      desc: '',
      args: [count],
    );
  }

  /// `Contains inappropriate language`
  String get validator_contains_inappropriate_language {
    return Intl.message(
      'Contains inappropriate language',
      name: 'validator_contains_inappropriate_language',
      desc: '',
      args: [],
    );
  }

  /// `This field is required`
  String get validator_field_is_required {
    return Intl.message(
      'This field is required',
      name: 'validator_field_is_required',
      desc: '',
      args: [],
    );
  }

  /// `Invalid format`
  String get validator_invalid_format {
    return Intl.message(
      'Invalid format',
      name: 'validator_invalid_format',
      desc: '',
      args: [],
    );
  }

  /// `Must be at least {n} characters`
  String validator_must_be_at_least_n_characters(int n) {
    return Intl.message(
      'Must be at least $n characters',
      name: 'validator_must_be_at_least_n_characters',
      desc: '',
      args: [n],
    );
  }

  /// `Must be at most {n} characters`
  String validator_must_be_at_most_n_characters(int n) {
    return Intl.message(
      'Must be at most $n characters',
      name: 'validator_must_be_at_most_n_characters',
      desc: '',
      args: [n],
    );
  }

  /// `Must be at least {n}`
  String validator_must_be_at_least_n(num n) {
    final NumberFormat nNumberFormat = NumberFormat.decimalPattern(
      Intl.getCurrentLocale(),
    );
    final String nString = nNumberFormat.format(n);

    return Intl.message(
      'Must be at least $nString',
      name: 'validator_must_be_at_least_n',
      desc: '',
      args: [nString],
    );
  }

  /// `Must be at most {n}`
  String validator_must_be_at_most_n(num n) {
    final NumberFormat nNumberFormat = NumberFormat.decimalPattern(
      Intl.getCurrentLocale(),
    );
    final String nString = nNumberFormat.format(n);

    return Intl.message(
      'Must be at most $nString',
      name: 'validator_must_be_at_most_n',
      desc: '',
      args: [nString],
    );
  }

  /// `First name cannot be empty`
  String get validator_first_name_cannot_be_empty {
    return Intl.message(
      'First name cannot be empty',
      name: 'validator_first_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `First name must be at least 3 characters long`
  String get validator_first_name_must_be_at_least_3_characters {
    return Intl.message(
      'First name must be at least 3 characters long',
      name: 'validator_first_name_must_be_at_least_3_characters',
      desc: '',
      args: [],
    );
  }

  /// `First name must be less than 50 characters`
  String get validator_first_name_must_be_less_than_50_characters {
    return Intl.message(
      'First name must be less than 50 characters',
      name: 'validator_first_name_must_be_less_than_50_characters',
      desc: '',
      args: [],
    );
  }

  /// `First name must contain only letters and spaces`
  String get validator_first_name_must_contain_only_letters_and_spaces {
    return Intl.message(
      'First name must contain only letters and spaces',
      name: 'validator_first_name_must_contain_only_letters_and_spaces',
      desc: '',
      args: [],
    );
  }

  /// `Last name cannot be empty`
  String get validator_last_name_cannot_be_empty {
    return Intl.message(
      'Last name cannot be empty',
      name: 'validator_last_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Last name must be at least 3 characters long`
  String get validator_last_name_must_be_at_least_3_characters {
    return Intl.message(
      'Last name must be at least 3 characters long',
      name: 'validator_last_name_must_be_at_least_3_characters',
      desc: '',
      args: [],
    );
  }

  /// `Last name must be less than 50 characters`
  String get validator_last_name_must_be_less_than_50_characters {
    return Intl.message(
      'Last name must be less than 50 characters',
      name: 'validator_last_name_must_be_less_than_50_characters',
      desc: '',
      args: [],
    );
  }

  /// `Last name must contain only letters and spaces`
  String get validator_last_name_must_contain_only_letters_and_spaces {
    return Intl.message(
      'Last name must contain only letters and spaces',
      name: 'validator_last_name_must_contain_only_letters_and_spaces',
      desc: '',
      args: [],
    );
  }

  /// `Middle name cannot be empty`
  String get validator_middle_name_cannot_be_empty {
    return Intl.message(
      'Middle name cannot be empty',
      name: 'validator_middle_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Middle name must be at least 3 characters long`
  String get validator_middle_name_must_be_at_least_3_characters {
    return Intl.message(
      'Middle name must be at least 3 characters long',
      name: 'validator_middle_name_must_be_at_least_3_characters',
      desc: '',
      args: [],
    );
  }

  /// `Middle name must be less than 50 characters`
  String get validator_middle_name_must_be_less_than_50_characters {
    return Intl.message(
      'Middle name must be less than 50 characters',
      name: 'validator_middle_name_must_be_less_than_50_characters',
      desc: '',
      args: [],
    );
  }

  /// `Middle name must contain only letters and spaces`
  String get validator_middle_name_must_contain_only_letters_and_spaces {
    return Intl.message(
      'Middle name must contain only letters and spaces',
      name: 'validator_middle_name_must_contain_only_letters_and_spaces',
      desc: '',
      args: [],
    );
  }

  /// `Father's name cannot be empty`
  String get validator_father_name_cannot_be_empty {
    return Intl.message(
      'Father\'s name cannot be empty',
      name: 'validator_father_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Father's name must be at least 3 characters long`
  String get validator_father_name_must_be_at_least_3_characters {
    return Intl.message(
      'Father\'s name must be at least 3 characters long',
      name: 'validator_father_name_must_be_at_least_3_characters',
      desc: '',
      args: [],
    );
  }

  /// `Father's name must be less than 50 characters`
  String get validator_father_name_must_be_less_than_50_characters {
    return Intl.message(
      'Father\'s name must be less than 50 characters',
      name: 'validator_father_name_must_be_less_than_50_characters',
      desc: '',
      args: [],
    );
  }

  /// `Father's name must contain only letters and spaces`
  String get validator_father_name_must_contain_only_letters_and_spaces {
    return Intl.message(
      'Father\'s name must contain only letters and spaces',
      name: 'validator_father_name_must_contain_only_letters_and_spaces',
      desc: '',
      args: [],
    );
  }

  /// `Full name cannot be empty`
  String get validator_full_name_cannot_be_empty {
    return Intl.message(
      'Full name cannot be empty',
      name: 'validator_full_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Full name must be less than 100 characters`
  String get validator_full_name_must_be_less_than_100_characters {
    return Intl.message(
      'Full name must be less than 100 characters',
      name: 'validator_full_name_must_be_less_than_100_characters',
      desc: '',
      args: [],
    );
  }

  /// `Full name must contain only letters and spaces`
  String get validator_full_name_must_contain_only_letters_and_spaces {
    return Intl.message(
      'Full name must contain only letters and spaces',
      name: 'validator_full_name_must_contain_only_letters_and_spaces',
      desc: '',
      args: [],
    );
  }

  /// `Full name must have at least {count} parts`
  String validator_full_name_must_have_at_least_n_parts(int count) {
    return Intl.message(
      'Full name must have at least $count parts',
      name: 'validator_full_name_must_have_at_least_n_parts',
      desc: '',
      args: [count],
    );
  }

  /// `Name must use Arabic letters`
  String get validator_name_must_use_arabic_letters {
    return Intl.message(
      'Name must use Arabic letters',
      name: 'validator_name_must_use_arabic_letters',
      desc: '',
      args: [],
    );
  }

  /// `Name must use English letters`
  String get validator_name_must_use_latin_letters {
    return Intl.message(
      'Name must use English letters',
      name: 'validator_name_must_use_latin_letters',
      desc: '',
      args: [],
    );
  }

  /// `Phone number cannot be empty`
  String get validator_phone_number_cannot_be_empty {
    return Intl.message(
      'Phone number cannot be empty',
      name: 'validator_phone_number_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Phone number must contain only digits`
  String get validator_phone_number_must_contain_only_digits {
    return Intl.message(
      'Phone number must contain only digits',
      name: 'validator_phone_number_must_contain_only_digits',
      desc: '',
      args: [],
    );
  }

  /// `Phone number is too short`
  String get validator_phone_number_is_too_short {
    return Intl.message(
      'Phone number is too short',
      name: 'validator_phone_number_is_too_short',
      desc: '',
      args: [],
    );
  }

  /// `Phone number is too long`
  String get validator_phone_number_is_too_long {
    return Intl.message(
      'Phone number is too long',
      name: 'validator_phone_number_is_too_long',
      desc: '',
      args: [],
    );
  }

  /// `Invalid country code`
  String get validator_invalid_country_code {
    return Intl.message(
      'Invalid country code',
      name: 'validator_invalid_country_code',
      desc: '',
      args: [],
    );
  }

  /// `Password cannot be empty`
  String get validator_password_cannot_be_empty {
    return Intl.message(
      'Password cannot be empty',
      name: 'validator_password_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Password must be at least 6 characters long`
  String get validator_password_must_be_at_least_6_characters {
    return Intl.message(
      'Password must be at least 6 characters long',
      name: 'validator_password_must_be_at_least_6_characters',
      desc: '',
      args: [],
    );
  }

  /// `Password must contain at least one uppercase letter`
  String get validator_password_must_contain_at_least_one_uppercase_letter {
    return Intl.message(
      'Password must contain at least one uppercase letter',
      name: 'validator_password_must_contain_at_least_one_uppercase_letter',
      desc: '',
      args: [],
    );
  }

  /// `Password must contain at least one lowercase letter`
  String get validator_password_must_contain_at_least_one_lowercase_letter {
    return Intl.message(
      'Password must contain at least one lowercase letter',
      name: 'validator_password_must_contain_at_least_one_lowercase_letter',
      desc: '',
      args: [],
    );
  }

  /// `Password must contain at least one number`
  String get validator_password_must_contain_at_least_one_number {
    return Intl.message(
      'Password must contain at least one number',
      name: 'validator_password_must_contain_at_least_one_number',
      desc: '',
      args: [],
    );
  }

  /// `Password must contain at least one special character`
  String get validator_password_must_contain_at_least_one_special_character {
    return Intl.message(
      'Password must contain at least one special character',
      name: 'validator_password_must_contain_at_least_one_special_character',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password cannot be empty`
  String get validator_confirm_password_cannot_be_empty {
    return Intl.message(
      'Confirm password cannot be empty',
      name: 'validator_confirm_password_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password must be the same as password`
  String get validator_confirm_password_must_be_the_same_as_password {
    return Intl.message(
      'Confirm password must be the same as password',
      name: 'validator_confirm_password_must_be_the_same_as_password',
      desc: '',
      args: [],
    );
  }

  /// `Gender cannot be empty`
  String get validator_gender_cannot_be_empty {
    return Intl.message(
      'Gender cannot be empty',
      name: 'validator_gender_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Email cannot be empty`
  String get validator_email_cannot_be_empty {
    return Intl.message(
      'Email cannot be empty',
      name: 'validator_email_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Email must be valid`
  String get validator_email_must_be_valid {
    return Intl.message(
      'Email must be valid',
      name: 'validator_email_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Age cannot be empty`
  String get validator_age_cannot_be_empty {
    return Intl.message(
      'Age cannot be empty',
      name: 'validator_age_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Age must be at least 12 years old`
  String get validator_age_must_be_at_least_12 {
    return Intl.message(
      'Age must be at least 12 years old',
      name: 'validator_age_must_be_at_least_12',
      desc: '',
      args: [],
    );
  }

  /// `Age must be less than 100 years old`
  String get validator_age_must_be_less_than_100 {
    return Intl.message(
      'Age must be less than 100 years old',
      name: 'validator_age_must_be_less_than_100',
      desc: '',
      args: [],
    );
  }

  /// `Username cannot be empty`
  String get validator_username_cannot_be_empty {
    return Intl.message(
      'Username cannot be empty',
      name: 'validator_username_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Username must be at least 3 characters long`
  String get validator_username_must_be_at_least_3_characters {
    return Intl.message(
      'Username must be at least 3 characters long',
      name: 'validator_username_must_be_at_least_3_characters',
      desc: '',
      args: [],
    );
  }

  /// `Username must be less than 20 characters`
  String get validator_username_must_be_less_than_20_characters {
    return Intl.message(
      'Username must be less than 20 characters',
      name: 'validator_username_must_be_less_than_20_characters',
      desc: '',
      args: [],
    );
  }

  /// `Username must be valid`
  String get validator_username_must_be_valid {
    return Intl.message(
      'Username must be valid',
      name: 'validator_username_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `OTP cannot be empty`
  String get validator_otp_cannot_be_empty {
    return Intl.message(
      'OTP cannot be empty',
      name: 'validator_otp_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `OTP must be {length} digits`
  String validator_otp_must_be_n_digits(int length) {
    return Intl.message(
      'OTP must be $length digits',
      name: 'validator_otp_must_be_n_digits',
      desc: '',
      args: [length],
    );
  }

  /// `Date of birth cannot be empty`
  String get validator_date_of_birth_cannot_be_empty {
    return Intl.message(
      'Date of birth cannot be empty',
      name: 'validator_date_of_birth_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Date of birth must be between 1900 and the current date`
  String get validator_date_of_birth_must_be_valid {
    return Intl.message(
      'Date of birth must be between 1900 and the current date',
      name: 'validator_date_of_birth_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Date cannot be empty`
  String get validator_date_cannot_be_empty {
    return Intl.message(
      'Date cannot be empty',
      name: 'validator_date_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Date must be in the future`
  String get validator_date_must_be_in_the_future {
    return Intl.message(
      'Date must be in the future',
      name: 'validator_date_must_be_in_the_future',
      desc: '',
      args: [],
    );
  }

  /// `Date must be in the past`
  String get validator_date_must_be_in_the_past {
    return Intl.message(
      'Date must be in the past',
      name: 'validator_date_must_be_in_the_past',
      desc: '',
      args: [],
    );
  }

  /// `Must be at least {years} years old`
  String validator_age_at_least_n_years(int years) {
    return Intl.message(
      'Must be at least $years years old',
      name: 'validator_age_at_least_n_years',
      desc: '',
      args: [years],
    );
  }

  /// `Must be {years} years old or younger`
  String validator_age_under_n_years(int years) {
    return Intl.message(
      'Must be $years years old or younger',
      name: 'validator_age_under_n_years',
      desc: '',
      args: [years],
    );
  }

  /// `Passport number cannot be empty`
  String get validator_passport_number_cannot_be_empty {
    return Intl.message(
      'Passport number cannot be empty',
      name: 'validator_passport_number_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Passport number must be at least 3 characters long`
  String get validator_passport_number_must_be_at_least_3_characters {
    return Intl.message(
      'Passport number must be at least 3 characters long',
      name: 'validator_passport_number_must_be_at_least_3_characters',
      desc: '',
      args: [],
    );
  }

  /// `Passport number must be less than 50 characters`
  String get validator_passport_number_must_be_less_than_50_characters {
    return Intl.message(
      'Passport number must be less than 50 characters',
      name: 'validator_passport_number_must_be_less_than_50_characters',
      desc: '',
      args: [],
    );
  }

  /// `Passport expiry date cannot be empty`
  String get validator_passport_expiry_date_cannot_be_empty {
    return Intl.message(
      'Passport expiry date cannot be empty',
      name: 'validator_passport_expiry_date_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Passport expiry date must be at least 6 months from now`
  String get validator_passport_expiry_date_must_be_at_least_6_months_from_now {
    return Intl.message(
      'Passport expiry date must be at least 6 months from now',
      name: 'validator_passport_expiry_date_must_be_at_least_6_months_from_now',
      desc: '',
      args: [],
    );
  }

  /// `Number cannot be empty`
  String get validator_number_cannot_be_empty {
    return Intl.message(
      'Number cannot be empty',
      name: 'validator_number_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Must be a valid number`
  String get validator_must_be_a_valid_number {
    return Intl.message(
      'Must be a valid number',
      name: 'validator_must_be_a_valid_number',
      desc: '',
      args: [],
    );
  }

  /// `Must be a valid integer`
  String get validator_must_be_a_valid_integer {
    return Intl.message(
      'Must be a valid integer',
      name: 'validator_must_be_a_valid_integer',
      desc: '',
      args: [],
    );
  }

  /// `Please select at least one item`
  String get validator_list_cannot_be_empty {
    return Intl.message(
      'Please select at least one item',
      name: 'validator_list_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Please select at least {n} items`
  String validator_list_must_have_at_least(int n) {
    return Intl.message(
      'Please select at least $n items',
      name: 'validator_list_must_have_at_least',
      desc: '',
      args: [n],
    );
  }

  /// `Please select at most {n} items`
  String validator_list_must_have_at_most(int n) {
    return Intl.message(
      'Please select at most $n items',
      name: 'validator_list_must_have_at_most',
      desc: '',
      args: [n],
    );
  }

  /// `Card number cannot be empty`
  String get validator_card_number_cannot_be_empty {
    return Intl.message(
      'Card number cannot be empty',
      name: 'validator_card_number_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Card number is invalid`
  String get validator_card_number_must_be_valid {
    return Intl.message(
      'Card number is invalid',
      name: 'validator_card_number_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Card expiry cannot be empty`
  String get validator_card_expiry_cannot_be_empty {
    return Intl.message(
      'Card expiry cannot be empty',
      name: 'validator_card_expiry_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Card expiry must be MM/YY or MM/YYYY`
  String get validator_card_expiry_must_be_valid {
    return Intl.message(
      'Card expiry must be MM/YY or MM/YYYY',
      name: 'validator_card_expiry_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Card expiry must be MM/YY`
  String get validator_card_expiry_must_be_mm_yy {
    return Intl.message(
      'Card expiry must be MM/YY',
      name: 'validator_card_expiry_must_be_mm_yy',
      desc: '',
      args: [],
    );
  }

  /// `Month must be between 01 and 12`
  String get validator_card_expiry_month_invalid {
    return Intl.message(
      'Month must be between 01 and 12',
      name: 'validator_card_expiry_month_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Card has expired`
  String get validator_card_expiry_must_be_in_the_future {
    return Intl.message(
      'Card has expired',
      name: 'validator_card_expiry_must_be_in_the_future',
      desc: '',
      args: [],
    );
  }

  /// `CVV cannot be empty`
  String get validator_card_cvv_cannot_be_empty {
    return Intl.message(
      'CVV cannot be empty',
      name: 'validator_card_cvv_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `CVV must be 3 or 4 digits`
  String get validator_card_cvv_must_be_valid {
    return Intl.message(
      'CVV must be 3 or 4 digits',
      name: 'validator_card_cvv_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `CVV must be {length} digits`
  String validator_card_cvv_must_be_n_digits(int length) {
    return Intl.message(
      'CVV must be $length digits',
      name: 'validator_card_cvv_must_be_n_digits',
      desc: '',
      args: [length],
    );
  }

  /// `Latitude cannot be empty`
  String get validator_latitude_cannot_be_empty {
    return Intl.message(
      'Latitude cannot be empty',
      name: 'validator_latitude_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Latitude must be between -90 and 90`
  String get validator_latitude_must_be_valid {
    return Intl.message(
      'Latitude must be between -90 and 90',
      name: 'validator_latitude_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Longitude cannot be empty`
  String get validator_longitude_cannot_be_empty {
    return Intl.message(
      'Longitude cannot be empty',
      name: 'validator_longitude_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Longitude must be between -180 and 180`
  String get validator_longitude_must_be_valid {
    return Intl.message(
      'Longitude must be between -180 and 180',
      name: 'validator_longitude_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Postal code cannot be empty`
  String get validator_postal_code_cannot_be_empty {
    return Intl.message(
      'Postal code cannot be empty',
      name: 'validator_postal_code_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Postal code is invalid`
  String get validator_postal_code_must_be_valid {
    return Intl.message(
      'Postal code is invalid',
      name: 'validator_postal_code_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `IP address cannot be empty`
  String get validator_ip_address_cannot_be_empty {
    return Intl.message(
      'IP address cannot be empty',
      name: 'validator_ip_address_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `IP address is invalid`
  String get validator_ip_address_must_be_valid {
    return Intl.message(
      'IP address is invalid',
      name: 'validator_ip_address_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Port cannot be empty`
  String get validator_port_cannot_be_empty {
    return Intl.message(
      'Port cannot be empty',
      name: 'validator_port_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Port must be between 1 and 65535`
  String get validator_port_must_be_valid {
    return Intl.message(
      'Port must be between 1 and 65535',
      name: 'validator_port_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `MAC address cannot be empty`
  String get validator_mac_address_cannot_be_empty {
    return Intl.message(
      'MAC address cannot be empty',
      name: 'validator_mac_address_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `MAC address is invalid`
  String get validator_mac_address_must_be_valid {
    return Intl.message(
      'MAC address is invalid',
      name: 'validator_mac_address_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `IBAN cannot be empty`
  String get validator_iban_cannot_be_empty {
    return Intl.message(
      'IBAN cannot be empty',
      name: 'validator_iban_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `IBAN is invalid`
  String get validator_iban_must_be_valid {
    return Intl.message(
      'IBAN is invalid',
      name: 'validator_iban_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `A {country} IBAN must be {length} characters`
  String validator_iban_length_for_country(String country, int length) {
    return Intl.message(
      'A $country IBAN must be $length characters',
      name: 'validator_iban_length_for_country',
      desc: '',
      args: [country, length],
    );
  }

  /// `VIN cannot be empty`
  String get validator_vin_cannot_be_empty {
    return Intl.message(
      'VIN cannot be empty',
      name: 'validator_vin_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `VIN is invalid`
  String get validator_vin_must_be_valid {
    return Intl.message(
      'VIN is invalid',
      name: 'validator_vin_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `File size is missing`
  String get validator_file_size_cannot_be_empty {
    return Intl.message(
      'File size is missing',
      name: 'validator_file_size_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `File is too large`
  String get validator_file_size_too_large {
    return Intl.message(
      'File is too large',
      name: 'validator_file_size_too_large',
      desc: '',
      args: [],
    );
  }

  /// `File name cannot be empty`
  String get validator_file_name_cannot_be_empty {
    return Intl.message(
      'File name cannot be empty',
      name: 'validator_file_name_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `File name contains invalid characters`
  String get validator_file_name_invalid {
    return Intl.message(
      'File name contains invalid characters',
      name: 'validator_file_name_invalid',
      desc: '',
      args: [],
    );
  }

  /// `File extension is not allowed`
  String get validator_file_extension_not_allowed {
    return Intl.message(
      'File extension is not allowed',
      name: 'validator_file_extension_not_allowed',
      desc: '',
      args: [],
    );
  }

  /// `URL cannot be empty`
  String get validator_url_cannot_be_empty {
    return Intl.message(
      'URL cannot be empty',
      name: 'validator_url_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `URL must be valid`
  String get validator_url_must_be_valid {
    return Intl.message(
      'URL must be valid',
      name: 'validator_url_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `URL must start with http:// or https://`
  String get validator_url_must_start_with_http_or_https {
    return Intl.message(
      'URL must start with http:// or https://',
      name: 'validator_url_must_start_with_http_or_https',
      desc: '',
      args: [],
    );
  }

  /// `Image URL cannot be empty`
  String get validator_image_url_cannot_be_empty {
    return Intl.message(
      'Image URL cannot be empty',
      name: 'validator_image_url_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Image URL must be valid`
  String get validator_image_url_must_be_valid {
    return Intl.message(
      'Image URL must be valid',
      name: 'validator_image_url_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Video URL cannot be empty`
  String get validator_video_url_cannot_be_empty {
    return Intl.message(
      'Video URL cannot be empty',
      name: 'validator_video_url_cannot_be_empty',
      desc: '',
      args: [],
    );
  }

  /// `Video URL must be valid`
  String get validator_video_url_must_be_valid {
    return Intl.message(
      'Video URL must be valid',
      name: 'validator_video_url_must_be_valid',
      desc: '',
      args: [],
    );
  }

  /// `Failed to pick image`
  String get media_failed_to_pick_image {
    return Intl.message(
      'Failed to pick image',
      name: 'media_failed_to_pick_image',
      desc: '',
      args: [],
    );
  }

  /// `Failed to pick images`
  String get media_failed_to_pick_images {
    return Intl.message(
      'Failed to pick images',
      name: 'media_failed_to_pick_images',
      desc: '',
      args: [],
    );
  }

  /// `Failed to pick video`
  String get media_failed_to_pick_video {
    return Intl.message(
      'Failed to pick video',
      name: 'media_failed_to_pick_video',
      desc: '',
      args: [],
    );
  }

  /// `Failed to pick videos`
  String get media_failed_to_pick_videos {
    return Intl.message(
      'Failed to pick videos',
      name: 'media_failed_to_pick_videos',
      desc: '',
      args: [],
    );
  }

  /// `Failed to compress image`
  String get media_failed_to_compress_image {
    return Intl.message(
      'Failed to compress image',
      name: 'media_failed_to_compress_image',
      desc: '',
      args: [],
    );
  }

  /// `Image too large, compression failed`
  String get media_image_too_large_compression_failed {
    return Intl.message(
      'Image too large, compression failed',
      name: 'media_image_too_large_compression_failed',
      desc: '',
      args: [],
    );
  }

  /// `Page not found`
  String get nav_page_not_found {
    return Intl.message(
      'Page not found',
      name: 'nav_page_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Go Home`
  String get nav_go_home {
    return Intl.message('Go Home', name: 'nav_go_home', desc: '', args: []);
  }

  /// `Swipe again to exit`
  String get nav_exit_confirm {
    return Intl.message(
      'Swipe again to exit',
      name: 'nav_exit_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get api_status_continue {
    return Intl.message(
      'Continue',
      name: 'api_status_continue',
      desc: '',
      args: [],
    );
  }

  /// `Switching Protocols`
  String get api_status_switching_protocols {
    return Intl.message(
      'Switching Protocols',
      name: 'api_status_switching_protocols',
      desc: '',
      args: [],
    );
  }

  /// `Processing`
  String get api_status_processing {
    return Intl.message(
      'Processing',
      name: 'api_status_processing',
      desc: '',
      args: [],
    );
  }

  /// `Early Hints`
  String get api_status_early_hints {
    return Intl.message(
      'Early Hints',
      name: 'api_status_early_hints',
      desc: '',
      args: [],
    );
  }

  /// `OK`
  String get api_status_ok {
    return Intl.message('OK', name: 'api_status_ok', desc: '', args: []);
  }

  /// `Created`
  String get api_status_created {
    return Intl.message(
      'Created',
      name: 'api_status_created',
      desc: '',
      args: [],
    );
  }

  /// `Accepted`
  String get api_status_accepted {
    return Intl.message(
      'Accepted',
      name: 'api_status_accepted',
      desc: '',
      args: [],
    );
  }

  /// `Non-Authoritative Information`
  String get api_status_non_authoritative_information {
    return Intl.message(
      'Non-Authoritative Information',
      name: 'api_status_non_authoritative_information',
      desc: '',
      args: [],
    );
  }

  /// `No Content`
  String get api_status_no_content {
    return Intl.message(
      'No Content',
      name: 'api_status_no_content',
      desc: '',
      args: [],
    );
  }

  /// `Reset Content`
  String get api_status_reset_content {
    return Intl.message(
      'Reset Content',
      name: 'api_status_reset_content',
      desc: '',
      args: [],
    );
  }

  /// `Partial Content`
  String get api_status_partial_content {
    return Intl.message(
      'Partial Content',
      name: 'api_status_partial_content',
      desc: '',
      args: [],
    );
  }

  /// `Multi-Status`
  String get api_status_multi_status {
    return Intl.message(
      'Multi-Status',
      name: 'api_status_multi_status',
      desc: '',
      args: [],
    );
  }

  /// `Already Reported`
  String get api_status_already_reported {
    return Intl.message(
      'Already Reported',
      name: 'api_status_already_reported',
      desc: '',
      args: [],
    );
  }

  /// `IM Used`
  String get api_status_im_used {
    return Intl.message(
      'IM Used',
      name: 'api_status_im_used',
      desc: '',
      args: [],
    );
  }

  /// `Multiple Choices`
  String get api_status_multiple_choices {
    return Intl.message(
      'Multiple Choices',
      name: 'api_status_multiple_choices',
      desc: '',
      args: [],
    );
  }

  /// `Moved Permanently`
  String get api_status_moved_permanently {
    return Intl.message(
      'Moved Permanently',
      name: 'api_status_moved_permanently',
      desc: '',
      args: [],
    );
  }

  /// `Found`
  String get api_status_found {
    return Intl.message('Found', name: 'api_status_found', desc: '', args: []);
  }

  /// `See Other`
  String get api_status_see_other {
    return Intl.message(
      'See Other',
      name: 'api_status_see_other',
      desc: '',
      args: [],
    );
  }

  /// `Not Modified`
  String get api_status_not_modified {
    return Intl.message(
      'Not Modified',
      name: 'api_status_not_modified',
      desc: '',
      args: [],
    );
  }

  /// `Use Proxy`
  String get api_status_use_proxy {
    return Intl.message(
      'Use Proxy',
      name: 'api_status_use_proxy',
      desc: '',
      args: [],
    );
  }

  /// `Temporary Redirect`
  String get api_status_temporary_redirect {
    return Intl.message(
      'Temporary Redirect',
      name: 'api_status_temporary_redirect',
      desc: '',
      args: [],
    );
  }

  /// `Permanent Redirect`
  String get api_status_permanent_redirect {
    return Intl.message(
      'Permanent Redirect',
      name: 'api_status_permanent_redirect',
      desc: '',
      args: [],
    );
  }

  /// `Bad Request`
  String get api_status_bad_request {
    return Intl.message(
      'Bad Request',
      name: 'api_status_bad_request',
      desc: '',
      args: [],
    );
  }

  /// `Unauthorized`
  String get api_status_unauthorized {
    return Intl.message(
      'Unauthorized',
      name: 'api_status_unauthorized',
      desc: '',
      args: [],
    );
  }

  /// `Payment Required`
  String get api_status_payment_required {
    return Intl.message(
      'Payment Required',
      name: 'api_status_payment_required',
      desc: '',
      args: [],
    );
  }

  /// `Forbidden`
  String get api_status_forbidden {
    return Intl.message(
      'Forbidden',
      name: 'api_status_forbidden',
      desc: '',
      args: [],
    );
  }

  /// `Not Found`
  String get api_status_not_found {
    return Intl.message(
      'Not Found',
      name: 'api_status_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Method Not Allowed`
  String get api_status_method_not_allowed {
    return Intl.message(
      'Method Not Allowed',
      name: 'api_status_method_not_allowed',
      desc: '',
      args: [],
    );
  }

  /// `Not Acceptable`
  String get api_status_not_acceptable {
    return Intl.message(
      'Not Acceptable',
      name: 'api_status_not_acceptable',
      desc: '',
      args: [],
    );
  }

  /// `Proxy Authentication Required`
  String get api_status_proxy_authentication_required {
    return Intl.message(
      'Proxy Authentication Required',
      name: 'api_status_proxy_authentication_required',
      desc: '',
      args: [],
    );
  }

  /// `Request Timeout`
  String get api_status_request_timeout {
    return Intl.message(
      'Request Timeout',
      name: 'api_status_request_timeout',
      desc: '',
      args: [],
    );
  }

  /// `Conflict`
  String get api_status_conflict {
    return Intl.message(
      'Conflict',
      name: 'api_status_conflict',
      desc: '',
      args: [],
    );
  }

  /// `Gone`
  String get api_status_gone {
    return Intl.message('Gone', name: 'api_status_gone', desc: '', args: []);
  }

  /// `Length Required`
  String get api_status_length_required {
    return Intl.message(
      'Length Required',
      name: 'api_status_length_required',
      desc: '',
      args: [],
    );
  }

  /// `Precondition Failed`
  String get api_status_precondition_failed {
    return Intl.message(
      'Precondition Failed',
      name: 'api_status_precondition_failed',
      desc: '',
      args: [],
    );
  }

  /// `Payload Too Large`
  String get api_status_payload_too_large {
    return Intl.message(
      'Payload Too Large',
      name: 'api_status_payload_too_large',
      desc: '',
      args: [],
    );
  }

  /// `URI Too Long`
  String get api_status_uri_too_long {
    return Intl.message(
      'URI Too Long',
      name: 'api_status_uri_too_long',
      desc: '',
      args: [],
    );
  }

  /// `Unsupported Media Type`
  String get api_status_unsupported_media_type {
    return Intl.message(
      'Unsupported Media Type',
      name: 'api_status_unsupported_media_type',
      desc: '',
      args: [],
    );
  }

  /// `Range Not Satisfiable`
  String get api_status_range_not_satisfiable {
    return Intl.message(
      'Range Not Satisfiable',
      name: 'api_status_range_not_satisfiable',
      desc: '',
      args: [],
    );
  }

  /// `Expectation Failed`
  String get api_status_expectation_failed {
    return Intl.message(
      'Expectation Failed',
      name: 'api_status_expectation_failed',
      desc: '',
      args: [],
    );
  }

  /// `Misdirected Request`
  String get api_status_misdirected_request {
    return Intl.message(
      'Misdirected Request',
      name: 'api_status_misdirected_request',
      desc: '',
      args: [],
    );
  }

  /// `Validation Error`
  String get api_status_validation_error {
    return Intl.message(
      'Validation Error',
      name: 'api_status_validation_error',
      desc: '',
      args: [],
    );
  }

  /// `Locked`
  String get api_status_locked {
    return Intl.message(
      'Locked',
      name: 'api_status_locked',
      desc: '',
      args: [],
    );
  }

  /// `Failed Dependency`
  String get api_status_failed_dependency {
    return Intl.message(
      'Failed Dependency',
      name: 'api_status_failed_dependency',
      desc: '',
      args: [],
    );
  }

  /// `Too Early`
  String get api_status_too_early {
    return Intl.message(
      'Too Early',
      name: 'api_status_too_early',
      desc: '',
      args: [],
    );
  }

  /// `Upgrade Required`
  String get api_status_upgrade_required {
    return Intl.message(
      'Upgrade Required',
      name: 'api_status_upgrade_required',
      desc: '',
      args: [],
    );
  }

  /// `Precondition Required`
  String get api_status_precondition_required {
    return Intl.message(
      'Precondition Required',
      name: 'api_status_precondition_required',
      desc: '',
      args: [],
    );
  }

  /// `Too Many Requests`
  String get api_status_too_many_requests {
    return Intl.message(
      'Too Many Requests',
      name: 'api_status_too_many_requests',
      desc: '',
      args: [],
    );
  }

  /// `Request Header Fields Too Large`
  String get api_status_request_header_fields_too_large {
    return Intl.message(
      'Request Header Fields Too Large',
      name: 'api_status_request_header_fields_too_large',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable For Legal Reasons`
  String get api_status_unavailable_for_legal_reasons {
    return Intl.message(
      'Unavailable For Legal Reasons',
      name: 'api_status_unavailable_for_legal_reasons',
      desc: '',
      args: [],
    );
  }

  /// `Internal Server Error`
  String get api_status_internal_server_error {
    return Intl.message(
      'Internal Server Error',
      name: 'api_status_internal_server_error',
      desc: '',
      args: [],
    );
  }

  /// `Not Implemented`
  String get api_status_not_implemented {
    return Intl.message(
      'Not Implemented',
      name: 'api_status_not_implemented',
      desc: '',
      args: [],
    );
  }

  /// `Bad Gateway`
  String get api_status_bad_gateway {
    return Intl.message(
      'Bad Gateway',
      name: 'api_status_bad_gateway',
      desc: '',
      args: [],
    );
  }

  /// `Service Unavailable`
  String get api_status_service_unavailable {
    return Intl.message(
      'Service Unavailable',
      name: 'api_status_service_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Gateway Timeout`
  String get api_status_gateway_timeout {
    return Intl.message(
      'Gateway Timeout',
      name: 'api_status_gateway_timeout',
      desc: '',
      args: [],
    );
  }

  /// `HTTP Version Not Supported`
  String get api_status_http_version_not_supported {
    return Intl.message(
      'HTTP Version Not Supported',
      name: 'api_status_http_version_not_supported',
      desc: '',
      args: [],
    );
  }

  /// `Variant Also Negotiates`
  String get api_status_variant_also_negotiates {
    return Intl.message(
      'Variant Also Negotiates',
      name: 'api_status_variant_also_negotiates',
      desc: '',
      args: [],
    );
  }

  /// `Insufficient Storage`
  String get api_status_insufficient_storage {
    return Intl.message(
      'Insufficient Storage',
      name: 'api_status_insufficient_storage',
      desc: '',
      args: [],
    );
  }

  /// `Loop Detected`
  String get api_status_loop_detected {
    return Intl.message(
      'Loop Detected',
      name: 'api_status_loop_detected',
      desc: '',
      args: [],
    );
  }

  /// `Not Extended`
  String get api_status_not_extended {
    return Intl.message(
      'Not Extended',
      name: 'api_status_not_extended',
      desc: '',
      args: [],
    );
  }

  /// `Network Authentication Required`
  String get api_status_network_authentication_required {
    return Intl.message(
      'Network Authentication Required',
      name: 'api_status_network_authentication_required',
      desc: '',
      args: [],
    );
  }

  /// `Network Error`
  String get api_status_network_error {
    return Intl.message(
      'Network Error',
      name: 'api_status_network_error',
      desc: '',
      args: [],
    );
  }

  /// `Timeout`
  String get api_status_timeout {
    return Intl.message(
      'Timeout',
      name: 'api_status_timeout',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get api_status_cancelled {
    return Intl.message(
      'Cancelled',
      name: 'api_status_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Unknown Error`
  String get api_status_unknown_error {
    return Intl.message(
      'Unknown Error',
      name: 'api_status_unknown_error',
      desc: '',
      args: [],
    );
  }

  /// `Jordan`
  String get country_jordan {
    return Intl.message('Jordan', name: 'country_jordan', desc: '', args: []);
  }

  /// `United States`
  String get country_united_states {
    return Intl.message(
      'United States',
      name: 'country_united_states',
      desc: '',
      args: [],
    );
  }

  /// `United Kingdom`
  String get country_united_kingdom {
    return Intl.message(
      'United Kingdom',
      name: 'country_united_kingdom',
      desc: '',
      args: [],
    );
  }

  /// `Saudi Arabia`
  String get country_saudi_arabia {
    return Intl.message(
      'Saudi Arabia',
      name: 'country_saudi_arabia',
      desc: '',
      args: [],
    );
  }

  /// `United Arab Emirates`
  String get country_united_arab_emirates {
    return Intl.message(
      'United Arab Emirates',
      name: 'country_united_arab_emirates',
      desc: '',
      args: [],
    );
  }

  /// `Kuwait`
  String get country_kuwait {
    return Intl.message('Kuwait', name: 'country_kuwait', desc: '', args: []);
  }

  /// `Qatar`
  String get country_qatar {
    return Intl.message('Qatar', name: 'country_qatar', desc: '', args: []);
  }

  /// `Bahrain`
  String get country_bahrain {
    return Intl.message('Bahrain', name: 'country_bahrain', desc: '', args: []);
  }

  /// `Oman`
  String get country_oman {
    return Intl.message('Oman', name: 'country_oman', desc: '', args: []);
  }

  /// `Egypt`
  String get country_egypt {
    return Intl.message('Egypt', name: 'country_egypt', desc: '', args: []);
  }

  /// `Lebanon`
  String get country_lebanon {
    return Intl.message('Lebanon', name: 'country_lebanon', desc: '', args: []);
  }

  /// `Syria`
  String get country_syria {
    return Intl.message('Syria', name: 'country_syria', desc: '', args: []);
  }

  /// `Iraq`
  String get country_iraq {
    return Intl.message('Iraq', name: 'country_iraq', desc: '', args: []);
  }

  /// `Palestine`
  String get country_palestine {
    return Intl.message(
      'Palestine',
      name: 'country_palestine',
      desc: '',
      args: [],
    );
  }

  /// `Yemen`
  String get country_yemen {
    return Intl.message('Yemen', name: 'country_yemen', desc: '', args: []);
  }

  /// `Libya`
  String get country_libya {
    return Intl.message('Libya', name: 'country_libya', desc: '', args: []);
  }

  /// `Tunisia`
  String get country_tunisia {
    return Intl.message('Tunisia', name: 'country_tunisia', desc: '', args: []);
  }

  /// `Algeria`
  String get country_algeria {
    return Intl.message('Algeria', name: 'country_algeria', desc: '', args: []);
  }

  /// `Morocco`
  String get country_morocco {
    return Intl.message('Morocco', name: 'country_morocco', desc: '', args: []);
  }

  /// `Sudan`
  String get country_sudan {
    return Intl.message('Sudan', name: 'country_sudan', desc: '', args: []);
  }

  /// `Turkey`
  String get country_turkey {
    return Intl.message('Turkey', name: 'country_turkey', desc: '', args: []);
  }

  /// `Iran`
  String get country_iran {
    return Intl.message('Iran', name: 'country_iran', desc: '', args: []);
  }

  /// `Pakistan`
  String get country_pakistan {
    return Intl.message(
      'Pakistan',
      name: 'country_pakistan',
      desc: '',
      args: [],
    );
  }

  /// `Afghanistan`
  String get country_afghanistan {
    return Intl.message(
      'Afghanistan',
      name: 'country_afghanistan',
      desc: '',
      args: [],
    );
  }

  /// `India`
  String get country_india {
    return Intl.message('India', name: 'country_india', desc: '', args: []);
  }

  /// `Bangladesh`
  String get country_bangladesh {
    return Intl.message(
      'Bangladesh',
      name: 'country_bangladesh',
      desc: '',
      args: [],
    );
  }

  /// `Sri Lanka`
  String get country_sri_lanka {
    return Intl.message(
      'Sri Lanka',
      name: 'country_sri_lanka',
      desc: '',
      args: [],
    );
  }

  /// `Nepal`
  String get country_nepal {
    return Intl.message('Nepal', name: 'country_nepal', desc: '', args: []);
  }

  /// `Myanmar`
  String get country_myanmar {
    return Intl.message('Myanmar', name: 'country_myanmar', desc: '', args: []);
  }

  /// `Thailand`
  String get country_thailand {
    return Intl.message(
      'Thailand',
      name: 'country_thailand',
      desc: '',
      args: [],
    );
  }

  /// `Vietnam`
  String get country_vietnam {
    return Intl.message('Vietnam', name: 'country_vietnam', desc: '', args: []);
  }

  /// `Cambodia`
  String get country_cambodia {
    return Intl.message(
      'Cambodia',
      name: 'country_cambodia',
      desc: '',
      args: [],
    );
  }

  /// `Laos`
  String get country_laos {
    return Intl.message('Laos', name: 'country_laos', desc: '', args: []);
  }

  /// `Malaysia`
  String get country_malaysia {
    return Intl.message(
      'Malaysia',
      name: 'country_malaysia',
      desc: '',
      args: [],
    );
  }

  /// `Singapore`
  String get country_singapore {
    return Intl.message(
      'Singapore',
      name: 'country_singapore',
      desc: '',
      args: [],
    );
  }

  /// `Indonesia`
  String get country_indonesia {
    return Intl.message(
      'Indonesia',
      name: 'country_indonesia',
      desc: '',
      args: [],
    );
  }

  /// `Philippines`
  String get country_philippines {
    return Intl.message(
      'Philippines',
      name: 'country_philippines',
      desc: '',
      args: [],
    );
  }

  /// `China`
  String get country_china {
    return Intl.message('China', name: 'country_china', desc: '', args: []);
  }

  /// `Japan`
  String get country_japan {
    return Intl.message('Japan', name: 'country_japan', desc: '', args: []);
  }

  /// `South Korea`
  String get country_south_korea {
    return Intl.message(
      'South Korea',
      name: 'country_south_korea',
      desc: '',
      args: [],
    );
  }

  /// `North Korea`
  String get country_north_korea {
    return Intl.message(
      'North Korea',
      name: 'country_north_korea',
      desc: '',
      args: [],
    );
  }

  /// `Mongolia`
  String get country_mongolia {
    return Intl.message(
      'Mongolia',
      name: 'country_mongolia',
      desc: '',
      args: [],
    );
  }

  /// `Taiwan`
  String get country_taiwan {
    return Intl.message('Taiwan', name: 'country_taiwan', desc: '', args: []);
  }

  /// `Hong Kong`
  String get country_hong_kong {
    return Intl.message(
      'Hong Kong',
      name: 'country_hong_kong',
      desc: '',
      args: [],
    );
  }

  /// `Macau`
  String get country_macau {
    return Intl.message('Macau', name: 'country_macau', desc: '', args: []);
  }

  /// `Canada`
  String get country_canada {
    return Intl.message('Canada', name: 'country_canada', desc: '', args: []);
  }

  /// `Mexico`
  String get country_mexico {
    return Intl.message('Mexico', name: 'country_mexico', desc: '', args: []);
  }

  /// `Brazil`
  String get country_brazil {
    return Intl.message('Brazil', name: 'country_brazil', desc: '', args: []);
  }

  /// `Argentina`
  String get country_argentina {
    return Intl.message(
      'Argentina',
      name: 'country_argentina',
      desc: '',
      args: [],
    );
  }

  /// `Chile`
  String get country_chile {
    return Intl.message('Chile', name: 'country_chile', desc: '', args: []);
  }

  /// `Peru`
  String get country_peru {
    return Intl.message('Peru', name: 'country_peru', desc: '', args: []);
  }

  /// `Colombia`
  String get country_colombia {
    return Intl.message(
      'Colombia',
      name: 'country_colombia',
      desc: '',
      args: [],
    );
  }

  /// `Venezuela`
  String get country_venezuela {
    return Intl.message(
      'Venezuela',
      name: 'country_venezuela',
      desc: '',
      args: [],
    );
  }

  /// `Ecuador`
  String get country_ecuador {
    return Intl.message('Ecuador', name: 'country_ecuador', desc: '', args: []);
  }

  /// `Bolivia`
  String get country_bolivia {
    return Intl.message('Bolivia', name: 'country_bolivia', desc: '', args: []);
  }

  /// `Paraguay`
  String get country_paraguay {
    return Intl.message(
      'Paraguay',
      name: 'country_paraguay',
      desc: '',
      args: [],
    );
  }

  /// `Uruguay`
  String get country_uruguay {
    return Intl.message('Uruguay', name: 'country_uruguay', desc: '', args: []);
  }

  /// `Guyana`
  String get country_guyana {
    return Intl.message('Guyana', name: 'country_guyana', desc: '', args: []);
  }

  /// `Suriname`
  String get country_suriname {
    return Intl.message(
      'Suriname',
      name: 'country_suriname',
      desc: '',
      args: [],
    );
  }

  /// `French Guiana`
  String get country_french_guiana {
    return Intl.message(
      'French Guiana',
      name: 'country_french_guiana',
      desc: '',
      args: [],
    );
  }

  /// `Germany`
  String get country_germany {
    return Intl.message('Germany', name: 'country_germany', desc: '', args: []);
  }

  /// `France`
  String get country_france {
    return Intl.message('France', name: 'country_france', desc: '', args: []);
  }

  /// `Italy`
  String get country_italy {
    return Intl.message('Italy', name: 'country_italy', desc: '', args: []);
  }

  /// `Spain`
  String get country_spain {
    return Intl.message('Spain', name: 'country_spain', desc: '', args: []);
  }

  /// `Portugal`
  String get country_portugal {
    return Intl.message(
      'Portugal',
      name: 'country_portugal',
      desc: '',
      args: [],
    );
  }

  /// `Netherlands`
  String get country_netherlands {
    return Intl.message(
      'Netherlands',
      name: 'country_netherlands',
      desc: '',
      args: [],
    );
  }

  /// `Belgium`
  String get country_belgium {
    return Intl.message('Belgium', name: 'country_belgium', desc: '', args: []);
  }

  /// `Switzerland`
  String get country_switzerland {
    return Intl.message(
      'Switzerland',
      name: 'country_switzerland',
      desc: '',
      args: [],
    );
  }

  /// `Austria`
  String get country_austria {
    return Intl.message('Austria', name: 'country_austria', desc: '', args: []);
  }

  /// `Sweden`
  String get country_sweden {
    return Intl.message('Sweden', name: 'country_sweden', desc: '', args: []);
  }

  /// `Norway`
  String get country_norway {
    return Intl.message('Norway', name: 'country_norway', desc: '', args: []);
  }

  /// `Denmark`
  String get country_denmark {
    return Intl.message('Denmark', name: 'country_denmark', desc: '', args: []);
  }

  /// `Finland`
  String get country_finland {
    return Intl.message('Finland', name: 'country_finland', desc: '', args: []);
  }

  /// `Iceland`
  String get country_iceland {
    return Intl.message('Iceland', name: 'country_iceland', desc: '', args: []);
  }

  /// `Poland`
  String get country_poland {
    return Intl.message('Poland', name: 'country_poland', desc: '', args: []);
  }

  /// `Czech Republic`
  String get country_czech_republic {
    return Intl.message(
      'Czech Republic',
      name: 'country_czech_republic',
      desc: '',
      args: [],
    );
  }

  /// `Slovakia`
  String get country_slovakia {
    return Intl.message(
      'Slovakia',
      name: 'country_slovakia',
      desc: '',
      args: [],
    );
  }

  /// `Hungary`
  String get country_hungary {
    return Intl.message('Hungary', name: 'country_hungary', desc: '', args: []);
  }

  /// `Romania`
  String get country_romania {
    return Intl.message('Romania', name: 'country_romania', desc: '', args: []);
  }

  /// `Bulgaria`
  String get country_bulgaria {
    return Intl.message(
      'Bulgaria',
      name: 'country_bulgaria',
      desc: '',
      args: [],
    );
  }

  /// `Croatia`
  String get country_croatia {
    return Intl.message('Croatia', name: 'country_croatia', desc: '', args: []);
  }

  /// `Slovenia`
  String get country_slovenia {
    return Intl.message(
      'Slovenia',
      name: 'country_slovenia',
      desc: '',
      args: [],
    );
  }

  /// `Serbia`
  String get country_serbia {
    return Intl.message('Serbia', name: 'country_serbia', desc: '', args: []);
  }

  /// `Montenegro`
  String get country_montenegro {
    return Intl.message(
      'Montenegro',
      name: 'country_montenegro',
      desc: '',
      args: [],
    );
  }

  /// `Bosnia and Herzegovina`
  String get country_bosnia_and_herzegovina {
    return Intl.message(
      'Bosnia and Herzegovina',
      name: 'country_bosnia_and_herzegovina',
      desc: '',
      args: [],
    );
  }

  /// `North Macedonia`
  String get country_north_macedonia {
    return Intl.message(
      'North Macedonia',
      name: 'country_north_macedonia',
      desc: '',
      args: [],
    );
  }

  /// `Albania`
  String get country_albania {
    return Intl.message('Albania', name: 'country_albania', desc: '', args: []);
  }

  /// `Greece`
  String get country_greece {
    return Intl.message('Greece', name: 'country_greece', desc: '', args: []);
  }

  /// `Cyprus`
  String get country_cyprus {
    return Intl.message('Cyprus', name: 'country_cyprus', desc: '', args: []);
  }

  /// `Malta`
  String get country_malta {
    return Intl.message('Malta', name: 'country_malta', desc: '', args: []);
  }

  /// `Ireland`
  String get country_ireland {
    return Intl.message('Ireland', name: 'country_ireland', desc: '', args: []);
  }

  /// `Luxembourg`
  String get country_luxembourg {
    return Intl.message(
      'Luxembourg',
      name: 'country_luxembourg',
      desc: '',
      args: [],
    );
  }

  /// `Monaco`
  String get country_monaco {
    return Intl.message('Monaco', name: 'country_monaco', desc: '', args: []);
  }

  /// `Liechtenstein`
  String get country_liechtenstein {
    return Intl.message(
      'Liechtenstein',
      name: 'country_liechtenstein',
      desc: '',
      args: [],
    );
  }

  /// `San Marino`
  String get country_san_marino {
    return Intl.message(
      'San Marino',
      name: 'country_san_marino',
      desc: '',
      args: [],
    );
  }

  /// `Vatican City`
  String get country_vatican_city {
    return Intl.message(
      'Vatican City',
      name: 'country_vatican_city',
      desc: '',
      args: [],
    );
  }

  /// `Andorra`
  String get country_andorra {
    return Intl.message('Andorra', name: 'country_andorra', desc: '', args: []);
  }

  /// `Russia`
  String get country_russia {
    return Intl.message('Russia', name: 'country_russia', desc: '', args: []);
  }

  /// `Ukraine`
  String get country_ukraine {
    return Intl.message('Ukraine', name: 'country_ukraine', desc: '', args: []);
  }

  /// `Belarus`
  String get country_belarus {
    return Intl.message('Belarus', name: 'country_belarus', desc: '', args: []);
  }

  /// `Moldova`
  String get country_moldova {
    return Intl.message('Moldova', name: 'country_moldova', desc: '', args: []);
  }

  /// `Estonia`
  String get country_estonia {
    return Intl.message('Estonia', name: 'country_estonia', desc: '', args: []);
  }

  /// `Latvia`
  String get country_latvia {
    return Intl.message('Latvia', name: 'country_latvia', desc: '', args: []);
  }

  /// `Lithuania`
  String get country_lithuania {
    return Intl.message(
      'Lithuania',
      name: 'country_lithuania',
      desc: '',
      args: [],
    );
  }

  /// `Georgia`
  String get country_georgia {
    return Intl.message('Georgia', name: 'country_georgia', desc: '', args: []);
  }

  /// `Armenia`
  String get country_armenia {
    return Intl.message('Armenia', name: 'country_armenia', desc: '', args: []);
  }

  /// `Azerbaijan`
  String get country_azerbaijan {
    return Intl.message(
      'Azerbaijan',
      name: 'country_azerbaijan',
      desc: '',
      args: [],
    );
  }

  /// `Kazakhstan`
  String get country_kazakhstan {
    return Intl.message(
      'Kazakhstan',
      name: 'country_kazakhstan',
      desc: '',
      args: [],
    );
  }

  /// `Uzbekistan`
  String get country_uzbekistan {
    return Intl.message(
      'Uzbekistan',
      name: 'country_uzbekistan',
      desc: '',
      args: [],
    );
  }

  /// `Kyrgyzstan`
  String get country_kyrgyzstan {
    return Intl.message(
      'Kyrgyzstan',
      name: 'country_kyrgyzstan',
      desc: '',
      args: [],
    );
  }

  /// `Tajikistan`
  String get country_tajikistan {
    return Intl.message(
      'Tajikistan',
      name: 'country_tajikistan',
      desc: '',
      args: [],
    );
  }

  /// `Turkmenistan`
  String get country_turkmenistan {
    return Intl.message(
      'Turkmenistan',
      name: 'country_turkmenistan',
      desc: '',
      args: [],
    );
  }

  /// `Australia`
  String get country_australia {
    return Intl.message(
      'Australia',
      name: 'country_australia',
      desc: '',
      args: [],
    );
  }

  /// `New Zealand`
  String get country_new_zealand {
    return Intl.message(
      'New Zealand',
      name: 'country_new_zealand',
      desc: '',
      args: [],
    );
  }

  /// `South Africa`
  String get country_south_africa {
    return Intl.message(
      'South Africa',
      name: 'country_south_africa',
      desc: '',
      args: [],
    );
  }

  /// `Nigeria`
  String get country_nigeria {
    return Intl.message('Nigeria', name: 'country_nigeria', desc: '', args: []);
  }

  /// `Kenya`
  String get country_kenya {
    return Intl.message('Kenya', name: 'country_kenya', desc: '', args: []);
  }

  /// `Ghana`
  String get country_ghana {
    return Intl.message('Ghana', name: 'country_ghana', desc: '', args: []);
  }

  /// `Ethiopia`
  String get country_ethiopia {
    return Intl.message(
      'Ethiopia',
      name: 'country_ethiopia',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get country_unknown {
    return Intl.message('Unknown', name: 'country_unknown', desc: '', args: []);
  }

  /// `Angola`
  String get country_angola {
    return Intl.message('Angola', name: 'country_angola', desc: '', args: []);
  }

  /// `Burkina Faso`
  String get country_burkina_faso {
    return Intl.message(
      'Burkina Faso',
      name: 'country_burkina_faso',
      desc: '',
      args: [],
    );
  }

  /// `Benin`
  String get country_benin {
    return Intl.message('Benin', name: 'country_benin', desc: '', args: []);
  }

  /// `Botswana`
  String get country_botswana {
    return Intl.message(
      'Botswana',
      name: 'country_botswana',
      desc: '',
      args: [],
    );
  }

  /// `Democratic Republic of the Congo`
  String get country_democratic_republic_of_the_congo {
    return Intl.message(
      'Democratic Republic of the Congo',
      name: 'country_democratic_republic_of_the_congo',
      desc: '',
      args: [],
    );
  }

  /// `Central African Republic`
  String get country_central_african_republic {
    return Intl.message(
      'Central African Republic',
      name: 'country_central_african_republic',
      desc: '',
      args: [],
    );
  }

  /// `Congo`
  String get country_congo {
    return Intl.message('Congo', name: 'country_congo', desc: '', args: []);
  }

  /// `Côte d'Ivoire`
  String get country_cote_d_ivoire {
    return Intl.message(
      'Côte d\'Ivoire',
      name: 'country_cote_d_ivoire',
      desc: '',
      args: [],
    );
  }

  /// `Cameroon`
  String get country_cameroon {
    return Intl.message(
      'Cameroon',
      name: 'country_cameroon',
      desc: '',
      args: [],
    );
  }

  /// `Cape Verde`
  String get country_cape_verde {
    return Intl.message(
      'Cape Verde',
      name: 'country_cape_verde',
      desc: '',
      args: [],
    );
  }

  /// `Djibouti`
  String get country_djibouti {
    return Intl.message(
      'Djibouti',
      name: 'country_djibouti',
      desc: '',
      args: [],
    );
  }

  /// `Western Sahara`
  String get country_western_sahara {
    return Intl.message(
      'Western Sahara',
      name: 'country_western_sahara',
      desc: '',
      args: [],
    );
  }

  /// `Eritrea`
  String get country_eritrea {
    return Intl.message('Eritrea', name: 'country_eritrea', desc: '', args: []);
  }

  /// `Fiji`
  String get country_fiji {
    return Intl.message('Fiji', name: 'country_fiji', desc: '', args: []);
  }

  /// `Micronesia`
  String get country_micronesia {
    return Intl.message(
      'Micronesia',
      name: 'country_micronesia',
      desc: '',
      args: [],
    );
  }

  /// `Gabon`
  String get country_gabon {
    return Intl.message('Gabon', name: 'country_gabon', desc: '', args: []);
  }

  /// `Gambia`
  String get country_gambia {
    return Intl.message('Gambia', name: 'country_gambia', desc: '', args: []);
  }

  /// `Guinea`
  String get country_guinea {
    return Intl.message('Guinea', name: 'country_guinea', desc: '', args: []);
  }

  /// `Equatorial Guinea`
  String get country_equatorial_guinea {
    return Intl.message(
      'Equatorial Guinea',
      name: 'country_equatorial_guinea',
      desc: '',
      args: [],
    );
  }

  /// `Guinea-Bissau`
  String get country_guinea_bissau {
    return Intl.message(
      'Guinea-Bissau',
      name: 'country_guinea_bissau',
      desc: '',
      args: [],
    );
  }

  /// `Kiribati`
  String get country_kiribati {
    return Intl.message(
      'Kiribati',
      name: 'country_kiribati',
      desc: '',
      args: [],
    );
  }

  /// `Comoros`
  String get country_comoros {
    return Intl.message('Comoros', name: 'country_comoros', desc: '', args: []);
  }

  /// `Liberia`
  String get country_liberia {
    return Intl.message('Liberia', name: 'country_liberia', desc: '', args: []);
  }

  /// `Lesotho`
  String get country_lesotho {
    return Intl.message('Lesotho', name: 'country_lesotho', desc: '', args: []);
  }

  /// `Madagascar`
  String get country_madagascar {
    return Intl.message(
      'Madagascar',
      name: 'country_madagascar',
      desc: '',
      args: [],
    );
  }

  /// `Marshall Islands`
  String get country_marshall_islands {
    return Intl.message(
      'Marshall Islands',
      name: 'country_marshall_islands',
      desc: '',
      args: [],
    );
  }

  /// `Mali`
  String get country_mali {
    return Intl.message('Mali', name: 'country_mali', desc: '', args: []);
  }

  /// `Mauritania`
  String get country_mauritania {
    return Intl.message(
      'Mauritania',
      name: 'country_mauritania',
      desc: '',
      args: [],
    );
  }

  /// `Mauritius`
  String get country_mauritius {
    return Intl.message(
      'Mauritius',
      name: 'country_mauritius',
      desc: '',
      args: [],
    );
  }

  /// `Malawi`
  String get country_malawi {
    return Intl.message('Malawi', name: 'country_malawi', desc: '', args: []);
  }

  /// `Mozambique`
  String get country_mozambique {
    return Intl.message(
      'Mozambique',
      name: 'country_mozambique',
      desc: '',
      args: [],
    );
  }

  /// `Namibia`
  String get country_namibia {
    return Intl.message('Namibia', name: 'country_namibia', desc: '', args: []);
  }

  /// `New Caledonia`
  String get country_new_caledonia {
    return Intl.message(
      'New Caledonia',
      name: 'country_new_caledonia',
      desc: '',
      args: [],
    );
  }

  /// `Niger`
  String get country_niger {
    return Intl.message('Niger', name: 'country_niger', desc: '', args: []);
  }

  /// `Nauru`
  String get country_nauru {
    return Intl.message('Nauru', name: 'country_nauru', desc: '', args: []);
  }

  /// `French Polynesia`
  String get country_french_polynesia {
    return Intl.message(
      'French Polynesia',
      name: 'country_french_polynesia',
      desc: '',
      args: [],
    );
  }

  /// `Papua New Guinea`
  String get country_papua_new_guinea {
    return Intl.message(
      'Papua New Guinea',
      name: 'country_papua_new_guinea',
      desc: '',
      args: [],
    );
  }

  /// `Palau`
  String get country_palau {
    return Intl.message('Palau', name: 'country_palau', desc: '', args: []);
  }

  /// `Solomon Islands`
  String get country_solomon_islands {
    return Intl.message(
      'Solomon Islands',
      name: 'country_solomon_islands',
      desc: '',
      args: [],
    );
  }

  /// `Seychelles`
  String get country_seychelles {
    return Intl.message(
      'Seychelles',
      name: 'country_seychelles',
      desc: '',
      args: [],
    );
  }

  /// `Sierra Leone`
  String get country_sierra_leone {
    return Intl.message(
      'Sierra Leone',
      name: 'country_sierra_leone',
      desc: '',
      args: [],
    );
  }

  /// `Senegal`
  String get country_senegal {
    return Intl.message('Senegal', name: 'country_senegal', desc: '', args: []);
  }

  /// `Somalia`
  String get country_somalia {
    return Intl.message('Somalia', name: 'country_somalia', desc: '', args: []);
  }

  /// `São Tomé and Príncipe`
  String get country_sao_tome_and_principe {
    return Intl.message(
      'São Tomé and Príncipe',
      name: 'country_sao_tome_and_principe',
      desc: '',
      args: [],
    );
  }

  /// `Eswatini`
  String get country_eswatini {
    return Intl.message(
      'Eswatini',
      name: 'country_eswatini',
      desc: '',
      args: [],
    );
  }

  /// `Chad`
  String get country_chad {
    return Intl.message('Chad', name: 'country_chad', desc: '', args: []);
  }

  /// `Togo`
  String get country_togo {
    return Intl.message('Togo', name: 'country_togo', desc: '', args: []);
  }

  /// `Tonga`
  String get country_tonga {
    return Intl.message('Tonga', name: 'country_tonga', desc: '', args: []);
  }

  /// `Tuvalu`
  String get country_tuvalu {
    return Intl.message('Tuvalu', name: 'country_tuvalu', desc: '', args: []);
  }

  /// `Tanzania`
  String get country_tanzania {
    return Intl.message(
      'Tanzania',
      name: 'country_tanzania',
      desc: '',
      args: [],
    );
  }

  /// `Uganda`
  String get country_uganda {
    return Intl.message('Uganda', name: 'country_uganda', desc: '', args: []);
  }

  /// `Vanuatu`
  String get country_vanuatu {
    return Intl.message('Vanuatu', name: 'country_vanuatu', desc: '', args: []);
  }

  /// `Samoa`
  String get country_samoa {
    return Intl.message('Samoa', name: 'country_samoa', desc: '', args: []);
  }

  /// `Zambia`
  String get country_zambia {
    return Intl.message('Zambia', name: 'country_zambia', desc: '', args: []);
  }

  /// `Zimbabwe`
  String get country_zimbabwe {
    return Intl.message(
      'Zimbabwe',
      name: 'country_zimbabwe',
      desc: '',
      args: [],
    );
  }

  /// `Jordanian`
  String get nationality_jordan {
    return Intl.message(
      'Jordanian',
      name: 'nationality_jordan',
      desc: '',
      args: [],
    );
  }

  /// `American`
  String get nationality_united_states {
    return Intl.message(
      'American',
      name: 'nationality_united_states',
      desc: '',
      args: [],
    );
  }

  /// `British`
  String get nationality_united_kingdom {
    return Intl.message(
      'British',
      name: 'nationality_united_kingdom',
      desc: '',
      args: [],
    );
  }

  /// `Saudi`
  String get nationality_saudi_arabia {
    return Intl.message(
      'Saudi',
      name: 'nationality_saudi_arabia',
      desc: '',
      args: [],
    );
  }

  /// `Emirati`
  String get nationality_united_arab_emirates {
    return Intl.message(
      'Emirati',
      name: 'nationality_united_arab_emirates',
      desc: '',
      args: [],
    );
  }

  /// `Kuwaiti`
  String get nationality_kuwait {
    return Intl.message(
      'Kuwaiti',
      name: 'nationality_kuwait',
      desc: '',
      args: [],
    );
  }

  /// `Qatari`
  String get nationality_qatar {
    return Intl.message(
      'Qatari',
      name: 'nationality_qatar',
      desc: '',
      args: [],
    );
  }

  /// `Bahraini`
  String get nationality_bahrain {
    return Intl.message(
      'Bahraini',
      name: 'nationality_bahrain',
      desc: '',
      args: [],
    );
  }

  /// `Omani`
  String get nationality_oman {
    return Intl.message('Omani', name: 'nationality_oman', desc: '', args: []);
  }

  /// `Egyptian`
  String get nationality_egypt {
    return Intl.message(
      'Egyptian',
      name: 'nationality_egypt',
      desc: '',
      args: [],
    );
  }

  /// `Lebanese`
  String get nationality_lebanon {
    return Intl.message(
      'Lebanese',
      name: 'nationality_lebanon',
      desc: '',
      args: [],
    );
  }

  /// `Syrian`
  String get nationality_syria {
    return Intl.message(
      'Syrian',
      name: 'nationality_syria',
      desc: '',
      args: [],
    );
  }

  /// `Iraqi`
  String get nationality_iraq {
    return Intl.message('Iraqi', name: 'nationality_iraq', desc: '', args: []);
  }

  /// `Palestinian`
  String get nationality_palestine {
    return Intl.message(
      'Palestinian',
      name: 'nationality_palestine',
      desc: '',
      args: [],
    );
  }

  /// `Yemeni`
  String get nationality_yemen {
    return Intl.message(
      'Yemeni',
      name: 'nationality_yemen',
      desc: '',
      args: [],
    );
  }

  /// `Libyan`
  String get nationality_libya {
    return Intl.message(
      'Libyan',
      name: 'nationality_libya',
      desc: '',
      args: [],
    );
  }

  /// `Tunisian`
  String get nationality_tunisia {
    return Intl.message(
      'Tunisian',
      name: 'nationality_tunisia',
      desc: '',
      args: [],
    );
  }

  /// `Algerian`
  String get nationality_algeria {
    return Intl.message(
      'Algerian',
      name: 'nationality_algeria',
      desc: '',
      args: [],
    );
  }

  /// `Moroccan`
  String get nationality_morocco {
    return Intl.message(
      'Moroccan',
      name: 'nationality_morocco',
      desc: '',
      args: [],
    );
  }

  /// `Sudanese`
  String get nationality_sudan {
    return Intl.message(
      'Sudanese',
      name: 'nationality_sudan',
      desc: '',
      args: [],
    );
  }

  /// `Turkish`
  String get nationality_turkey {
    return Intl.message(
      'Turkish',
      name: 'nationality_turkey',
      desc: '',
      args: [],
    );
  }

  /// `Iranian`
  String get nationality_iran {
    return Intl.message(
      'Iranian',
      name: 'nationality_iran',
      desc: '',
      args: [],
    );
  }

  /// `Pakistani`
  String get nationality_pakistan {
    return Intl.message(
      'Pakistani',
      name: 'nationality_pakistan',
      desc: '',
      args: [],
    );
  }

  /// `Afghan`
  String get nationality_afghanistan {
    return Intl.message(
      'Afghan',
      name: 'nationality_afghanistan',
      desc: '',
      args: [],
    );
  }

  /// `Indian`
  String get nationality_india {
    return Intl.message(
      'Indian',
      name: 'nationality_india',
      desc: '',
      args: [],
    );
  }

  /// `Bangladeshi`
  String get nationality_bangladesh {
    return Intl.message(
      'Bangladeshi',
      name: 'nationality_bangladesh',
      desc: '',
      args: [],
    );
  }

  /// `Sri Lankan`
  String get nationality_sri_lanka {
    return Intl.message(
      'Sri Lankan',
      name: 'nationality_sri_lanka',
      desc: '',
      args: [],
    );
  }

  /// `Nepali`
  String get nationality_nepal {
    return Intl.message(
      'Nepali',
      name: 'nationality_nepal',
      desc: '',
      args: [],
    );
  }

  /// `Burmese`
  String get nationality_myanmar {
    return Intl.message(
      'Burmese',
      name: 'nationality_myanmar',
      desc: '',
      args: [],
    );
  }

  /// `Thai`
  String get nationality_thailand {
    return Intl.message(
      'Thai',
      name: 'nationality_thailand',
      desc: '',
      args: [],
    );
  }

  /// `Vietnamese`
  String get nationality_vietnam {
    return Intl.message(
      'Vietnamese',
      name: 'nationality_vietnam',
      desc: '',
      args: [],
    );
  }

  /// `Cambodian`
  String get nationality_cambodia {
    return Intl.message(
      'Cambodian',
      name: 'nationality_cambodia',
      desc: '',
      args: [],
    );
  }

  /// `Lao`
  String get nationality_laos {
    return Intl.message('Lao', name: 'nationality_laos', desc: '', args: []);
  }

  /// `Malaysian`
  String get nationality_malaysia {
    return Intl.message(
      'Malaysian',
      name: 'nationality_malaysia',
      desc: '',
      args: [],
    );
  }

  /// `Singaporean`
  String get nationality_singapore {
    return Intl.message(
      'Singaporean',
      name: 'nationality_singapore',
      desc: '',
      args: [],
    );
  }

  /// `Indonesian`
  String get nationality_indonesia {
    return Intl.message(
      'Indonesian',
      name: 'nationality_indonesia',
      desc: '',
      args: [],
    );
  }

  /// `Filipino`
  String get nationality_philippines {
    return Intl.message(
      'Filipino',
      name: 'nationality_philippines',
      desc: '',
      args: [],
    );
  }

  /// `Chinese`
  String get nationality_china {
    return Intl.message(
      'Chinese',
      name: 'nationality_china',
      desc: '',
      args: [],
    );
  }

  /// `Japanese`
  String get nationality_japan {
    return Intl.message(
      'Japanese',
      name: 'nationality_japan',
      desc: '',
      args: [],
    );
  }

  /// `South Korean`
  String get nationality_south_korea {
    return Intl.message(
      'South Korean',
      name: 'nationality_south_korea',
      desc: '',
      args: [],
    );
  }

  /// `North Korean`
  String get nationality_north_korea {
    return Intl.message(
      'North Korean',
      name: 'nationality_north_korea',
      desc: '',
      args: [],
    );
  }

  /// `Mongolian`
  String get nationality_mongolia {
    return Intl.message(
      'Mongolian',
      name: 'nationality_mongolia',
      desc: '',
      args: [],
    );
  }

  /// `Taiwanese`
  String get nationality_taiwan {
    return Intl.message(
      'Taiwanese',
      name: 'nationality_taiwan',
      desc: '',
      args: [],
    );
  }

  /// `Hong Konger`
  String get nationality_hong_kong {
    return Intl.message(
      'Hong Konger',
      name: 'nationality_hong_kong',
      desc: '',
      args: [],
    );
  }

  /// `Macanese`
  String get nationality_macau {
    return Intl.message(
      'Macanese',
      name: 'nationality_macau',
      desc: '',
      args: [],
    );
  }

  /// `Canadian`
  String get nationality_canada {
    return Intl.message(
      'Canadian',
      name: 'nationality_canada',
      desc: '',
      args: [],
    );
  }

  /// `Mexican`
  String get nationality_mexico {
    return Intl.message(
      'Mexican',
      name: 'nationality_mexico',
      desc: '',
      args: [],
    );
  }

  /// `Brazilian`
  String get nationality_brazil {
    return Intl.message(
      'Brazilian',
      name: 'nationality_brazil',
      desc: '',
      args: [],
    );
  }

  /// `Argentine`
  String get nationality_argentina {
    return Intl.message(
      'Argentine',
      name: 'nationality_argentina',
      desc: '',
      args: [],
    );
  }

  /// `Chilean`
  String get nationality_chile {
    return Intl.message(
      'Chilean',
      name: 'nationality_chile',
      desc: '',
      args: [],
    );
  }

  /// `Peruvian`
  String get nationality_peru {
    return Intl.message(
      'Peruvian',
      name: 'nationality_peru',
      desc: '',
      args: [],
    );
  }

  /// `Colombian`
  String get nationality_colombia {
    return Intl.message(
      'Colombian',
      name: 'nationality_colombia',
      desc: '',
      args: [],
    );
  }

  /// `Venezuelan`
  String get nationality_venezuela {
    return Intl.message(
      'Venezuelan',
      name: 'nationality_venezuela',
      desc: '',
      args: [],
    );
  }

  /// `Ecuadorian`
  String get nationality_ecuador {
    return Intl.message(
      'Ecuadorian',
      name: 'nationality_ecuador',
      desc: '',
      args: [],
    );
  }

  /// `Bolivian`
  String get nationality_bolivia {
    return Intl.message(
      'Bolivian',
      name: 'nationality_bolivia',
      desc: '',
      args: [],
    );
  }

  /// `Paraguayan`
  String get nationality_paraguay {
    return Intl.message(
      'Paraguayan',
      name: 'nationality_paraguay',
      desc: '',
      args: [],
    );
  }

  /// `Uruguayan`
  String get nationality_uruguay {
    return Intl.message(
      'Uruguayan',
      name: 'nationality_uruguay',
      desc: '',
      args: [],
    );
  }

  /// `Guyanese`
  String get nationality_guyana {
    return Intl.message(
      'Guyanese',
      name: 'nationality_guyana',
      desc: '',
      args: [],
    );
  }

  /// `Surinamese`
  String get nationality_suriname {
    return Intl.message(
      'Surinamese',
      name: 'nationality_suriname',
      desc: '',
      args: [],
    );
  }

  /// `French Guianese`
  String get nationality_french_guiana {
    return Intl.message(
      'French Guianese',
      name: 'nationality_french_guiana',
      desc: '',
      args: [],
    );
  }

  /// `German`
  String get nationality_germany {
    return Intl.message(
      'German',
      name: 'nationality_germany',
      desc: '',
      args: [],
    );
  }

  /// `French`
  String get nationality_france {
    return Intl.message(
      'French',
      name: 'nationality_france',
      desc: '',
      args: [],
    );
  }

  /// `Italian`
  String get nationality_italy {
    return Intl.message(
      'Italian',
      name: 'nationality_italy',
      desc: '',
      args: [],
    );
  }

  /// `Spanish`
  String get nationality_spain {
    return Intl.message(
      'Spanish',
      name: 'nationality_spain',
      desc: '',
      args: [],
    );
  }

  /// `Portuguese`
  String get nationality_portugal {
    return Intl.message(
      'Portuguese',
      name: 'nationality_portugal',
      desc: '',
      args: [],
    );
  }

  /// `Dutch`
  String get nationality_netherlands {
    return Intl.message(
      'Dutch',
      name: 'nationality_netherlands',
      desc: '',
      args: [],
    );
  }

  /// `Belgian`
  String get nationality_belgium {
    return Intl.message(
      'Belgian',
      name: 'nationality_belgium',
      desc: '',
      args: [],
    );
  }

  /// `Swiss`
  String get nationality_switzerland {
    return Intl.message(
      'Swiss',
      name: 'nationality_switzerland',
      desc: '',
      args: [],
    );
  }

  /// `Austrian`
  String get nationality_austria {
    return Intl.message(
      'Austrian',
      name: 'nationality_austria',
      desc: '',
      args: [],
    );
  }

  /// `Swedish`
  String get nationality_sweden {
    return Intl.message(
      'Swedish',
      name: 'nationality_sweden',
      desc: '',
      args: [],
    );
  }

  /// `Norwegian`
  String get nationality_norway {
    return Intl.message(
      'Norwegian',
      name: 'nationality_norway',
      desc: '',
      args: [],
    );
  }

  /// `Danish`
  String get nationality_denmark {
    return Intl.message(
      'Danish',
      name: 'nationality_denmark',
      desc: '',
      args: [],
    );
  }

  /// `Finnish`
  String get nationality_finland {
    return Intl.message(
      'Finnish',
      name: 'nationality_finland',
      desc: '',
      args: [],
    );
  }

  /// `Icelandic`
  String get nationality_iceland {
    return Intl.message(
      'Icelandic',
      name: 'nationality_iceland',
      desc: '',
      args: [],
    );
  }

  /// `Polish`
  String get nationality_poland {
    return Intl.message(
      'Polish',
      name: 'nationality_poland',
      desc: '',
      args: [],
    );
  }

  /// `Czech`
  String get nationality_czech_republic {
    return Intl.message(
      'Czech',
      name: 'nationality_czech_republic',
      desc: '',
      args: [],
    );
  }

  /// `Slovak`
  String get nationality_slovakia {
    return Intl.message(
      'Slovak',
      name: 'nationality_slovakia',
      desc: '',
      args: [],
    );
  }

  /// `Hungarian`
  String get nationality_hungary {
    return Intl.message(
      'Hungarian',
      name: 'nationality_hungary',
      desc: '',
      args: [],
    );
  }

  /// `Romanian`
  String get nationality_romania {
    return Intl.message(
      'Romanian',
      name: 'nationality_romania',
      desc: '',
      args: [],
    );
  }

  /// `Bulgarian`
  String get nationality_bulgaria {
    return Intl.message(
      'Bulgarian',
      name: 'nationality_bulgaria',
      desc: '',
      args: [],
    );
  }

  /// `Croatian`
  String get nationality_croatia {
    return Intl.message(
      'Croatian',
      name: 'nationality_croatia',
      desc: '',
      args: [],
    );
  }

  /// `Slovenian`
  String get nationality_slovenia {
    return Intl.message(
      'Slovenian',
      name: 'nationality_slovenia',
      desc: '',
      args: [],
    );
  }

  /// `Serbian`
  String get nationality_serbia {
    return Intl.message(
      'Serbian',
      name: 'nationality_serbia',
      desc: '',
      args: [],
    );
  }

  /// `Montenegrin`
  String get nationality_montenegro {
    return Intl.message(
      'Montenegrin',
      name: 'nationality_montenegro',
      desc: '',
      args: [],
    );
  }

  /// `Bosnian`
  String get nationality_bosnia_and_herzegovina {
    return Intl.message(
      'Bosnian',
      name: 'nationality_bosnia_and_herzegovina',
      desc: '',
      args: [],
    );
  }

  /// `Macedonian`
  String get nationality_north_macedonia {
    return Intl.message(
      'Macedonian',
      name: 'nationality_north_macedonia',
      desc: '',
      args: [],
    );
  }

  /// `Albanian`
  String get nationality_albania {
    return Intl.message(
      'Albanian',
      name: 'nationality_albania',
      desc: '',
      args: [],
    );
  }

  /// `Greek`
  String get nationality_greece {
    return Intl.message(
      'Greek',
      name: 'nationality_greece',
      desc: '',
      args: [],
    );
  }

  /// `Cypriot`
  String get nationality_cyprus {
    return Intl.message(
      'Cypriot',
      name: 'nationality_cyprus',
      desc: '',
      args: [],
    );
  }

  /// `Maltese`
  String get nationality_malta {
    return Intl.message(
      'Maltese',
      name: 'nationality_malta',
      desc: '',
      args: [],
    );
  }

  /// `Irish`
  String get nationality_ireland {
    return Intl.message(
      'Irish',
      name: 'nationality_ireland',
      desc: '',
      args: [],
    );
  }

  /// `Luxembourgish`
  String get nationality_luxembourg {
    return Intl.message(
      'Luxembourgish',
      name: 'nationality_luxembourg',
      desc: '',
      args: [],
    );
  }

  /// `Monégasque`
  String get nationality_monaco {
    return Intl.message(
      'Monégasque',
      name: 'nationality_monaco',
      desc: '',
      args: [],
    );
  }

  /// `Liechtensteiner`
  String get nationality_liechtenstein {
    return Intl.message(
      'Liechtensteiner',
      name: 'nationality_liechtenstein',
      desc: '',
      args: [],
    );
  }

  /// `Sammarinese`
  String get nationality_san_marino {
    return Intl.message(
      'Sammarinese',
      name: 'nationality_san_marino',
      desc: '',
      args: [],
    );
  }

  /// `Vatican`
  String get nationality_vatican_city {
    return Intl.message(
      'Vatican',
      name: 'nationality_vatican_city',
      desc: '',
      args: [],
    );
  }

  /// `Andorran`
  String get nationality_andorra {
    return Intl.message(
      'Andorran',
      name: 'nationality_andorra',
      desc: '',
      args: [],
    );
  }

  /// `Russian`
  String get nationality_russia {
    return Intl.message(
      'Russian',
      name: 'nationality_russia',
      desc: '',
      args: [],
    );
  }

  /// `Ukrainian`
  String get nationality_ukraine {
    return Intl.message(
      'Ukrainian',
      name: 'nationality_ukraine',
      desc: '',
      args: [],
    );
  }

  /// `Belarusian`
  String get nationality_belarus {
    return Intl.message(
      'Belarusian',
      name: 'nationality_belarus',
      desc: '',
      args: [],
    );
  }

  /// `Moldovan`
  String get nationality_moldova {
    return Intl.message(
      'Moldovan',
      name: 'nationality_moldova',
      desc: '',
      args: [],
    );
  }

  /// `Estonian`
  String get nationality_estonia {
    return Intl.message(
      'Estonian',
      name: 'nationality_estonia',
      desc: '',
      args: [],
    );
  }

  /// `Latvian`
  String get nationality_latvia {
    return Intl.message(
      'Latvian',
      name: 'nationality_latvia',
      desc: '',
      args: [],
    );
  }

  /// `Lithuanian`
  String get nationality_lithuania {
    return Intl.message(
      'Lithuanian',
      name: 'nationality_lithuania',
      desc: '',
      args: [],
    );
  }

  /// `Georgian`
  String get nationality_georgia {
    return Intl.message(
      'Georgian',
      name: 'nationality_georgia',
      desc: '',
      args: [],
    );
  }

  /// `Armenian`
  String get nationality_armenia {
    return Intl.message(
      'Armenian',
      name: 'nationality_armenia',
      desc: '',
      args: [],
    );
  }

  /// `Azerbaijani`
  String get nationality_azerbaijan {
    return Intl.message(
      'Azerbaijani',
      name: 'nationality_azerbaijan',
      desc: '',
      args: [],
    );
  }

  /// `Kazakh`
  String get nationality_kazakhstan {
    return Intl.message(
      'Kazakh',
      name: 'nationality_kazakhstan',
      desc: '',
      args: [],
    );
  }

  /// `Uzbek`
  String get nationality_uzbekistan {
    return Intl.message(
      'Uzbek',
      name: 'nationality_uzbekistan',
      desc: '',
      args: [],
    );
  }

  /// `Kyrgyz`
  String get nationality_kyrgyzstan {
    return Intl.message(
      'Kyrgyz',
      name: 'nationality_kyrgyzstan',
      desc: '',
      args: [],
    );
  }

  /// `Tajik`
  String get nationality_tajikistan {
    return Intl.message(
      'Tajik',
      name: 'nationality_tajikistan',
      desc: '',
      args: [],
    );
  }

  /// `Turkmen`
  String get nationality_turkmenistan {
    return Intl.message(
      'Turkmen',
      name: 'nationality_turkmenistan',
      desc: '',
      args: [],
    );
  }

  /// `Australian`
  String get nationality_australia {
    return Intl.message(
      'Australian',
      name: 'nationality_australia',
      desc: '',
      args: [],
    );
  }

  /// `New Zealander`
  String get nationality_new_zealand {
    return Intl.message(
      'New Zealander',
      name: 'nationality_new_zealand',
      desc: '',
      args: [],
    );
  }

  /// `South African`
  String get nationality_south_africa {
    return Intl.message(
      'South African',
      name: 'nationality_south_africa',
      desc: '',
      args: [],
    );
  }

  /// `Nigerian`
  String get nationality_nigeria {
    return Intl.message(
      'Nigerian',
      name: 'nationality_nigeria',
      desc: '',
      args: [],
    );
  }

  /// `Kenyan`
  String get nationality_kenya {
    return Intl.message(
      'Kenyan',
      name: 'nationality_kenya',
      desc: '',
      args: [],
    );
  }

  /// `Ghanaian`
  String get nationality_ghana {
    return Intl.message(
      'Ghanaian',
      name: 'nationality_ghana',
      desc: '',
      args: [],
    );
  }

  /// `Ethiopian`
  String get nationality_ethiopia {
    return Intl.message(
      'Ethiopian',
      name: 'nationality_ethiopia',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get nationality_unknown {
    return Intl.message(
      'Unknown',
      name: 'nationality_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Angolan`
  String get nationality_angola {
    return Intl.message(
      'Angolan',
      name: 'nationality_angola',
      desc: '',
      args: [],
    );
  }

  /// `Burkinabé`
  String get nationality_burkina_faso {
    return Intl.message(
      'Burkinabé',
      name: 'nationality_burkina_faso',
      desc: '',
      args: [],
    );
  }

  /// `Beninese`
  String get nationality_benin {
    return Intl.message(
      'Beninese',
      name: 'nationality_benin',
      desc: '',
      args: [],
    );
  }

  /// `Botswanan`
  String get nationality_botswana {
    return Intl.message(
      'Botswanan',
      name: 'nationality_botswana',
      desc: '',
      args: [],
    );
  }

  /// `Congolese`
  String get nationality_democratic_republic_of_the_congo {
    return Intl.message(
      'Congolese',
      name: 'nationality_democratic_republic_of_the_congo',
      desc: '',
      args: [],
    );
  }

  /// `Central African`
  String get nationality_central_african_republic {
    return Intl.message(
      'Central African',
      name: 'nationality_central_african_republic',
      desc: '',
      args: [],
    );
  }

  /// `Congolese`
  String get nationality_congo {
    return Intl.message(
      'Congolese',
      name: 'nationality_congo',
      desc: '',
      args: [],
    );
  }

  /// `Ivorian`
  String get nationality_cote_d_ivoire {
    return Intl.message(
      'Ivorian',
      name: 'nationality_cote_d_ivoire',
      desc: '',
      args: [],
    );
  }

  /// `Cameroonian`
  String get nationality_cameroon {
    return Intl.message(
      'Cameroonian',
      name: 'nationality_cameroon',
      desc: '',
      args: [],
    );
  }

  /// `Cape Verdean`
  String get nationality_cape_verde {
    return Intl.message(
      'Cape Verdean',
      name: 'nationality_cape_verde',
      desc: '',
      args: [],
    );
  }

  /// `Djiboutian`
  String get nationality_djibouti {
    return Intl.message(
      'Djiboutian',
      name: 'nationality_djibouti',
      desc: '',
      args: [],
    );
  }

  /// `Sahrawi`
  String get nationality_western_sahara {
    return Intl.message(
      'Sahrawi',
      name: 'nationality_western_sahara',
      desc: '',
      args: [],
    );
  }

  /// `Eritrean`
  String get nationality_eritrea {
    return Intl.message(
      'Eritrean',
      name: 'nationality_eritrea',
      desc: '',
      args: [],
    );
  }

  /// `Fijian`
  String get nationality_fiji {
    return Intl.message('Fijian', name: 'nationality_fiji', desc: '', args: []);
  }

  /// `Micronesian`
  String get nationality_micronesia {
    return Intl.message(
      'Micronesian',
      name: 'nationality_micronesia',
      desc: '',
      args: [],
    );
  }

  /// `Gabonese`
  String get nationality_gabon {
    return Intl.message(
      'Gabonese',
      name: 'nationality_gabon',
      desc: '',
      args: [],
    );
  }

  /// `Gambian`
  String get nationality_gambia {
    return Intl.message(
      'Gambian',
      name: 'nationality_gambia',
      desc: '',
      args: [],
    );
  }

  /// `Guinean`
  String get nationality_guinea {
    return Intl.message(
      'Guinean',
      name: 'nationality_guinea',
      desc: '',
      args: [],
    );
  }

  /// `Equatorial Guinean`
  String get nationality_equatorial_guinea {
    return Intl.message(
      'Equatorial Guinean',
      name: 'nationality_equatorial_guinea',
      desc: '',
      args: [],
    );
  }

  /// `Bissau-Guinean`
  String get nationality_guinea_bissau {
    return Intl.message(
      'Bissau-Guinean',
      name: 'nationality_guinea_bissau',
      desc: '',
      args: [],
    );
  }

  /// `I-Kiribati`
  String get nationality_kiribati {
    return Intl.message(
      'I-Kiribati',
      name: 'nationality_kiribati',
      desc: '',
      args: [],
    );
  }

  /// `Comorian`
  String get nationality_comoros {
    return Intl.message(
      'Comorian',
      name: 'nationality_comoros',
      desc: '',
      args: [],
    );
  }

  /// `Liberian`
  String get nationality_liberia {
    return Intl.message(
      'Liberian',
      name: 'nationality_liberia',
      desc: '',
      args: [],
    );
  }

  /// `Basotho`
  String get nationality_lesotho {
    return Intl.message(
      'Basotho',
      name: 'nationality_lesotho',
      desc: '',
      args: [],
    );
  }

  /// `Malagasy`
  String get nationality_madagascar {
    return Intl.message(
      'Malagasy',
      name: 'nationality_madagascar',
      desc: '',
      args: [],
    );
  }

  /// `Marshallese`
  String get nationality_marshall_islands {
    return Intl.message(
      'Marshallese',
      name: 'nationality_marshall_islands',
      desc: '',
      args: [],
    );
  }

  /// `Malian`
  String get nationality_mali {
    return Intl.message('Malian', name: 'nationality_mali', desc: '', args: []);
  }

  /// `Mauritanian`
  String get nationality_mauritania {
    return Intl.message(
      'Mauritanian',
      name: 'nationality_mauritania',
      desc: '',
      args: [],
    );
  }

  /// `Mauritian`
  String get nationality_mauritius {
    return Intl.message(
      'Mauritian',
      name: 'nationality_mauritius',
      desc: '',
      args: [],
    );
  }

  /// `Malawian`
  String get nationality_malawi {
    return Intl.message(
      'Malawian',
      name: 'nationality_malawi',
      desc: '',
      args: [],
    );
  }

  /// `Mozambican`
  String get nationality_mozambique {
    return Intl.message(
      'Mozambican',
      name: 'nationality_mozambique',
      desc: '',
      args: [],
    );
  }

  /// `Namibian`
  String get nationality_namibia {
    return Intl.message(
      'Namibian',
      name: 'nationality_namibia',
      desc: '',
      args: [],
    );
  }

  /// `New Caledonian`
  String get nationality_new_caledonia {
    return Intl.message(
      'New Caledonian',
      name: 'nationality_new_caledonia',
      desc: '',
      args: [],
    );
  }

  /// `Nigerien`
  String get nationality_niger {
    return Intl.message(
      'Nigerien',
      name: 'nationality_niger',
      desc: '',
      args: [],
    );
  }

  /// `Nauruan`
  String get nationality_nauru {
    return Intl.message(
      'Nauruan',
      name: 'nationality_nauru',
      desc: '',
      args: [],
    );
  }

  /// `French Polynesian`
  String get nationality_french_polynesia {
    return Intl.message(
      'French Polynesian',
      name: 'nationality_french_polynesia',
      desc: '',
      args: [],
    );
  }

  /// `Papua New Guinean`
  String get nationality_papua_new_guinea {
    return Intl.message(
      'Papua New Guinean',
      name: 'nationality_papua_new_guinea',
      desc: '',
      args: [],
    );
  }

  /// `Palauan`
  String get nationality_palau {
    return Intl.message(
      'Palauan',
      name: 'nationality_palau',
      desc: '',
      args: [],
    );
  }

  /// `Solomon Islander`
  String get nationality_solomon_islands {
    return Intl.message(
      'Solomon Islander',
      name: 'nationality_solomon_islands',
      desc: '',
      args: [],
    );
  }

  /// `Seychellois`
  String get nationality_seychelles {
    return Intl.message(
      'Seychellois',
      name: 'nationality_seychelles',
      desc: '',
      args: [],
    );
  }

  /// `Sierra Leonean`
  String get nationality_sierra_leone {
    return Intl.message(
      'Sierra Leonean',
      name: 'nationality_sierra_leone',
      desc: '',
      args: [],
    );
  }

  /// `Senegalese`
  String get nationality_senegal {
    return Intl.message(
      'Senegalese',
      name: 'nationality_senegal',
      desc: '',
      args: [],
    );
  }

  /// `Somali`
  String get nationality_somalia {
    return Intl.message(
      'Somali',
      name: 'nationality_somalia',
      desc: '',
      args: [],
    );
  }

  /// `São Toméan`
  String get nationality_sao_tome_and_principe {
    return Intl.message(
      'São Toméan',
      name: 'nationality_sao_tome_and_principe',
      desc: '',
      args: [],
    );
  }

  /// `Swazi`
  String get nationality_eswatini {
    return Intl.message(
      'Swazi',
      name: 'nationality_eswatini',
      desc: '',
      args: [],
    );
  }

  /// `Chadian`
  String get nationality_chad {
    return Intl.message(
      'Chadian',
      name: 'nationality_chad',
      desc: '',
      args: [],
    );
  }

  /// `Togolese`
  String get nationality_togo {
    return Intl.message(
      'Togolese',
      name: 'nationality_togo',
      desc: '',
      args: [],
    );
  }

  /// `Tongan`
  String get nationality_tonga {
    return Intl.message(
      'Tongan',
      name: 'nationality_tonga',
      desc: '',
      args: [],
    );
  }

  /// `Tuvaluan`
  String get nationality_tuvalu {
    return Intl.message(
      'Tuvaluan',
      name: 'nationality_tuvalu',
      desc: '',
      args: [],
    );
  }

  /// `Tanzanian`
  String get nationality_tanzania {
    return Intl.message(
      'Tanzanian',
      name: 'nationality_tanzania',
      desc: '',
      args: [],
    );
  }

  /// `Ugandan`
  String get nationality_uganda {
    return Intl.message(
      'Ugandan',
      name: 'nationality_uganda',
      desc: '',
      args: [],
    );
  }

  /// `Ni-Vanuatu`
  String get nationality_vanuatu {
    return Intl.message(
      'Ni-Vanuatu',
      name: 'nationality_vanuatu',
      desc: '',
      args: [],
    );
  }

  /// `Samoan`
  String get nationality_samoa {
    return Intl.message(
      'Samoan',
      name: 'nationality_samoa',
      desc: '',
      args: [],
    );
  }

  /// `Zambian`
  String get nationality_zambia {
    return Intl.message(
      'Zambian',
      name: 'nationality_zambia',
      desc: '',
      args: [],
    );
  }

  /// `Zimbabwean`
  String get nationality_zimbabwe {
    return Intl.message(
      'Zimbabwean',
      name: 'nationality_zimbabwe',
      desc: '',
      args: [],
    );
  }

  /// `Pago Pago`
  String get timezone_pacific_pago_pago {
    return Intl.message(
      'Pago Pago',
      name: 'timezone_pacific_pago_pago',
      desc: '',
      args: [],
    );
  }

  /// `Honolulu`
  String get timezone_pacific_honolulu {
    return Intl.message(
      'Honolulu',
      name: 'timezone_pacific_honolulu',
      desc: '',
      args: [],
    );
  }

  /// `Marquesas`
  String get timezone_pacific_marquesas {
    return Intl.message(
      'Marquesas',
      name: 'timezone_pacific_marquesas',
      desc: '',
      args: [],
    );
  }

  /// `Anchorage`
  String get timezone_america_anchorage {
    return Intl.message(
      'Anchorage',
      name: 'timezone_america_anchorage',
      desc: '',
      args: [],
    );
  }

  /// `Los Angeles`
  String get timezone_america_los_angeles {
    return Intl.message(
      'Los Angeles',
      name: 'timezone_america_los_angeles',
      desc: '',
      args: [],
    );
  }

  /// `Denver`
  String get timezone_america_denver {
    return Intl.message(
      'Denver',
      name: 'timezone_america_denver',
      desc: '',
      args: [],
    );
  }

  /// `Chicago`
  String get timezone_america_chicago {
    return Intl.message(
      'Chicago',
      name: 'timezone_america_chicago',
      desc: '',
      args: [],
    );
  }

  /// `Mexico City`
  String get timezone_america_mexico_city {
    return Intl.message(
      'Mexico City',
      name: 'timezone_america_mexico_city',
      desc: '',
      args: [],
    );
  }

  /// `Bogota`
  String get timezone_america_bogota {
    return Intl.message(
      'Bogota',
      name: 'timezone_america_bogota',
      desc: '',
      args: [],
    );
  }

  /// `Lima`
  String get timezone_america_lima {
    return Intl.message(
      'Lima',
      name: 'timezone_america_lima',
      desc: '',
      args: [],
    );
  }

  /// `New York`
  String get timezone_america_new_york {
    return Intl.message(
      'New York',
      name: 'timezone_america_new_york',
      desc: '',
      args: [],
    );
  }

  /// `Toronto`
  String get timezone_america_toronto {
    return Intl.message(
      'Toronto',
      name: 'timezone_america_toronto',
      desc: '',
      args: [],
    );
  }

  /// `Caracas`
  String get timezone_america_caracas {
    return Intl.message(
      'Caracas',
      name: 'timezone_america_caracas',
      desc: '',
      args: [],
    );
  }

  /// `Santiago`
  String get timezone_america_santiago {
    return Intl.message(
      'Santiago',
      name: 'timezone_america_santiago',
      desc: '',
      args: [],
    );
  }

  /// `St. John's`
  String get timezone_america_st_johns {
    return Intl.message(
      'St. John\'s',
      name: 'timezone_america_st_johns',
      desc: '',
      args: [],
    );
  }

  /// `Buenos Aires`
  String get timezone_america_argentina_buenos_aires {
    return Intl.message(
      'Buenos Aires',
      name: 'timezone_america_argentina_buenos_aires',
      desc: '',
      args: [],
    );
  }

  /// `Sao Paulo`
  String get timezone_america_sao_paulo {
    return Intl.message(
      'Sao Paulo',
      name: 'timezone_america_sao_paulo',
      desc: '',
      args: [],
    );
  }

  /// `Fernando de Noronha`
  String get timezone_america_noronha {
    return Intl.message(
      'Fernando de Noronha',
      name: 'timezone_america_noronha',
      desc: '',
      args: [],
    );
  }

  /// `Praia`
  String get timezone_atlantic_cape_verde {
    return Intl.message(
      'Praia',
      name: 'timezone_atlantic_cape_verde',
      desc: '',
      args: [],
    );
  }

  /// `Accra`
  String get timezone_africa_accra {
    return Intl.message(
      'Accra',
      name: 'timezone_africa_accra',
      desc: '',
      args: [],
    );
  }

  /// `Dublin`
  String get timezone_europe_dublin {
    return Intl.message(
      'Dublin',
      name: 'timezone_europe_dublin',
      desc: '',
      args: [],
    );
  }

  /// `Lisbon`
  String get timezone_europe_lisbon {
    return Intl.message(
      'Lisbon',
      name: 'timezone_europe_lisbon',
      desc: '',
      args: [],
    );
  }

  /// `London`
  String get timezone_europe_london {
    return Intl.message(
      'London',
      name: 'timezone_europe_london',
      desc: '',
      args: [],
    );
  }

  /// `Nouakchott`
  String get timezone_africa_nouakchott {
    return Intl.message(
      'Nouakchott',
      name: 'timezone_africa_nouakchott',
      desc: '',
      args: [],
    );
  }

  /// `Reykjavik`
  String get timezone_atlantic_reykjavik {
    return Intl.message(
      'Reykjavik',
      name: 'timezone_atlantic_reykjavik',
      desc: '',
      args: [],
    );
  }

  /// `Algiers`
  String get timezone_africa_algiers {
    return Intl.message(
      'Algiers',
      name: 'timezone_africa_algiers',
      desc: '',
      args: [],
    );
  }

  /// `Amsterdam`
  String get timezone_europe_amsterdam {
    return Intl.message(
      'Amsterdam',
      name: 'timezone_europe_amsterdam',
      desc: '',
      args: [],
    );
  }

  /// `Berlin`
  String get timezone_europe_berlin {
    return Intl.message(
      'Berlin',
      name: 'timezone_europe_berlin',
      desc: '',
      args: [],
    );
  }

  /// `Casablanca`
  String get timezone_africa_casablanca {
    return Intl.message(
      'Casablanca',
      name: 'timezone_africa_casablanca',
      desc: '',
      args: [],
    );
  }

  /// `Kinshasa`
  String get timezone_africa_kinshasa {
    return Intl.message(
      'Kinshasa',
      name: 'timezone_africa_kinshasa',
      desc: '',
      args: [],
    );
  }

  /// `Lagos`
  String get timezone_africa_lagos {
    return Intl.message(
      'Lagos',
      name: 'timezone_africa_lagos',
      desc: '',
      args: [],
    );
  }

  /// `Madrid`
  String get timezone_europe_madrid {
    return Intl.message(
      'Madrid',
      name: 'timezone_europe_madrid',
      desc: '',
      args: [],
    );
  }

  /// `Paris`
  String get timezone_europe_paris {
    return Intl.message(
      'Paris',
      name: 'timezone_europe_paris',
      desc: '',
      args: [],
    );
  }

  /// `Rome`
  String get timezone_europe_rome {
    return Intl.message(
      'Rome',
      name: 'timezone_europe_rome',
      desc: '',
      args: [],
    );
  }

  /// `Stockholm`
  String get timezone_europe_stockholm {
    return Intl.message(
      'Stockholm',
      name: 'timezone_europe_stockholm',
      desc: '',
      args: [],
    );
  }

  /// `Tunis`
  String get timezone_africa_tunis {
    return Intl.message(
      'Tunis',
      name: 'timezone_africa_tunis',
      desc: '',
      args: [],
    );
  }

  /// `Zurich`
  String get timezone_europe_zurich {
    return Intl.message(
      'Zurich',
      name: 'timezone_europe_zurich',
      desc: '',
      args: [],
    );
  }

  /// `Athens`
  String get timezone_europe_athens {
    return Intl.message(
      'Athens',
      name: 'timezone_europe_athens',
      desc: '',
      args: [],
    );
  }

  /// `Beirut`
  String get timezone_asia_beirut {
    return Intl.message(
      'Beirut',
      name: 'timezone_asia_beirut',
      desc: '',
      args: [],
    );
  }

  /// `Cairo`
  String get timezone_africa_cairo {
    return Intl.message(
      'Cairo',
      name: 'timezone_africa_cairo',
      desc: '',
      args: [],
    );
  }

  /// `Jerusalem`
  String get timezone_asia_jerusalem {
    return Intl.message(
      'Jerusalem',
      name: 'timezone_asia_jerusalem',
      desc: '',
      args: [],
    );
  }

  /// `Johannesburg`
  String get timezone_africa_johannesburg {
    return Intl.message(
      'Johannesburg',
      name: 'timezone_africa_johannesburg',
      desc: '',
      args: [],
    );
  }

  /// `Khartoum`
  String get timezone_africa_khartoum {
    return Intl.message(
      'Khartoum',
      name: 'timezone_africa_khartoum',
      desc: '',
      args: [],
    );
  }

  /// `Kyiv`
  String get timezone_europe_kyiv {
    return Intl.message(
      'Kyiv',
      name: 'timezone_europe_kyiv',
      desc: '',
      args: [],
    );
  }

  /// `Tripoli`
  String get timezone_africa_tripoli {
    return Intl.message(
      'Tripoli',
      name: 'timezone_africa_tripoli',
      desc: '',
      args: [],
    );
  }

  /// `Addis Ababa`
  String get timezone_africa_addis_ababa {
    return Intl.message(
      'Addis Ababa',
      name: 'timezone_africa_addis_ababa',
      desc: '',
      args: [],
    );
  }

  /// `Amman`
  String get timezone_asia_amman {
    return Intl.message(
      'Amman',
      name: 'timezone_asia_amman',
      desc: '',
      args: [],
    );
  }

  /// `Baghdad`
  String get timezone_asia_baghdad {
    return Intl.message(
      'Baghdad',
      name: 'timezone_asia_baghdad',
      desc: '',
      args: [],
    );
  }

  /// `Damascus`
  String get timezone_asia_damascus {
    return Intl.message(
      'Damascus',
      name: 'timezone_asia_damascus',
      desc: '',
      args: [],
    );
  }

  /// `Doha`
  String get timezone_asia_qatar {
    return Intl.message(
      'Doha',
      name: 'timezone_asia_qatar',
      desc: '',
      args: [],
    );
  }

  /// `Istanbul`
  String get timezone_europe_istanbul {
    return Intl.message(
      'Istanbul',
      name: 'timezone_europe_istanbul',
      desc: '',
      args: [],
    );
  }

  /// `Kuwait City`
  String get timezone_asia_kuwait {
    return Intl.message(
      'Kuwait City',
      name: 'timezone_asia_kuwait',
      desc: '',
      args: [],
    );
  }

  /// `Manama`
  String get timezone_asia_bahrain {
    return Intl.message(
      'Manama',
      name: 'timezone_asia_bahrain',
      desc: '',
      args: [],
    );
  }

  /// `Mogadishu`
  String get timezone_africa_mogadishu {
    return Intl.message(
      'Mogadishu',
      name: 'timezone_africa_mogadishu',
      desc: '',
      args: [],
    );
  }

  /// `Moscow`
  String get timezone_europe_moscow {
    return Intl.message(
      'Moscow',
      name: 'timezone_europe_moscow',
      desc: '',
      args: [],
    );
  }

  /// `Nairobi`
  String get timezone_africa_nairobi {
    return Intl.message(
      'Nairobi',
      name: 'timezone_africa_nairobi',
      desc: '',
      args: [],
    );
  }

  /// `Riyadh`
  String get timezone_asia_riyadh {
    return Intl.message(
      'Riyadh',
      name: 'timezone_asia_riyadh',
      desc: '',
      args: [],
    );
  }

  /// `Sanaa`
  String get timezone_asia_aden {
    return Intl.message(
      'Sanaa',
      name: 'timezone_asia_aden',
      desc: '',
      args: [],
    );
  }

  /// `Tehran`
  String get timezone_asia_tehran {
    return Intl.message(
      'Tehran',
      name: 'timezone_asia_tehran',
      desc: '',
      args: [],
    );
  }

  /// `Dubai`
  String get timezone_asia_dubai {
    return Intl.message(
      'Dubai',
      name: 'timezone_asia_dubai',
      desc: '',
      args: [],
    );
  }

  /// `Muscat`
  String get timezone_asia_muscat {
    return Intl.message(
      'Muscat',
      name: 'timezone_asia_muscat',
      desc: '',
      args: [],
    );
  }

  /// `Kabul`
  String get timezone_asia_kabul {
    return Intl.message(
      'Kabul',
      name: 'timezone_asia_kabul',
      desc: '',
      args: [],
    );
  }

  /// `Almaty`
  String get timezone_asia_almaty {
    return Intl.message(
      'Almaty',
      name: 'timezone_asia_almaty',
      desc: '',
      args: [],
    );
  }

  /// `Karachi`
  String get timezone_asia_karachi {
    return Intl.message(
      'Karachi',
      name: 'timezone_asia_karachi',
      desc: '',
      args: [],
    );
  }

  /// `Tashkent`
  String get timezone_asia_tashkent {
    return Intl.message(
      'Tashkent',
      name: 'timezone_asia_tashkent',
      desc: '',
      args: [],
    );
  }

  /// `Colombo`
  String get timezone_asia_colombo {
    return Intl.message(
      'Colombo',
      name: 'timezone_asia_colombo',
      desc: '',
      args: [],
    );
  }

  /// `Delhi`
  String get timezone_asia_kolkata {
    return Intl.message(
      'Delhi',
      name: 'timezone_asia_kolkata',
      desc: '',
      args: [],
    );
  }

  /// `Kathmandu`
  String get timezone_asia_kathmandu {
    return Intl.message(
      'Kathmandu',
      name: 'timezone_asia_kathmandu',
      desc: '',
      args: [],
    );
  }

  /// `Dhaka`
  String get timezone_asia_dhaka {
    return Intl.message(
      'Dhaka',
      name: 'timezone_asia_dhaka',
      desc: '',
      args: [],
    );
  }

  /// `Yangon`
  String get timezone_asia_yangon {
    return Intl.message(
      'Yangon',
      name: 'timezone_asia_yangon',
      desc: '',
      args: [],
    );
  }

  /// `Bangkok`
  String get timezone_asia_bangkok {
    return Intl.message(
      'Bangkok',
      name: 'timezone_asia_bangkok',
      desc: '',
      args: [],
    );
  }

  /// `Ho Chi Minh`
  String get timezone_asia_ho_chi_minh {
    return Intl.message(
      'Ho Chi Minh',
      name: 'timezone_asia_ho_chi_minh',
      desc: '',
      args: [],
    );
  }

  /// `Jakarta`
  String get timezone_asia_jakarta {
    return Intl.message(
      'Jakarta',
      name: 'timezone_asia_jakarta',
      desc: '',
      args: [],
    );
  }

  /// `Hong Kong`
  String get timezone_asia_hong_kong {
    return Intl.message(
      'Hong Kong',
      name: 'timezone_asia_hong_kong',
      desc: '',
      args: [],
    );
  }

  /// `Kuala Lumpur`
  String get timezone_asia_kuala_lumpur {
    return Intl.message(
      'Kuala Lumpur',
      name: 'timezone_asia_kuala_lumpur',
      desc: '',
      args: [],
    );
  }

  /// `Manila`
  String get timezone_asia_manila {
    return Intl.message(
      'Manila',
      name: 'timezone_asia_manila',
      desc: '',
      args: [],
    );
  }

  /// `Perth`
  String get timezone_australia_perth {
    return Intl.message(
      'Perth',
      name: 'timezone_australia_perth',
      desc: '',
      args: [],
    );
  }

  /// `Shanghai`
  String get timezone_asia_shanghai {
    return Intl.message(
      'Shanghai',
      name: 'timezone_asia_shanghai',
      desc: '',
      args: [],
    );
  }

  /// `Singapore`
  String get timezone_asia_singapore {
    return Intl.message(
      'Singapore',
      name: 'timezone_asia_singapore',
      desc: '',
      args: [],
    );
  }

  /// `Taipei`
  String get timezone_asia_taipei {
    return Intl.message(
      'Taipei',
      name: 'timezone_asia_taipei',
      desc: '',
      args: [],
    );
  }

  /// `Seoul`
  String get timezone_asia_seoul {
    return Intl.message(
      'Seoul',
      name: 'timezone_asia_seoul',
      desc: '',
      args: [],
    );
  }

  /// `Tokyo`
  String get timezone_asia_tokyo {
    return Intl.message(
      'Tokyo',
      name: 'timezone_asia_tokyo',
      desc: '',
      args: [],
    );
  }

  /// `Adelaide`
  String get timezone_australia_adelaide {
    return Intl.message(
      'Adelaide',
      name: 'timezone_australia_adelaide',
      desc: '',
      args: [],
    );
  }

  /// `Darwin`
  String get timezone_australia_darwin {
    return Intl.message(
      'Darwin',
      name: 'timezone_australia_darwin',
      desc: '',
      args: [],
    );
  }

  /// `Brisbane`
  String get timezone_australia_brisbane {
    return Intl.message(
      'Brisbane',
      name: 'timezone_australia_brisbane',
      desc: '',
      args: [],
    );
  }

  /// `Guam`
  String get timezone_pacific_guam {
    return Intl.message(
      'Guam',
      name: 'timezone_pacific_guam',
      desc: '',
      args: [],
    );
  }

  /// `Melbourne`
  String get timezone_australia_melbourne {
    return Intl.message(
      'Melbourne',
      name: 'timezone_australia_melbourne',
      desc: '',
      args: [],
    );
  }

  /// `Port Moresby`
  String get timezone_pacific_port_moresby {
    return Intl.message(
      'Port Moresby',
      name: 'timezone_pacific_port_moresby',
      desc: '',
      args: [],
    );
  }

  /// `Sydney`
  String get timezone_australia_sydney {
    return Intl.message(
      'Sydney',
      name: 'timezone_australia_sydney',
      desc: '',
      args: [],
    );
  }

  /// `Lord Howe`
  String get timezone_australia_lord_howe {
    return Intl.message(
      'Lord Howe',
      name: 'timezone_australia_lord_howe',
      desc: '',
      args: [],
    );
  }

  /// `Honiara`
  String get timezone_pacific_guadalcanal {
    return Intl.message(
      'Honiara',
      name: 'timezone_pacific_guadalcanal',
      desc: '',
      args: [],
    );
  }

  /// `Auckland`
  String get timezone_pacific_auckland {
    return Intl.message(
      'Auckland',
      name: 'timezone_pacific_auckland',
      desc: '',
      args: [],
    );
  }

  /// `Suva`
  String get timezone_pacific_fiji {
    return Intl.message(
      'Suva',
      name: 'timezone_pacific_fiji',
      desc: '',
      args: [],
    );
  }

  /// `Chatham`
  String get timezone_pacific_chatham {
    return Intl.message(
      'Chatham',
      name: 'timezone_pacific_chatham',
      desc: '',
      args: [],
    );
  }

  /// `Apia`
  String get timezone_pacific_apia {
    return Intl.message(
      'Apia',
      name: 'timezone_pacific_apia',
      desc: '',
      args: [],
    );
  }

  /// `Nuku'alofa`
  String get timezone_pacific_tongatapu {
    return Intl.message(
      'Nuku\'alofa',
      name: 'timezone_pacific_tongatapu',
      desc: '',
      args: [],
    );
  }

  /// `Kiritimati`
  String get timezone_pacific_kiritimati {
    return Intl.message(
      'Kiritimati',
      name: 'timezone_pacific_kiritimati',
      desc: '',
      args: [],
    );
  }

  /// `At least {length} characters`
  String text_field_req_min_length(int length) {
    return Intl.message(
      'At least $length characters',
      name: 'text_field_req_min_length',
      desc: '',
      args: [length],
    );
  }

  /// `Contains an uppercase letter`
  String get text_field_req_uppercase {
    return Intl.message(
      'Contains an uppercase letter',
      name: 'text_field_req_uppercase',
      desc: '',
      args: [],
    );
  }

  /// `Contains a lowercase letter`
  String get text_field_req_lowercase {
    return Intl.message(
      'Contains a lowercase letter',
      name: 'text_field_req_lowercase',
      desc: '',
      args: [],
    );
  }

  /// `Contains a number`
  String get text_field_req_digit {
    return Intl.message(
      'Contains a number',
      name: 'text_field_req_digit',
      desc: '',
      args: [],
    );
  }

  /// `Contains a special character`
  String get text_field_req_special_char {
    return Intl.message(
      'Contains a special character',
      name: 'text_field_req_special_char',
      desc: '',
      args: [],
    );
  }

  /// `No spaces`
  String get text_field_req_no_spaces {
    return Intl.message(
      'No spaces',
      name: 'text_field_req_no_spaces',
      desc: '',
      args: [],
    );
  }

  /// `Reveal password?`
  String get text_field_reveal_password_title {
    return Intl.message(
      'Reveal password?',
      name: 'text_field_reveal_password_title',
      desc: '',
      args: [],
    );
  }

  /// `Your screen is being recorded or shared — anyone watching will see what you typed.`
  String get text_field_reveal_password_message {
    return Intl.message(
      'Your screen is being recorded or shared — anyone watching will see what you typed.',
      name: 'text_field_reveal_password_message',
      desc: '',
      args: [],
    );
  }

  /// `Reveal`
  String get text_field_reveal {
    return Intl.message(
      'Reveal',
      name: 'text_field_reveal',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get text_field_cancel {
    return Intl.message(
      'Cancel',
      name: 'text_field_cancel',
      desc: '',
      args: [],
    );
  }

  /// `word`
  String get text_field_word {
    return Intl.message('word', name: 'text_field_word', desc: '', args: []);
  }

  /// `words`
  String get text_field_words {
    return Intl.message('words', name: 'text_field_words', desc: '', args: []);
  }

  /// `chars`
  String get text_field_chars {
    return Intl.message('chars', name: 'text_field_chars', desc: '', args: []);
  }

  /// `Caps Lock is on`
  String get text_field_caps_lock_on {
    return Intl.message(
      'Caps Lock is on',
      name: 'text_field_caps_lock_on',
      desc: '',
      args: [],
    );
  }

  /// `Weak`
  String get text_field_strength_weak {
    return Intl.message(
      'Weak',
      name: 'text_field_strength_weak',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get text_field_strength_medium {
    return Intl.message(
      'Medium',
      name: 'text_field_strength_medium',
      desc: '',
      args: [],
    );
  }

  /// `Strong`
  String get text_field_strength_strong {
    return Intl.message(
      'Strong',
      name: 'text_field_strength_strong',
      desc: '',
      args: [],
    );
  }

  /// `Clear All`
  String get text_field_clear_all {
    return Intl.message(
      'Clear All',
      name: 'text_field_clear_all',
      desc: '',
      args: [],
    );
  }

  /// `Generate password`
  String get text_field_generate_password {
    return Intl.message(
      'Generate password',
      name: 'text_field_generate_password',
      desc: '',
      args: [],
    );
  }

  /// `Undo`
  String get text_field_undo {
    return Intl.message('Undo', name: 'text_field_undo', desc: '', args: []);
  }

  /// `Redo`
  String get text_field_redo {
    return Intl.message('Redo', name: 'text_field_redo', desc: '', args: []);
  }

  /// `Clear`
  String get text_field_clear {
    return Intl.message('Clear', name: 'text_field_clear', desc: '', args: []);
  }

  /// `Voice input`
  String get text_field_voice_input {
    return Intl.message(
      'Voice input',
      name: 'text_field_voice_input',
      desc: '',
      args: [],
    );
  }

  /// `Hold to reveal password`
  String get text_field_hold_to_reveal {
    return Intl.message(
      'Hold to reveal password',
      name: 'text_field_hold_to_reveal',
      desc: '',
      args: [],
    );
  }

  /// `Show or hide password`
  String get text_field_toggle_visibility {
    return Intl.message(
      'Show or hide password',
      name: 'text_field_toggle_visibility',
      desc: '',
      args: [],
    );
  }

  /// `May contain inappropriate language`
  String get text_field_profanity_warning {
    return Intl.message(
      'May contain inappropriate language',
      name: 'text_field_profanity_warning',
      desc: '',
      args: [],
    );
  }

  /// `{count} of {total} name parts`
  String text_field_name_parts_progress(int count, int total) {
    return Intl.message(
      '$count of $total name parts',
      name: 'text_field_name_parts_progress',
      desc: '',
      args: [count, total],
    );
  }

  /// `Enter your password`
  String get text_field_password_hint {
    return Intl.message(
      'Enter your password',
      name: 'text_field_password_hint',
      desc: '',
      args: [],
    );
  }

  /// `Create a password`
  String get text_field_password_create_hint {
    return Intl.message(
      'Create a password',
      name: 'text_field_password_create_hint',
      desc: '',
      args: [],
    );
  }

  /// `Confirm your password`
  String get text_field_password_confirm_hint {
    return Intl.message(
      'Confirm your password',
      name: 'text_field_password_confirm_hint',
      desc: '',
      args: [],
    );
  }

  /// `Screen is being recorded or shared — input stays hidden`
  String get text_field_screen_capture_warning {
    return Intl.message(
      'Screen is being recorded or shared — input stays hidden',
      name: 'text_field_screen_capture_warning',
      desc: '',
      args: [],
    );
  }

  /// `Only {domains} addresses are accepted`
  String text_field_email_domain_not_allowed(String domains) {
    return Intl.message(
      'Only $domains addresses are accepted',
      name: 'text_field_email_domain_not_allowed',
      desc: '',
      args: [domains],
    );
  }

  /// `This email domain can't receive mail`
  String get text_field_email_domain_unreachable {
    return Intl.message(
      'This email domain can\'t receive mail',
      name: 'text_field_email_domain_unreachable',
      desc: '',
      args: [],
    );
  }

  /// `This password appeared in {count} data breaches — pick another`
  String text_field_password_breached(int count) {
    return Intl.message(
      'This password appeared in $count data breaches — pick another',
      name: 'text_field_password_breached',
      desc: '',
      args: [count],
    );
  }

  /// `Preferred`
  String get phone_field_preferred_countries {
    return Intl.message(
      'Preferred',
      name: 'phone_field_preferred_countries',
      desc: '',
      args: [],
    );
  }

  /// `All countries`
  String get phone_field_all_countries {
    return Intl.message(
      'All countries',
      name: 'phone_field_all_countries',
      desc: '',
      args: [],
    );
  }

  /// `Phone number must be {count} digits`
  String phone_field_length_exact(int count) {
    return Intl.message(
      'Phone number must be $count digits',
      name: 'phone_field_length_exact',
      desc: '',
      args: [count],
    );
  }

  /// `Phone number must be {min}–{max} digits`
  String phone_field_length_range(int min, int max) {
    return Intl.message(
      'Phone number must be $min–$max digits',
      name: 'phone_field_length_range',
      desc: '',
      args: [min, max],
    );
  }

  /// `Mobile number must be {count} digits`
  String phone_field_mobile_length_exact(int count) {
    return Intl.message(
      'Mobile number must be $count digits',
      name: 'phone_field_mobile_length_exact',
      desc: '',
      args: [count],
    );
  }

  /// `Mobile number must be {min}–{max} digits`
  String phone_field_mobile_length_range(int min, int max) {
    return Intl.message(
      'Mobile number must be $min–$max digits',
      name: 'phone_field_mobile_length_range',
      desc: '',
      args: [min, max],
    );
  }

  /// `Mobile numbers start with {prefixes}`
  String phone_field_mobile_prefix(String prefixes) {
    return Intl.message(
      'Mobile numbers start with $prefixes',
      name: 'phone_field_mobile_prefix',
      desc: '',
      args: [prefixes],
    );
  }

  /// `Preferred`
  String get amount_field_preferred_currencies {
    return Intl.message(
      'Preferred',
      name: 'amount_field_preferred_currencies',
      desc: '',
      args: [],
    );
  }

  /// `All currencies`
  String get amount_field_all_currencies {
    return Intl.message(
      'All currencies',
      name: 'amount_field_all_currencies',
      desc: '',
      args: [],
    );
  }

  /// `Common`
  String get measurement_field_preferred_units {
    return Intl.message(
      'Common',
      name: 'measurement_field_preferred_units',
      desc: '',
      args: [],
    );
  }

  /// `All units`
  String get measurement_field_all_units {
    return Intl.message(
      'All units',
      name: 'measurement_field_all_units',
      desc: '',
      args: [],
    );
  }

  /// `Incomplete date — use {format}`
  String date_field_incomplete(String format) {
    return Intl.message(
      'Incomplete date — use $format',
      name: 'date_field_incomplete',
      desc: '',
      args: [format],
    );
  }

  /// `That date doesn't exist`
  String get date_field_impossible {
    return Intl.message(
      'That date doesn\'t exist',
      name: 'date_field_impossible',
      desc: '',
      args: [],
    );
  }

  /// `Date must be on or after {date}`
  String date_field_min_date(String date) {
    return Intl.message(
      'Date must be on or after $date',
      name: 'date_field_min_date',
      desc: '',
      args: [date],
    );
  }

  /// `Date must be on or before {date}`
  String date_field_max_date(String date) {
    return Intl.message(
      'Date must be on or before $date',
      name: 'date_field_max_date',
      desc: '',
      args: [date],
    );
  }

  /// `Pick a date at least {days} days from now`
  String date_field_min_days_ahead(int days) {
    return Intl.message(
      'Pick a date at least $days days from now',
      name: 'date_field_min_days_ahead',
      desc: '',
      args: [days],
    );
  }

  /// `Pick a date within the next {days} days`
  String date_field_max_days_ahead(int days) {
    return Intl.message(
      'Pick a date within the next $days days',
      name: 'date_field_max_days_ahead',
      desc: '',
      args: [days],
    );
  }

  /// `That day of the week isn't available`
  String get date_field_weekday_not_allowed {
    return Intl.message(
      'That day of the week isn\'t available',
      name: 'date_field_weekday_not_allowed',
      desc: '',
      args: [],
    );
  }

  /// `That date isn't available`
  String get date_field_date_unavailable {
    return Intl.message(
      'That date isn\'t available',
      name: 'date_field_date_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Must be after {date}`
  String date_field_must_be_after(String date) {
    return Intl.message(
      'Must be after $date',
      name: 'date_field_must_be_after',
      desc: '',
      args: [date],
    );
  }

  /// `Must be before {date}`
  String date_field_must_be_before(String date) {
    return Intl.message(
      'Must be before $date',
      name: 'date_field_must_be_before',
      desc: '',
      args: [date],
    );
  }

  /// `Must be valid for at least {months} more months`
  String date_field_expiry_min_months(int months) {
    return Intl.message(
      'Must be valid for at least $months more months',
      name: 'date_field_expiry_min_months',
      desc: '',
      args: [months],
    );
  }

  /// `{months, plural, one{1 month old} other{{months} months old}}`
  String date_field_age_months(int months) {
    return Intl.plural(
      months,
      one: '1 month old',
      other: '$months months old',
      name: 'date_field_age_months',
      desc: '',
      args: [months],
    );
  }

  /// `{days, plural, one{1 day old} other{{days} days old}}`
  String date_field_age_days(int days) {
    return Intl.plural(
      days,
      one: '1 day old',
      other: '$days days old',
      name: 'date_field_age_days',
      desc: '',
      args: [days],
    );
  }

  /// `{years} years old`
  String date_field_age_years(int years) {
    return Intl.message(
      '$years years old',
      name: 'date_field_age_years',
      desc: '',
      args: [years],
    );
  }

  /// `{date} AH`
  String date_field_hijri(String date) {
    return Intl.message(
      '$date AH',
      name: 'date_field_hijri',
      desc: '',
      args: [date],
    );
  }

  /// `Pick a date`
  String get date_field_pick_date {
    return Intl.message(
      'Pick a date',
      name: 'date_field_pick_date',
      desc: '',
      args: [],
    );
  }

  /// `DD`
  String get date_field_day_word {
    return Intl.message('DD', name: 'date_field_day_word', desc: '', args: []);
  }

  /// `MM`
  String get date_field_month_word {
    return Intl.message(
      'MM',
      name: 'date_field_month_word',
      desc: '',
      args: [],
    );
  }

  /// `YYYY`
  String get date_field_year_word {
    return Intl.message(
      'YYYY',
      name: 'date_field_year_word',
      desc: '',
      args: [],
    );
  }

  /// `YY`
  String get date_field_year2_word {
    return Intl.message(
      'YY',
      name: 'date_field_year2_word',
      desc: '',
      args: [],
    );
  }

  /// `Start date`
  String get date_range_start {
    return Intl.message(
      'Start date',
      name: 'date_range_start',
      desc: '',
      args: [],
    );
  }

  /// `End date`
  String get date_range_end {
    return Intl.message('End date', name: 'date_range_end', desc: '', args: []);
  }

  /// `{nights} nights`
  String date_range_nights(int nights) {
    return Intl.message(
      '$nights nights',
      name: 'date_range_nights',
      desc: '',
      args: [nights],
    );
  }

  /// `HH`
  String get time_field_hour_word {
    return Intl.message('HH', name: 'time_field_hour_word', desc: '', args: []);
  }

  /// `mm`
  String get time_field_minute_word {
    return Intl.message(
      'mm',
      name: 'time_field_minute_word',
      desc: '',
      args: [],
    );
  }

  /// `Time cannot be empty`
  String get time_field_required {
    return Intl.message(
      'Time cannot be empty',
      name: 'time_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Incomplete time — use {format}`
  String time_field_incomplete(String format) {
    return Intl.message(
      'Incomplete time — use $format',
      name: 'time_field_incomplete',
      desc: '',
      args: [format],
    );
  }

  /// `Time must be at or after {time}`
  String time_field_min_time(String time) {
    return Intl.message(
      'Time must be at or after $time',
      name: 'time_field_min_time',
      desc: '',
      args: [time],
    );
  }

  /// `Time must be at or before {time}`
  String time_field_max_time(String time) {
    return Intl.message(
      'Time must be at or before $time',
      name: 'time_field_max_time',
      desc: '',
      args: [time],
    );
  }

  /// `Time must be between {start} and {end}`
  String time_field_outside_window(String start, String end) {
    return Intl.message(
      'Time must be between $start and $end',
      name: 'time_field_outside_window',
      desc: '',
      args: [start, end],
    );
  }

  /// `Time must be on {minutes}-minute steps`
  String time_field_interval(int minutes) {
    return Intl.message(
      'Time must be on $minutes-minute steps',
      name: 'time_field_interval',
      desc: '',
      args: [minutes],
    );
  }

  /// `Pick a time`
  String get time_field_pick_time {
    return Intl.message(
      'Pick a time',
      name: 'time_field_pick_time',
      desc: '',
      args: [],
    );
  }

  /// `24h`
  String get time_field_format_24 {
    return Intl.message(
      '24h',
      name: 'time_field_format_24',
      desc: '',
      args: [],
    );
  }

  /// `12h`
  String get time_field_format_12 {
    return Intl.message(
      '12h',
      name: 'time_field_format_12',
      desc: '',
      args: [],
    );
  }

  /// `ss`
  String get time_field_second_word {
    return Intl.message(
      'ss',
      name: 'time_field_second_word',
      desc: '',
      args: [],
    );
  }

  /// `Now`
  String get time_field_now {
    return Intl.message('Now', name: 'time_field_now', desc: '', args: []);
  }

  /// `Must be after {time}`
  String time_field_must_be_after(String time) {
    return Intl.message(
      'Must be after $time',
      name: 'time_field_must_be_after',
      desc: '',
      args: [time],
    );
  }

  /// `Start time`
  String get time_range_start {
    return Intl.message(
      'Start time',
      name: 'time_range_start',
      desc: '',
      args: [],
    );
  }

  /// `End time`
  String get time_range_end {
    return Intl.message('End time', name: 'time_range_end', desc: '', args: []);
  }

  /// `{hours}h {minutes}m`
  String time_range_duration(int hours, int minutes) {
    return Intl.message(
      '${hours}h ${minutes}m',
      name: 'time_range_duration',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `Date`
  String get datetime_field_date {
    return Intl.message(
      'Date',
      name: 'datetime_field_date',
      desc: '',
      args: [],
    );
  }

  /// `Time`
  String get datetime_field_time {
    return Intl.message(
      'Time',
      name: 'datetime_field_time',
      desc: '',
      args: [],
    );
  }

  /// `Email or phone number`
  String get login_field_hint {
    return Intl.message(
      'Email or phone number',
      name: 'login_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter national ID`
  String get national_id_field_hint {
    return Intl.message(
      'Enter national ID',
      name: 'national_id_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `National ID is required`
  String get national_id_required {
    return Intl.message(
      'National ID is required',
      name: 'national_id_required',
      desc: '',
      args: [],
    );
  }

  /// `Must be {length} digits`
  String national_id_length(int length) {
    return Intl.message(
      'Must be $length digits',
      name: 'national_id_length',
      desc: '',
      args: [length],
    );
  }

  /// `Enter a valid ID number`
  String get national_id_generic {
    return Intl.message(
      'Enter a valid ID number',
      name: 'national_id_generic',
      desc: '',
      args: [],
    );
  }

  /// `Invalid ID prefix`
  String get national_id_prefix {
    return Intl.message(
      'Invalid ID prefix',
      name: 'national_id_prefix',
      desc: '',
      args: [],
    );
  }

  /// `Invalid ID number`
  String get national_id_checksum {
    return Intl.message(
      'Invalid ID number',
      name: 'national_id_checksum',
      desc: '',
      args: [],
    );
  }

  /// `The embedded birth date is invalid`
  String get national_id_birthdate {
    return Intl.message(
      'The embedded birth date is invalid',
      name: 'national_id_birthdate',
      desc: '',
      args: [],
    );
  }

  /// `Unknown governorate code`
  String get national_id_governorate {
    return Intl.message(
      'Unknown governorate code',
      name: 'national_id_governorate',
      desc: '',
      args: [],
    );
  }

  /// `ID doesn't match the birth date`
  String get national_id_dob_mismatch {
    return Intl.message(
      'ID doesn\'t match the birth date',
      name: 'national_id_dob_mismatch',
      desc: '',
      args: [],
    );
  }

  /// `Citizens only`
  String get national_id_citizens_only {
    return Intl.message(
      'Citizens only',
      name: 'national_id_citizens_only',
      desc: '',
      args: [],
    );
  }

  /// `Residents only`
  String get national_id_residents_only {
    return Intl.message(
      'Residents only',
      name: 'national_id_residents_only',
      desc: '',
      args: [],
    );
  }

  /// `Born {date}`
  String national_id_born(String date) {
    return Intl.message(
      'Born $date',
      name: 'national_id_born',
      desc: '',
      args: [date],
    );
  }

  /// `Male`
  String get national_id_male {
    return Intl.message('Male', name: 'national_id_male', desc: '', args: []);
  }

  /// `Female`
  String get national_id_female {
    return Intl.message(
      'Female',
      name: 'national_id_female',
      desc: '',
      args: [],
    );
  }

  /// `Citizen`
  String get national_id_citizen {
    return Intl.message(
      'Citizen',
      name: 'national_id_citizen',
      desc: '',
      args: [],
    );
  }

  /// `Resident`
  String get national_id_resident {
    return Intl.message(
      'Resident',
      name: 'national_id_resident',
      desc: '',
      args: [],
    );
  }

  /// `Area / District`
  String get address_field_area {
    return Intl.message(
      'Area / District',
      name: 'address_field_area',
      desc: '',
      args: [],
    );
  }

  /// `Neighborhood or district`
  String get address_field_area_hint {
    return Intl.message(
      'Neighborhood or district',
      name: 'address_field_area_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter city`
  String get address_field_city_hint {
    return Intl.message(
      'Enter city',
      name: 'address_field_city_hint',
      desc: '',
      args: [],
    );
  }

  /// `Apartment, floor, landmark`
  String get address_field_line2_hint {
    return Intl.message(
      'Apartment, floor, landmark',
      name: 'address_field_line2_hint',
      desc: '',
      args: [],
    );
  }

  /// `Enter {label}`
  String address_field_enter(String label) {
    return Intl.message(
      'Enter $label',
      name: 'address_field_enter',
      desc: '',
      args: [label],
    );
  }

  /// `Home`
  String get address_field_type_home {
    return Intl.message(
      'Home',
      name: 'address_field_type_home',
      desc: '',
      args: [],
    );
  }

  /// `Work`
  String get address_field_type_work {
    return Intl.message(
      'Work',
      name: 'address_field_type_work',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get address_field_type_other {
    return Intl.message(
      'Other',
      name: 'address_field_type_other',
      desc: '',
      args: [],
    );
  }

  /// `Recipient name`
  String get address_field_recipient {
    return Intl.message(
      'Recipient name',
      name: 'address_field_recipient',
      desc: '',
      args: [],
    );
  }

  /// `Who receives this`
  String get address_field_recipient_hint {
    return Intl.message(
      'Who receives this',
      name: 'address_field_recipient_hint',
      desc: '',
      args: [],
    );
  }

  /// `Contact phone`
  String get address_field_phone {
    return Intl.message(
      'Contact phone',
      name: 'address_field_phone',
      desc: '',
      args: [],
    );
  }

  /// `Exact location`
  String get location_field_label {
    return Intl.message(
      'Exact location',
      name: 'location_field_label',
      desc: '',
      args: [],
    );
  }

  /// `Latitude`
  String get location_field_latitude {
    return Intl.message(
      'Latitude',
      name: 'location_field_latitude',
      desc: '',
      args: [],
    );
  }

  /// `Longitude`
  String get location_field_longitude {
    return Intl.message(
      'Longitude',
      name: 'location_field_longitude',
      desc: '',
      args: [],
    );
  }

  /// `Use current location`
  String get location_field_use_current {
    return Intl.message(
      'Use current location',
      name: 'location_field_use_current',
      desc: '',
      args: [],
    );
  }

  /// `Pick on map`
  String get location_field_pick_map {
    return Intl.message(
      'Pick on map',
      name: 'location_field_pick_map',
      desc: '',
      args: [],
    );
  }

  /// `Location unavailable — check GPS and permissions`
  String get location_field_unavailable {
    return Intl.message(
      'Location unavailable — check GPS and permissions',
      name: 'location_field_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Confirm location`
  String get location_field_confirm {
    return Intl.message(
      'Confirm location',
      name: 'location_field_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Latitude must be between -90 and 90`
  String get location_field_lat_range {
    return Intl.message(
      'Latitude must be between -90 and 90',
      name: 'location_field_lat_range',
      desc: '',
      args: [],
    );
  }

  /// `Longitude must be between -180 and 180`
  String get location_field_lng_range {
    return Intl.message(
      'Longitude must be between -180 and 180',
      name: 'location_field_lng_range',
      desc: '',
      args: [],
    );
  }

  /// `Delivery notes (optional)`
  String get address_field_notes {
    return Intl.message(
      'Delivery notes (optional)',
      name: 'address_field_notes',
      desc: '',
      args: [],
    );
  }

  /// `Leave at the door, ring twice…`
  String get address_field_notes_hint {
    return Intl.message(
      'Leave at the door, ring twice…',
      name: 'address_field_notes_hint',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get address_field_country {
    return Intl.message(
      'Country',
      name: 'address_field_country',
      desc: '',
      args: [],
    );
  }

  /// `Street address`
  String get address_field_street {
    return Intl.message(
      'Street address',
      name: 'address_field_street',
      desc: '',
      args: [],
    );
  }

  /// `Street name and number`
  String get address_field_street_hint {
    return Intl.message(
      'Street name and number',
      name: 'address_field_street_hint',
      desc: '',
      args: [],
    );
  }

  /// `Apartment, suite, building (optional)`
  String get address_field_line2 {
    return Intl.message(
      'Apartment, suite, building (optional)',
      name: 'address_field_line2',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get address_field_city {
    return Intl.message('City', name: 'address_field_city', desc: '', args: []);
  }

  /// `State`
  String get address_field_state {
    return Intl.message(
      'State',
      name: 'address_field_state',
      desc: '',
      args: [],
    );
  }

  /// `Governorate`
  String get address_field_governorate {
    return Intl.message(
      'Governorate',
      name: 'address_field_governorate',
      desc: '',
      args: [],
    );
  }

  /// `Emirate`
  String get address_field_emirate {
    return Intl.message(
      'Emirate',
      name: 'address_field_emirate',
      desc: '',
      args: [],
    );
  }

  /// `Region`
  String get address_field_region {
    return Intl.message(
      'Region',
      name: 'address_field_region',
      desc: '',
      args: [],
    );
  }

  /// `County`
  String get address_field_county {
    return Intl.message(
      'County',
      name: 'address_field_county',
      desc: '',
      args: [],
    );
  }

  /// `Postal code`
  String get address_field_postal_code {
    return Intl.message(
      'Postal code',
      name: 'address_field_postal_code',
      desc: '',
      args: [],
    );
  }

  /// `ZIP code`
  String get address_field_zip_code {
    return Intl.message(
      'ZIP code',
      name: 'address_field_zip_code',
      desc: '',
      args: [],
    );
  }

  /// `Postcode`
  String get address_field_postcode {
    return Intl.message(
      'Postcode',
      name: 'address_field_postcode',
      desc: '',
      args: [],
    );
  }

  /// `{label} is required`
  String address_field_field_required(String label) {
    return Intl.message(
      '$label is required',
      name: 'address_field_field_required',
      desc: '',
      args: [label],
    );
  }

  /// `Enter a valid {label}`
  String address_field_postal_invalid(String label) {
    return Intl.message(
      'Enter a valid $label',
      name: 'address_field_postal_invalid',
      desc: '',
      args: [label],
    );
  }

  /// `Select {label}`
  String address_field_select_state(String label) {
    return Intl.message(
      'Select $label',
      name: 'address_field_select_state',
      desc: '',
      args: [label],
    );
  }

  /// `Duration is required`
  String get duration_field_required {
    return Intl.message(
      'Duration is required',
      name: 'duration_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Enter a complete duration`
  String get duration_field_incomplete {
    return Intl.message(
      'Enter a complete duration',
      name: 'duration_field_incomplete',
      desc: '',
      args: [],
    );
  }

  /// `Must be at least {duration}`
  String duration_field_min(String duration) {
    return Intl.message(
      'Must be at least $duration',
      name: 'duration_field_min',
      desc: '',
      args: [duration],
    );
  }

  /// `Must be at most {duration}`
  String duration_field_max(String duration) {
    return Intl.message(
      'Must be at most $duration',
      name: 'duration_field_max',
      desc: '',
      args: [duration],
    );
  }

  /// `Minutes must be in {step}-minute steps`
  String duration_field_step(int step) {
    return Intl.message(
      'Minutes must be in $step-minute steps',
      name: 'duration_field_step',
      desc: '',
      args: [step],
    );
  }

  /// `{minutes}m`
  String duration_field_minutes(int minutes) {
    return Intl.message(
      '${minutes}m',
      name: 'duration_field_minutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `{seconds}s`
  String duration_field_seconds(int seconds) {
    return Intl.message(
      '${seconds}s',
      name: 'duration_field_seconds',
      desc: '',
      args: [seconds],
    );
  }

  /// `Pick duration`
  String get duration_field_pick {
    return Intl.message(
      'Pick duration',
      name: 'duration_field_pick',
      desc: '',
      args: [],
    );
  }

  /// `Hours`
  String get duration_field_hours_word {
    return Intl.message(
      'Hours',
      name: 'duration_field_hours_word',
      desc: '',
      args: [],
    );
  }

  /// `Minutes`
  String get duration_field_minutes_word {
    return Intl.message(
      'Minutes',
      name: 'duration_field_minutes_word',
      desc: '',
      args: [],
    );
  }

  /// `Seconds`
  String get duration_field_seconds_word {
    return Intl.message(
      'Seconds',
      name: 'duration_field_seconds_word',
      desc: '',
      args: [],
    );
  }

  /// `Enter percentage`
  String get percent_field_hint {
    return Intl.message(
      'Enter percentage',
      name: 'percent_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Percentage is required`
  String get percent_field_required {
    return Intl.message(
      'Percentage is required',
      name: 'percent_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Must be between {min} and {max}`
  String percent_field_range(String min, String max) {
    return Intl.message(
      'Must be between $min and $max',
      name: 'percent_field_range',
      desc: '',
      args: [min, max],
    );
  }

  /// `Must be at least {min}`
  String percent_field_min(String min) {
    return Intl.message(
      'Must be at least $min',
      name: 'percent_field_min',
      desc: '',
      args: [min],
    );
  }

  /// `Must be at most {max}`
  String percent_field_max(String max) {
    return Intl.message(
      'Must be at most $max',
      name: 'percent_field_max',
      desc: '',
      args: [max],
    );
  }

  /// `Enter plate number`
  String get plate_field_hint {
    return Intl.message(
      'Enter plate number',
      name: 'plate_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Plate number is required`
  String get plate_field_required {
    return Intl.message(
      'Plate number is required',
      name: 'plate_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Invalid plate number`
  String get plate_field_invalid {
    return Intl.message(
      'Invalid plate number',
      name: 'plate_field_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Enter wallet address`
  String get crypto_field_hint {
    return Intl.message(
      'Enter wallet address',
      name: 'crypto_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Wallet address is required`
  String get crypto_field_required {
    return Intl.message(
      'Wallet address is required',
      name: 'crypto_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Invalid {network} address`
  String crypto_field_invalid(String network) {
    return Intl.message(
      'Invalid $network address',
      name: 'crypto_field_invalid',
      desc: '',
      args: [network],
    );
  }

  /// `Enter VIN`
  String get vin_field_hint {
    return Intl.message(
      'Enter VIN',
      name: 'vin_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `VIN is required`
  String get vin_field_required {
    return Intl.message(
      'VIN is required',
      name: 'vin_field_required',
      desc: '',
      args: [],
    );
  }

  /// `VIN is 17 characters`
  String get vin_field_length {
    return Intl.message(
      'VIN is 17 characters',
      name: 'vin_field_length',
      desc: '',
      args: [],
    );
  }

  /// `Invalid VIN (check digit mismatch)`
  String get vin_field_checksum {
    return Intl.message(
      'Invalid VIN (check digit mismatch)',
      name: 'vin_field_checksum',
      desc: '',
      args: [],
    );
  }

  /// `Model year {year}`
  String vin_field_year(int year) {
    return Intl.message(
      'Model year $year',
      name: 'vin_field_year',
      desc: '',
      args: [year],
    );
  }

  /// `Enter IP or hostname`
  String get ip_field_hint {
    return Intl.message(
      'Enter IP or hostname',
      name: 'ip_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Address is required`
  String get ip_field_required {
    return Intl.message(
      'Address is required',
      name: 'ip_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Invalid IP address`
  String get ip_field_invalid_ip {
    return Intl.message(
      'Invalid IP address',
      name: 'ip_field_invalid_ip',
      desc: '',
      args: [],
    );
  }

  /// `Invalid hostname`
  String get ip_field_invalid_host {
    return Intl.message(
      'Invalid hostname',
      name: 'ip_field_invalid_host',
      desc: '',
      args: [],
    );
  }

  /// `Invalid port`
  String get ip_field_invalid_port {
    return Intl.message(
      'Invalid port',
      name: 'ip_field_invalid_port',
      desc: '',
      args: [],
    );
  }

  /// `Enter promo code`
  String get promo_field_hint {
    return Intl.message(
      'Enter promo code',
      name: 'promo_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Apply`
  String get promo_field_apply {
    return Intl.message('Apply', name: 'promo_field_apply', desc: '', args: []);
  }

  /// `Remove code`
  String get promo_field_remove {
    return Intl.message(
      'Remove code',
      name: 'promo_field_remove',
      desc: '',
      args: [],
    );
  }

  /// `Enter a code first`
  String get promo_field_empty {
    return Intl.message(
      'Enter a code first',
      name: 'promo_field_empty',
      desc: '',
      args: [],
    );
  }

  /// `Enter SWIFT / BIC`
  String get swift_field_hint {
    return Intl.message(
      'Enter SWIFT / BIC',
      name: 'swift_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `SWIFT / BIC is required`
  String get swift_field_required {
    return Intl.message(
      'SWIFT / BIC is required',
      name: 'swift_field_required',
      desc: '',
      args: [],
    );
  }

  /// `BIC is 8 or 11 characters`
  String get swift_field_length {
    return Intl.message(
      'BIC is 8 or 11 characters',
      name: 'swift_field_length',
      desc: '',
      args: [],
    );
  }

  /// `Bank code is 4 letters`
  String get swift_field_bank {
    return Intl.message(
      'Bank code is 4 letters',
      name: 'swift_field_bank',
      desc: '',
      args: [],
    );
  }

  /// `Unknown country code`
  String get swift_field_country {
    return Intl.message(
      'Unknown country code',
      name: 'swift_field_country',
      desc: '',
      args: [],
    );
  }

  /// `Country not supported`
  String get swift_field_country_not_allowed {
    return Intl.message(
      'Country not supported',
      name: 'swift_field_country_not_allowed',
      desc: '',
      args: [],
    );
  }

  /// `Invalid location code`
  String get swift_field_location {
    return Intl.message(
      'Invalid location code',
      name: 'swift_field_location',
      desc: '',
      args: [],
    );
  }

  /// `Invalid branch code`
  String get swift_field_branch {
    return Intl.message(
      'Invalid branch code',
      name: 'swift_field_branch',
      desc: '',
      args: [],
    );
  }

  /// `BIC country doesn't match the IBAN`
  String get swift_field_iban_mismatch {
    return Intl.message(
      'BIC country doesn\'t match the IBAN',
      name: 'swift_field_iban_mismatch',
      desc: '',
      args: [],
    );
  }

  /// `Head office`
  String get swift_field_head_office {
    return Intl.message(
      'Head office',
      name: 'swift_field_head_office',
      desc: '',
      args: [],
    );
  }

  /// `Test BIC — not for live payments`
  String get swift_field_test_warning {
    return Intl.message(
      'Test BIC — not for live payments',
      name: 'swift_field_test_warning',
      desc: '',
      args: [],
    );
  }

  /// `Add a tag…`
  String get tags_field_hint {
    return Intl.message(
      'Add a tag…',
      name: 'tags_field_hint',
      desc: '',
      args: [],
    );
  }

  /// `Add at least {count} tags`
  String tags_field_min(int count) {
    return Intl.message(
      'Add at least $count tags',
      name: 'tags_field_min',
      desc: '',
      args: [count],
    );
  }

  /// `Max {max} characters`
  String tags_field_too_long(int max) {
    return Intl.message(
      'Max $max characters',
      name: 'tags_field_too_long',
      desc: '',
      args: [max],
    );
  }

  /// `Maximum {max} tags reached`
  String tags_field_max_reached(int max) {
    return Intl.message(
      'Maximum $max tags reached',
      name: 'tags_field_max_reached',
      desc: '',
      args: [max],
    );
  }

  /// `Pick from the suggestions`
  String get tags_field_not_allowed {
    return Intl.message(
      'Pick from the suggestions',
      name: 'tags_field_not_allowed',
      desc: '',
      args: [],
    );
  }

  /// `Select an option`
  String get drop_down_select_option {
    return Intl.message(
      'Select an option',
      name: 'drop_down_select_option',
      desc: '',
      args: [],
    );
  }

  /// `Select options`
  String get drop_down_select_options {
    return Intl.message(
      'Select options',
      name: 'drop_down_select_options',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get drop_down_search {
    return Intl.message('Search', name: 'drop_down_search', desc: '', args: []);
  }

  /// `No results found`
  String get drop_down_no_results {
    return Intl.message(
      'No results found',
      name: 'drop_down_no_results',
      desc: '',
      args: [],
    );
  }

  /// `Create "{query}"`
  String drop_down_create_new(String query) {
    return Intl.message(
      'Create "$query"',
      name: 'drop_down_create_new',
      desc: '',
      args: [query],
    );
  }

  /// `Select All`
  String get drop_down_select_all {
    return Intl.message(
      'Select All',
      name: 'drop_down_select_all',
      desc: '',
      args: [],
    );
  }

  /// `Clear All`
  String get drop_down_clear_all {
    return Intl.message(
      'Clear All',
      name: 'drop_down_clear_all',
      desc: '',
      args: [],
    );
  }

  /// `Selected {count}`
  String drop_down_selected_count(int count) {
    return Intl.message(
      'Selected $count',
      name: 'drop_down_selected_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count}/{max} selected`
  String drop_down_selected_of_max(int count, int max) {
    return Intl.message(
      '$count/$max selected',
      name: 'drop_down_selected_of_max',
      desc: '',
      args: [count, max],
    );
  }

  /// `Couldn't load options`
  String get drop_down_load_failed {
    return Intl.message(
      'Couldn\'t load options',
      name: 'drop_down_load_failed',
      desc: '',
      args: [],
    );
  }

  /// `{labels} (+{count} more)`
  String drop_down_more_items(String labels, int count) {
    return Intl.message(
      '$labels (+$count more)',
      name: 'drop_down_more_items',
      desc: '',
      args: [labels, count],
    );
  }

  /// `Double tap to open`
  String get drop_down_tap_to_open {
    return Intl.message(
      'Double tap to open',
      name: 'drop_down_tap_to_open',
      desc: '',
      args: [],
    );
  }

  /// `Double tap to close`
  String get drop_down_tap_to_close {
    return Intl.message(
      'Double tap to close',
      name: 'drop_down_tap_to_close',
      desc: '',
      args: [],
    );
  }

  /// `Clear selection`
  String get drop_down_clear_selection {
    return Intl.message(
      'Clear selection',
      name: 'drop_down_clear_selection',
      desc: '',
      args: [],
    );
  }

  /// `Current password`
  String get change_password_current_label {
    return Intl.message(
      'Current password',
      name: 'change_password_current_label',
      desc: '',
      args: [],
    );
  }

  /// `Enter current password`
  String get change_password_current_hint {
    return Intl.message(
      'Enter current password',
      name: 'change_password_current_hint',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get change_password_new_label {
    return Intl.message(
      'New password',
      name: 'change_password_new_label',
      desc: '',
      args: [],
    );
  }

  /// `Confirm new password`
  String get change_password_confirm_label {
    return Intl.message(
      'Confirm new password',
      name: 'change_password_confirm_label',
      desc: '',
      args: [],
    );
  }

  /// `New password must be different from your current password`
  String get change_password_same_as_current {
    return Intl.message(
      'New password must be different from your current password',
      name: 'change_password_same_as_current',
      desc: '',
      args: [],
    );
  }

  /// `Account holder`
  String get bank_field_holder_label {
    return Intl.message(
      'Account holder',
      name: 'bank_field_holder_label',
      desc: '',
      args: [],
    );
  }

  /// `Full name on the account`
  String get bank_field_holder_hint {
    return Intl.message(
      'Full name on the account',
      name: 'bank_field_holder_hint',
      desc: '',
      args: [],
    );
  }

  /// `Code sent to {destination}`
  String otp_form_sent_to(String destination) {
    return Intl.message(
      'Code sent to $destination',
      name: 'otp_form_sent_to',
      desc: '',
      args: [destination],
    );
  }

  /// `Didn't receive the code?`
  String get otp_form_no_code {
    return Intl.message(
      'Didn\'t receive the code?',
      name: 'otp_form_no_code',
      desc: '',
      args: [],
    );
  }

  /// `Resend`
  String get otp_form_resend {
    return Intl.message('Resend', name: 'otp_form_resend', desc: '', args: []);
  }

  /// `Resend in {seconds}s`
  String otp_form_resend_in(int seconds) {
    return Intl.message(
      'Resend in ${seconds}s',
      name: 'otp_form_resend_in',
      desc: '',
      args: [seconds],
    );
  }

  /// `Message`
  String get contact_form_message_label {
    return Intl.message(
      'Message',
      name: 'contact_form_message_label',
      desc: '',
      args: [],
    );
  }

  /// `Write your message`
  String get contact_form_message_hint {
    return Intl.message(
      'Write your message',
      name: 'contact_form_message_hint',
      desc: '',
      args: [],
    );
  }

  /// `Message is required`
  String get contact_form_message_required {
    return Intl.message(
      'Message is required',
      name: 'contact_form_message_required',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get field_hint_email {
    return Intl.message(
      'Enter your email',
      name: 'field_hint_email',
      desc: '',
      args: [],
    );
  }

  /// `Enter phone number`
  String get field_hint_phone {
    return Intl.message(
      'Enter phone number',
      name: 'field_hint_phone',
      desc: '',
      args: [],
    );
  }

  /// `Choose a username`
  String get field_hint_username {
    return Intl.message(
      'Choose a username',
      name: 'field_hint_username',
      desc: '',
      args: [],
    );
  }

  /// `Enter passport number`
  String get field_hint_passport {
    return Intl.message(
      'Enter passport number',
      name: 'field_hint_passport',
      desc: '',
      args: [],
    );
  }

  /// `Name on card`
  String get field_hint_cardholder {
    return Intl.message(
      'Name on card',
      name: 'field_hint_cardholder',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get field_hint_search {
    return Intl.message(
      'Search',
      name: 'field_hint_search',
      desc: '',
      args: [],
    );
  }

  /// `Skip`
  String get common_skip {
    return Intl.message('Skip', name: 'common_skip', desc: '', args: []);
  }

  /// `Something went wrong`
  String get common_something_went_wrong {
    return Intl.message(
      'Something went wrong',
      name: 'common_something_went_wrong',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get common_try_again {
    return Intl.message(
      'Try again',
      name: 'common_try_again',
      desc: '',
      args: [],
    );
  }

  /// `Contact support`
  String get common_contact_support {
    return Intl.message(
      'Contact support',
      name: 'common_contact_support',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get common_close {
    return Intl.message('Close', name: 'common_close', desc: '', args: []);
  }

  /// `Pause`
  String get common_pause {
    return Intl.message('Pause', name: 'common_pause', desc: '', args: []);
  }

  /// `Resume`
  String get common_resume {
    return Intl.message('Resume', name: 'common_resume', desc: '', args: []);
  }

  /// `Continue`
  String get common_continue {
    return Intl.message(
      'Continue',
      name: 'common_continue',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss`
  String get common_dismiss {
    return Intl.message('Dismiss', name: 'common_dismiss', desc: '', args: []);
  }

  /// `Update available`
  String get banner_update_title {
    return Intl.message(
      'Update available',
      name: 'banner_update_title',
      desc: '',
      args: [],
    );
  }

  /// `A newer version of the app is ready to install.`
  String get banner_update_message {
    return Intl.message(
      'A newer version of the app is ready to install.',
      name: 'banner_update_message',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get banner_update_action {
    return Intl.message(
      'Update',
      name: 'banner_update_action',
      desc: '',
      args: [],
    );
  }

  /// `Changes you make will sync once you're back online.`
  String get banner_offline_message {
    return Intl.message(
      'Changes you make will sync once you\'re back online.',
      name: 'banner_offline_message',
      desc: '',
      args: [],
    );
  }

  /// `Expand`
  String get common_expand {
    return Intl.message('Expand', name: 'common_expand', desc: '', args: []);
  }

  /// `Collapse`
  String get common_collapse {
    return Intl.message(
      'Collapse',
      name: 'common_collapse',
      desc: '',
      args: [],
    );
  }

  /// `Undo`
  String get common_undo {
    return Intl.message('Undo', name: 'common_undo', desc: '', args: []);
  }

  /// `Dismissed`
  String get common_dismissed {
    return Intl.message(
      'Dismissed',
      name: 'common_dismissed',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get common_clear {
    return Intl.message('Clear', name: 'common_clear', desc: '', args: []);
  }

  /// `Clear all`
  String get common_clear_all {
    return Intl.message(
      'Clear all',
      name: 'common_clear_all',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get common_remove {
    return Intl.message('Remove', name: 'common_remove', desc: '', args: []);
  }

  /// `Save`
  String get common_save {
    return Intl.message('Save', name: 'common_save', desc: '', args: []);
  }

  /// `Saving…`
  String get common_saving {
    return Intl.message('Saving…', name: 'common_saving', desc: '', args: []);
  }

  /// `Edit`
  String get common_edit {
    return Intl.message('Edit', name: 'common_edit', desc: '', args: []);
  }

  /// `Add`
  String get common_add {
    return Intl.message('Add', name: 'common_add', desc: '', args: []);
  }

  /// `Delete`
  String get common_delete {
    return Intl.message('Delete', name: 'common_delete', desc: '', args: []);
  }

  /// `Copy`
  String get common_copy {
    return Intl.message('Copy', name: 'common_copy', desc: '', args: []);
  }

  /// `Copied to clipboard`
  String get common_copied_to_clipboard {
    return Intl.message(
      'Copied to clipboard',
      name: 'common_copied_to_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `No results`
  String get common_no_results {
    return Intl.message(
      'No results',
      name: 'common_no_results',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get common_refresh {
    return Intl.message('Refresh', name: 'common_refresh', desc: '', args: []);
  }

  /// `Search`
  String get common_search {
    return Intl.message('Search', name: 'common_search', desc: '', args: []);
  }

  /// `Share`
  String get common_share {
    return Intl.message('Share', name: 'common_share', desc: '', args: []);
  }

  /// `Next`
  String get common_next {
    return Intl.message('Next', name: 'common_next', desc: '', args: []);
  }

  /// `Qty {count}`
  String common_count(int count) {
    return Intl.message(
      'Qty $count',
      name: 'common_count',
      desc: '',
      args: [count],
    );
  }

  /// `Back`
  String get common_back {
    return Intl.message('Back', name: 'common_back', desc: '', args: []);
  }

  /// `Support email isn't set up yet.`
  String get error_support_email_unconfigured {
    return Intl.message(
      'Support email isn\'t set up yet.',
      name: 'error_support_email_unconfigured',
      desc: '',
      args: [],
    );
  }

  /// `Diagnostics`
  String get error_diagnostics {
    return Intl.message(
      'Diagnostics',
      name: 'error_diagnostics',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't send the report. Please try again.`
  String get error_report_failed {
    return Intl.message(
      'Couldn\'t send the report. Please try again.',
      name: 'error_report_failed',
      desc: '',
      args: [],
    );
  }

  /// `Expected`
  String get coming_soon_eta_label {
    return Intl.message(
      'Expected',
      name: 'coming_soon_eta_label',
      desc: '',
      args: [],
    );
  }

  /// `We're working on it. Check back soon.`
  String get coming_soon_body_plain {
    return Intl.message(
      'We\'re working on it. Check back soon.',
      name: 'coming_soon_body_plain',
      desc: '',
      args: [],
    );
  }

  /// `Use a different email`
  String get coming_soon_change_email {
    return Intl.message(
      'Use a different email',
      name: 'coming_soon_change_email',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{{count} bookmark} other{{count} bookmarks}}`
  String pdf_bookmark_count(int count) {
    return Intl.plural(
      count,
      one: '$count bookmark',
      other: '$count bookmarks',
      name: 'pdf_bookmark_count',
      desc: '',
      args: [count],
    );
  }

  /// `Settings`
  String get common_settings {
    return Intl.message(
      'Settings',
      name: 'common_settings',
      desc: '',
      args: [],
    );
  }

  /// `Open settings`
  String get common_open_settings {
    return Intl.message(
      'Open settings',
      name: 'common_open_settings',
      desc: '',
      args: [],
    );
  }

  /// `Paste`
  String get common_paste {
    return Intl.message('Paste', name: 'common_paste', desc: '', args: []);
  }

  /// `Stop`
  String get common_stop {
    return Intl.message('Stop', name: 'common_stop', desc: '', args: []);
  }

  /// `Previous`
  String get common_previous {
    return Intl.message(
      'Previous',
      name: 'common_previous',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get common_reset {
    return Intl.message('Reset', name: 'common_reset', desc: '', args: []);
  }

  /// `Later`
  String get common_later {
    return Intl.message('Later', name: 'common_later', desc: '', args: []);
  }

  /// `Update`
  String get common_update {
    return Intl.message('Update', name: 'common_update', desc: '', args: []);
  }

  /// `Open`
  String get common_open {
    return Intl.message('Open', name: 'common_open', desc: '', args: []);
  }

  /// `Submit`
  String get common_submit {
    return Intl.message('Submit', name: 'common_submit', desc: '', args: []);
  }

  /// `Help`
  String get common_help {
    return Intl.message('Help', name: 'common_help', desc: '', args: []);
  }

  /// `Unlock`
  String get pdf_unlock {
    return Intl.message('Unlock', name: 'pdf_unlock', desc: '', args: []);
  }

  /// `Previous page`
  String get pdf_previous_page {
    return Intl.message(
      'Previous page',
      name: 'pdf_previous_page',
      desc: '',
      args: [],
    );
  }

  /// `Next page`
  String get pdf_next_page {
    return Intl.message('Next page', name: 'pdf_next_page', desc: '', args: []);
  }

  /// `Reset zoom`
  String get pdf_reset_zoom {
    return Intl.message(
      'Reset zoom',
      name: 'pdf_reset_zoom',
      desc: '',
      args: [],
    );
  }

  /// `Clear draft`
  String get wizard_clear_draft {
    return Intl.message(
      'Clear draft',
      name: 'wizard_clear_draft',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get faq_all {
    return Intl.message('All', name: 'faq_all', desc: '', args: []);
  }

  /// `Recent`
  String get faq_recent {
    return Intl.message('Recent', name: 'faq_recent', desc: '', args: []);
  }

  /// `Still need help?`
  String get faq_still_need_help {
    return Intl.message(
      'Still need help?',
      name: 'faq_still_need_help',
      desc: '',
      args: [],
    );
  }

  /// `Could not save your email. Please try again.`
  String get coming_soon_save_failed {
    return Intl.message(
      'Could not save your email. Please try again.',
      name: 'coming_soon_save_failed',
      desc: '',
      args: [],
    );
  }

  /// `Rotate`
  String get media_rotate {
    return Intl.message('Rotate', name: 'media_rotate', desc: '', args: []);
  }

  /// `Re-align`
  String get media_realign {
    return Intl.message('Re-align', name: 'media_realign', desc: '', args: []);
  }

  /// `{count} of {max} selected`
  String media_selected_count(int count, int max) {
    return Intl.message(
      '$count of $max selected',
      name: 'media_selected_count',
      desc: '',
      args: [count, max],
    );
  }

  /// `Go`
  String get pdf_go {
    return Intl.message('Go', name: 'pdf_go', desc: '', args: []);
  }

  /// `Previous match`
  String get pdf_previous_match {
    return Intl.message(
      'Previous match',
      name: 'pdf_previous_match',
      desc: '',
      args: [],
    );
  }

  /// `Next match`
  String get pdf_next_match {
    return Intl.message(
      'Next match',
      name: 'pdf_next_match',
      desc: '',
      args: [],
    );
  }

  /// `Forget this document`
  String get pdf_forget {
    return Intl.message(
      'Forget this document',
      name: 'pdf_forget',
      desc: '',
      args: [],
    );
  }

  /// `Outline`
  String get pdf_outline {
    return Intl.message('Outline', name: 'pdf_outline', desc: '', args: []);
  }

  /// `Bookmarks`
  String get pdf_bookmarks {
    return Intl.message('Bookmarks', name: 'pdf_bookmarks', desc: '', args: []);
  }

  /// `Scan code`
  String get scanner_title {
    return Intl.message('Scan code', name: 'scanner_title', desc: '', args: []);
  }

  /// `Expand`
  String get drawer_expand {
    return Intl.message('Expand', name: 'drawer_expand', desc: '', args: []);
  }

  /// `Submit failed`
  String get wizard_submit_failed {
    return Intl.message(
      'Submit failed',
      name: 'wizard_submit_failed',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure?`
  String get sheet_confirm_title {
    return Intl.message(
      'Are you sure?',
      name: 'sheet_confirm_title',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get sheet_confirm {
    return Intl.message('Confirm', name: 'sheet_confirm', desc: '', args: []);
  }

  /// `Delete this item?`
  String get sheet_delete_title {
    return Intl.message(
      'Delete this item?',
      name: 'sheet_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `This action cannot be undone.`
  String get sheet_delete_message {
    return Intl.message(
      'This action cannot be undone.',
      name: 'sheet_delete_message',
      desc: '',
      args: [],
    );
  }

  /// `Log out?`
  String get sheet_logout_title {
    return Intl.message(
      'Log out?',
      name: 'sheet_logout_title',
      desc: '',
      args: [],
    );
  }

  /// `You can sign back in at any time.`
  String get sheet_logout_message {
    return Intl.message(
      'You can sign back in at any time.',
      name: 'sheet_logout_message',
      desc: '',
      args: [],
    );
  }

  /// `Log out`
  String get sheet_logout_confirm {
    return Intl.message(
      'Log out',
      name: 'sheet_logout_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Discard changes?`
  String get sheet_discard_title {
    return Intl.message(
      'Discard changes?',
      name: 'sheet_discard_title',
      desc: '',
      args: [],
    );
  }

  /// `Your unsaved changes will be lost.`
  String get sheet_discard_message {
    return Intl.message(
      'Your unsaved changes will be lost.',
      name: 'sheet_discard_message',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get sheet_discard_confirm {
    return Intl.message(
      'Discard',
      name: 'sheet_discard_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Got it`
  String get sheet_got_it {
    return Intl.message('Got it', name: 'sheet_got_it', desc: '', args: []);
  }

  /// `Filters`
  String get sheet_filters {
    return Intl.message('Filters', name: 'sheet_filters', desc: '', args: []);
  }

  /// `Apply`
  String get sheet_apply {
    return Intl.message('Apply', name: 'sheet_apply', desc: '', args: []);
  }

  /// `Reset`
  String get sheet_reset {
    return Intl.message('Reset', name: 'sheet_reset', desc: '', args: []);
  }

  /// `Tap to retry`
  String get common_tap_to_retry {
    return Intl.message(
      'Tap to retry',
      name: 'common_tap_to_retry',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get button_tooltip_add {
    return Intl.message('Add', name: 'button_tooltip_add', desc: '', args: []);
  }

  /// `Copy`
  String get button_tooltip_copy {
    return Intl.message(
      'Copy',
      name: 'button_tooltip_copy',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get button_tooltip_delete {
    return Intl.message(
      'Delete',
      name: 'button_tooltip_delete',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get button_tooltip_edit {
    return Intl.message(
      'Edit',
      name: 'button_tooltip_edit',
      desc: '',
      args: [],
    );
  }

  /// `Filter`
  String get button_tooltip_filter {
    return Intl.message(
      'Filter',
      name: 'button_tooltip_filter',
      desc: '',
      args: [],
    );
  }

  /// `More`
  String get button_tooltip_more {
    return Intl.message(
      'More',
      name: 'button_tooltip_more',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get button_tooltip_refresh {
    return Intl.message(
      'Refresh',
      name: 'button_tooltip_refresh',
      desc: '',
      args: [],
    );
  }

  /// `Search`
  String get button_tooltip_search {
    return Intl.message(
      'Search',
      name: 'button_tooltip_search',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get button_tooltip_send {
    return Intl.message(
      'Send',
      name: 'button_tooltip_send',
      desc: '',
      args: [],
    );
  }

  /// `Add to favorites`
  String get button_tooltip_add_favorite {
    return Intl.message(
      'Add to favorites',
      name: 'button_tooltip_add_favorite',
      desc: '',
      args: [],
    );
  }

  /// `Remove from favorites`
  String get button_tooltip_remove_favorite {
    return Intl.message(
      'Remove from favorites',
      name: 'button_tooltip_remove_favorite',
      desc: '',
      args: [],
    );
  }

  /// `Start voice input`
  String get button_tooltip_start_voice_input {
    return Intl.message(
      'Start voice input',
      name: 'button_tooltip_start_voice_input',
      desc: '',
      args: [],
    );
  }

  /// `Stop listening`
  String get button_tooltip_stop_listening {
    return Intl.message(
      'Stop listening',
      name: 'button_tooltip_stop_listening',
      desc: '',
      args: [],
    );
  }

  /// `Read more`
  String get button_read_more {
    return Intl.message(
      'Read more',
      name: 'button_read_more',
      desc: '',
      args: [],
    );
  }

  /// `Show less`
  String get button_show_less {
    return Intl.message(
      'Show less',
      name: 'button_show_less',
      desc: '',
      args: [],
    );
  }

  /// `Icon button`
  String get button_icon_semantic_label {
    return Intl.message(
      'Icon button',
      name: 'button_icon_semantic_label',
      desc: '',
      args: [],
    );
  }

  /// `Success`
  String get button_result_success {
    return Intl.message(
      'Success',
      name: 'button_result_success',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get button_result_failed {
    return Intl.message(
      'Failed',
      name: 'button_result_failed',
      desc: '',
      args: [],
    );
  }

  /// `Continue with {provider}`
  String social_button_continue_with(String provider) {
    return Intl.message(
      'Continue with $provider',
      name: 'social_button_continue_with',
      desc: '',
      args: [provider],
    );
  }

  /// `Gender`
  String get drop_down_gender_label {
    return Intl.message(
      'Gender',
      name: 'drop_down_gender_label',
      desc: '',
      args: [],
    );
  }

  /// `Select gender`
  String get drop_down_gender_hint {
    return Intl.message(
      'Select gender',
      name: 'drop_down_gender_hint',
      desc: '',
      args: [],
    );
  }

  /// `Hour`
  String get drop_down_hour_label {
    return Intl.message(
      'Hour',
      name: 'drop_down_hour_label',
      desc: '',
      args: [],
    );
  }

  /// `Select hour`
  String get drop_down_hour_hint {
    return Intl.message(
      'Select hour',
      name: 'drop_down_hour_hint',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get drop_down_language_label {
    return Intl.message(
      'Language',
      name: 'drop_down_language_label',
      desc: '',
      args: [],
    );
  }

  /// `Select language`
  String get drop_down_language_hint {
    return Intl.message(
      'Select language',
      name: 'drop_down_language_hint',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get drop_down_month_label {
    return Intl.message(
      'Month',
      name: 'drop_down_month_label',
      desc: '',
      args: [],
    );
  }

  /// `Select month`
  String get drop_down_month_hint {
    return Intl.message(
      'Select month',
      name: 'drop_down_month_hint',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get drop_down_theme_label {
    return Intl.message(
      'Theme',
      name: 'drop_down_theme_label',
      desc: '',
      args: [],
    );
  }

  /// `Select theme`
  String get drop_down_theme_hint {
    return Intl.message(
      'Select theme',
      name: 'drop_down_theme_hint',
      desc: '',
      args: [],
    );
  }

  /// `Year`
  String get drop_down_year_label {
    return Intl.message(
      'Year',
      name: 'drop_down_year_label',
      desc: '',
      args: [],
    );
  }

  /// `Select year`
  String get drop_down_year_hint {
    return Intl.message(
      'Select year',
      name: 'drop_down_year_hint',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get drop_down_country_hint {
    return Intl.message(
      'Country',
      name: 'drop_down_country_hint',
      desc: '',
      args: [],
    );
  }

  /// `Select a governorate / region`
  String get drop_down_state_hint {
    return Intl.message(
      'Select a governorate / region',
      name: 'drop_down_state_hint',
      desc: '',
      args: [],
    );
  }

  /// `Select a city / area`
  String get drop_down_city_hint {
    return Intl.message(
      'Select a city / area',
      name: 'drop_down_city_hint',
      desc: '',
      args: [],
    );
  }

  /// `Select currency`
  String get drop_down_currency_hint {
    return Intl.message(
      'Select currency',
      name: 'drop_down_currency_hint',
      desc: '',
      args: [],
    );
  }

  /// `Select unit`
  String get drop_down_unit_hint {
    return Intl.message(
      'Select unit',
      name: 'drop_down_unit_hint',
      desc: '',
      args: [],
    );
  }

  /// `Format`
  String get drop_down_color_format_label {
    return Intl.message(
      'Format',
      name: 'drop_down_color_format_label',
      desc: '',
      args: [],
    );
  }

  /// `Select format`
  String get drop_down_color_format_hint {
    return Intl.message(
      'Select format',
      name: 'drop_down_color_format_hint',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get drop_down_day_label {
    return Intl.message('Day', name: 'drop_down_day_label', desc: '', args: []);
  }

  /// `Select day`
  String get drop_down_day_hint {
    return Intl.message(
      'Select day',
      name: 'drop_down_day_hint',
      desc: '',
      args: [],
    );
  }

  /// `Weekday`
  String get drop_down_weekday_label {
    return Intl.message(
      'Weekday',
      name: 'drop_down_weekday_label',
      desc: '',
      args: [],
    );
  }

  /// `Select weekday`
  String get drop_down_weekday_hint {
    return Intl.message(
      'Select weekday',
      name: 'drop_down_weekday_hint',
      desc: '',
      args: [],
    );
  }

  /// `Nationality`
  String get drop_down_nationality_hint {
    return Intl.message(
      'Nationality',
      name: 'drop_down_nationality_hint',
      desc: '',
      args: [],
    );
  }

  /// `Select timezone`
  String get drop_down_timezone_hint {
    return Intl.message(
      'Select timezone',
      name: 'drop_down_timezone_hint',
      desc: '',
      args: [],
    );
  }

  /// `Blood type`
  String get drop_down_blood_type_label {
    return Intl.message(
      'Blood type',
      name: 'drop_down_blood_type_label',
      desc: '',
      args: [],
    );
  }

  /// `Select blood type`
  String get drop_down_blood_type_hint {
    return Intl.message(
      'Select blood type',
      name: 'drop_down_blood_type_hint',
      desc: '',
      args: [],
    );
  }

  /// `Marital status`
  String get drop_down_marital_status_label {
    return Intl.message(
      'Marital status',
      name: 'drop_down_marital_status_label',
      desc: '',
      args: [],
    );
  }

  /// `Select status`
  String get drop_down_marital_status_hint {
    return Intl.message(
      'Select status',
      name: 'drop_down_marital_status_hint',
      desc: '',
      args: [],
    );
  }

  /// `Education`
  String get drop_down_education_label {
    return Intl.message(
      'Education',
      name: 'drop_down_education_label',
      desc: '',
      args: [],
    );
  }

  /// `Select level`
  String get drop_down_education_hint {
    return Intl.message(
      'Select level',
      name: 'drop_down_education_hint',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get drop_down_sort_by_label {
    return Intl.message(
      'Sort by',
      name: 'drop_down_sort_by_label',
      desc: '',
      args: [],
    );
  }

  /// `Sort by`
  String get drop_down_sort_by_hint {
    return Intl.message(
      'Sort by',
      name: 'drop_down_sort_by_hint',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get drop_down_duration_label {
    return Intl.message(
      'Duration',
      name: 'drop_down_duration_label',
      desc: '',
      args: [],
    );
  }

  /// `Select duration`
  String get drop_down_duration_hint {
    return Intl.message(
      'Select duration',
      name: 'drop_down_duration_hint',
      desc: '',
      args: [],
    );
  }

  /// `Repeat`
  String get drop_down_recurrence_label {
    return Intl.message(
      'Repeat',
      name: 'drop_down_recurrence_label',
      desc: '',
      args: [],
    );
  }

  /// `Select repeat`
  String get drop_down_recurrence_hint {
    return Intl.message(
      'Select repeat',
      name: 'drop_down_recurrence_hint',
      desc: '',
      args: [],
    );
  }

  /// `English`
  String get language_name_en {
    return Intl.message(
      'English',
      name: 'language_name_en',
      desc: '',
      args: [],
    );
  }

  /// `Arabic`
  String get language_name_ar {
    return Intl.message('Arabic', name: 'language_name_ar', desc: '', args: []);
  }

  /// `Male`
  String get gender_male {
    return Intl.message('Male', name: 'gender_male', desc: '', args: []);
  }

  /// `Female`
  String get gender_female {
    return Intl.message('Female', name: 'gender_female', desc: '', args: []);
  }

  /// `Other`
  String get gender_other {
    return Intl.message('Other', name: 'gender_other', desc: '', args: []);
  }

  /// `Prefer not to say`
  String get gender_prefer_not_to_say {
    return Intl.message(
      'Prefer not to say',
      name: 'gender_prefer_not_to_say',
      desc: '',
      args: [],
    );
  }

  /// `Single`
  String get marital_single {
    return Intl.message('Single', name: 'marital_single', desc: '', args: []);
  }

  /// `Married`
  String get marital_married {
    return Intl.message('Married', name: 'marital_married', desc: '', args: []);
  }

  /// `Divorced`
  String get marital_divorced {
    return Intl.message(
      'Divorced',
      name: 'marital_divorced',
      desc: '',
      args: [],
    );
  }

  /// `Widowed`
  String get marital_widowed {
    return Intl.message('Widowed', name: 'marital_widowed', desc: '', args: []);
  }

  /// `Primary`
  String get education_primary {
    return Intl.message(
      'Primary',
      name: 'education_primary',
      desc: '',
      args: [],
    );
  }

  /// `Middle school`
  String get education_middle {
    return Intl.message(
      'Middle school',
      name: 'education_middle',
      desc: '',
      args: [],
    );
  }

  /// `High school`
  String get education_secondary {
    return Intl.message(
      'High school',
      name: 'education_secondary',
      desc: '',
      args: [],
    );
  }

  /// `Diploma`
  String get education_diploma {
    return Intl.message(
      'Diploma',
      name: 'education_diploma',
      desc: '',
      args: [],
    );
  }

  /// `Bachelor's`
  String get education_bachelor {
    return Intl.message(
      'Bachelor\'s',
      name: 'education_bachelor',
      desc: '',
      args: [],
    );
  }

  /// `Master's`
  String get education_master {
    return Intl.message(
      'Master\'s',
      name: 'education_master',
      desc: '',
      args: [],
    );
  }

  /// `Doctorate`
  String get education_doctorate {
    return Intl.message(
      'Doctorate',
      name: 'education_doctorate',
      desc: '',
      args: [],
    );
  }

  /// `Newest`
  String get sort_newest {
    return Intl.message('Newest', name: 'sort_newest', desc: '', args: []);
  }

  /// `Oldest`
  String get sort_oldest {
    return Intl.message('Oldest', name: 'sort_oldest', desc: '', args: []);
  }

  /// `Price: low to high`
  String get sort_price_low_high {
    return Intl.message(
      'Price: low to high',
      name: 'sort_price_low_high',
      desc: '',
      args: [],
    );
  }

  /// `Price: high to low`
  String get sort_price_high_low {
    return Intl.message(
      'Price: high to low',
      name: 'sort_price_high_low',
      desc: '',
      args: [],
    );
  }

  /// `Name: A–Z`
  String get sort_name_az {
    return Intl.message('Name: A–Z', name: 'sort_name_az', desc: '', args: []);
  }

  /// `Name: Z–A`
  String get sort_name_za {
    return Intl.message('Name: Z–A', name: 'sort_name_za', desc: '', args: []);
  }

  /// `Highest rated`
  String get sort_rating {
    return Intl.message(
      'Highest rated',
      name: 'sort_rating',
      desc: '',
      args: [],
    );
  }

  /// `Most relevant`
  String get sort_relevance {
    return Intl.message(
      'Most relevant',
      name: 'sort_relevance',
      desc: '',
      args: [],
    );
  }

  /// `Does not repeat`
  String get recurrence_none {
    return Intl.message(
      'Does not repeat',
      name: 'recurrence_none',
      desc: '',
      args: [],
    );
  }

  /// `Daily`
  String get recurrence_daily {
    return Intl.message('Daily', name: 'recurrence_daily', desc: '', args: []);
  }

  /// `Weekly`
  String get recurrence_weekly {
    return Intl.message(
      'Weekly',
      name: 'recurrence_weekly',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get recurrence_monthly {
    return Intl.message(
      'Monthly',
      name: 'recurrence_monthly',
      desc: '',
      args: [],
    );
  }

  /// `Yearly`
  String get recurrence_yearly {
    return Intl.message(
      'Yearly',
      name: 'recurrence_yearly',
      desc: '',
      args: [],
    );
  }

  /// `{n} min`
  String duration_minutes(int n) {
    return Intl.message(
      '$n min',
      name: 'duration_minutes',
      desc: '',
      args: [n],
    );
  }

  /// `{n} h`
  String duration_hours(int n) {
    return Intl.message('$n h', name: 'duration_hours', desc: '', args: [n]);
  }

  /// `{n} d`
  String duration_days(int n) {
    return Intl.message('$n d', name: 'duration_days', desc: '', args: [n]);
  }

  /// `System`
  String get theme_mode_system {
    return Intl.message(
      'System',
      name: 'theme_mode_system',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get theme_mode_light {
    return Intl.message('Light', name: 'theme_mode_light', desc: '', args: []);
  }

  /// `Dark`
  String get theme_mode_dark {
    return Intl.message('Dark', name: 'theme_mode_dark', desc: '', args: []);
  }

  /// `IBAN`
  String get bank_field_iban_label {
    return Intl.message(
      'IBAN',
      name: 'bank_field_iban_label',
      desc: '',
      args: [],
    );
  }

  /// `SWIFT / BIC`
  String get bank_field_swift_bic_label {
    return Intl.message(
      'SWIFT / BIC',
      name: 'bank_field_swift_bic_label',
      desc: '',
      args: [],
    );
  }

  /// `Card number`
  String get card_field_number_label {
    return Intl.message(
      'Card number',
      name: 'card_field_number_label',
      desc: '',
      args: [],
    );
  }

  /// `Expiry`
  String get card_field_expiry_label {
    return Intl.message(
      'Expiry',
      name: 'card_field_expiry_label',
      desc: '',
      args: [],
    );
  }

  /// `CVV`
  String get card_field_cvv_label {
    return Intl.message(
      'CVV',
      name: 'card_field_cvv_label',
      desc: '',
      args: [],
    );
  }

  /// `Pick a color`
  String get color_field_picker_title {
    return Intl.message(
      'Pick a color',
      name: 'color_field_picker_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter a color`
  String get color_field_required {
    return Intl.message(
      'Enter a color',
      name: 'color_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Use {hint}`
  String color_field_invalid_format(String hint) {
    return Intl.message(
      'Use $hint',
      name: 'color_field_invalid_format',
      desc: '',
      args: [hint],
    );
  }

  /// `Use a secure https:// link`
  String get url_field_https_required {
    return Intl.message(
      'Use a secure https:// link',
      name: 'url_field_https_required',
      desc: '',
      args: [],
    );
  }

  /// `Link type "{scheme}" isn’t allowed`
  String url_field_scheme_not_allowed(String scheme) {
    return Intl.message(
      'Link type "$scheme" isn’t allowed',
      name: 'url_field_scheme_not_allowed',
      desc: '',
      args: [scheme],
    );
  }

  /// `Link must be on {domains}`
  String url_field_domain_not_allowed(String domains) {
    return Intl.message(
      'Link must be on $domains',
      name: 'url_field_domain_not_allowed',
      desc: '',
      args: [domains],
    );
  }

  /// `Links to {host} aren’t allowed`
  String url_field_domain_blocked(String host) {
    return Intl.message(
      'Links to $host aren’t allowed',
      name: 'url_field_domain_blocked',
      desc: '',
      args: [host],
    );
  }

  /// `Address uses lookalike characters — check it carefully`
  String get url_field_lookalike_host {
    return Intl.message(
      'Address uses lookalike characters — check it carefully',
      name: 'url_field_lookalike_host',
      desc: '',
      args: [],
    );
  }

  /// `Encoded international domain — check it carefully`
  String get url_field_punycode_host {
    return Intl.message(
      'Encoded international domain — check it carefully',
      name: 'url_field_punycode_host',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss`
  String get url_field_dismiss_paste {
    return Intl.message(
      'Dismiss',
      name: 'url_field_dismiss_paste',
      desc: '',
      args: [],
    );
  }

  /// `Increase`
  String get stepper_increase {
    return Intl.message(
      'Increase',
      name: 'stepper_increase',
      desc: '',
      args: [],
    );
  }

  /// `Decrease`
  String get stepper_decrease {
    return Intl.message(
      'Decrease',
      name: 'stepper_decrease',
      desc: '',
      args: [],
    );
  }

  /// `Code must be {length} characters`
  String otp_field_must_be_n_chars(int length) {
    return Intl.message(
      'Code must be $length characters',
      name: 'otp_field_must_be_n_chars',
      desc: '',
      args: [length],
    );
  }

  /// `Scroll to top`
  String get scroll_to_top {
    return Intl.message(
      'Scroll to top',
      name: 'scroll_to_top',
      desc: '',
      args: [],
    );
  }

  /// `Scroll progress`
  String get scroll_progress {
    return Intl.message(
      'Scroll progress',
      name: 'scroll_progress',
      desc: '',
      args: [],
    );
  }

  /// `{count} new`
  String scroll_new_items(int count) {
    return Intl.message(
      '$count new',
      name: 'scroll_new_items',
      desc: '',
      args: [count],
    );
  }

  /// `Page {page}`
  String list_page(int page) {
    return Intl.message(
      'Page $page',
      name: 'list_page',
      desc: '',
      args: [page],
    );
  }

  /// `Card {index} of {total}`
  String stack_card_of(String index, String total) {
    return Intl.message(
      'Card $index of $total',
      name: 'stack_card_of',
      desc: '',
      args: [index, total],
    );
  }

  /// `Item {index} of {total}`
  String stack_layer_of(String index, String total) {
    return Intl.message(
      'Item $index of $total',
      name: 'stack_layer_of',
      desc: '',
      args: [index, total],
    );
  }

  /// `Swipe left`
  String get stack_swipe_left {
    return Intl.message(
      'Swipe left',
      name: 'stack_swipe_left',
      desc: '',
      args: [],
    );
  }

  /// `Swipe right`
  String get stack_swipe_right {
    return Intl.message(
      'Swipe right',
      name: 'stack_swipe_right',
      desc: '',
      args: [],
    );
  }

  /// `Swipe up`
  String get stack_swipe_up {
    return Intl.message('Swipe up', name: 'stack_swipe_up', desc: '', args: []);
  }

  /// `Swipe down`
  String get stack_swipe_down {
    return Intl.message(
      'Swipe down',
      name: 'stack_swipe_down',
      desc: '',
      args: [],
    );
  }

  /// `Page {page} of {total}`
  String list_page_of(String page, String total) {
    return Intl.message(
      'Page $page of $total',
      name: 'list_page_of',
      desc: '',
      args: [page, total],
    );
  }

  /// `Previous page`
  String get list_previous_page {
    return Intl.message(
      'Previous page',
      name: 'list_previous_page',
      desc: '',
      args: [],
    );
  }

  /// `Next page`
  String get list_next_page {
    return Intl.message(
      'Next page',
      name: 'list_next_page',
      desc: '',
      args: [],
    );
  }

  /// `More pages`
  String get list_more_pages {
    return Intl.message(
      'More pages',
      name: 'list_more_pages',
      desc: '',
      args: [],
    );
  }

  /// `Section index`
  String get list_section_index {
    return Intl.message(
      'Section index',
      name: 'list_section_index',
      desc: '',
      args: [],
    );
  }

  /// `Load more`
  String get list_load_more {
    return Intl.message(
      'Load more',
      name: 'list_load_more',
      desc: '',
      args: [],
    );
  }

  /// `Nothing here yet`
  String get list_empty_title {
    return Intl.message(
      'Nothing here yet',
      name: 'list_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Clear selection`
  String get list_clear_selection {
    return Intl.message(
      'Clear selection',
      name: 'list_clear_selection',
      desc: '',
      args: [],
    );
  }

  /// `{count} selected`
  String list_selected_count(int count) {
    return Intl.message(
      '$count selected',
      name: 'list_selected_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count} notifications`
  String badge_count_notifications(String count) {
    return Intl.message(
      '$count notifications',
      name: 'badge_count_notifications',
      desc: '',
      args: [count],
    );
  }

  /// `New notification`
  String get badge_new_notification {
    return Intl.message(
      'New notification',
      name: 'badge_new_notification',
      desc: '',
      args: [],
    );
  }

  /// `Read more`
  String get text_read_more {
    return Intl.message(
      'Read more',
      name: 'text_read_more',
      desc: '',
      args: [],
    );
  }

  /// `Read less`
  String get text_read_less {
    return Intl.message(
      'Read less',
      name: 'text_read_less',
      desc: '',
      args: [],
    );
  }

  /// `Select All`
  String get checkbox_select_all {
    return Intl.message(
      'Select All',
      name: 'checkbox_select_all',
      desc: '',
      args: [],
    );
  }

  /// `Checkbox`
  String get checkbox_semantic_label {
    return Intl.message(
      'Checkbox',
      name: 'checkbox_semantic_label',
      desc: '',
      args: [],
    );
  }

  /// `On`
  String get switch_on {
    return Intl.message('On', name: 'switch_on', desc: '', args: []);
  }

  /// `Off`
  String get switch_off {
    return Intl.message('Off', name: 'switch_off', desc: '', args: []);
  }

  /// `Dark mode`
  String get switch_dark_mode {
    return Intl.message(
      'Dark mode',
      name: 'switch_dark_mode',
      desc: '',
      args: [],
    );
  }

  /// `Push notifications`
  String get switch_notifications {
    return Intl.message(
      'Push notifications',
      name: 'switch_notifications',
      desc: '',
      args: [],
    );
  }

  /// `Biometric unlock`
  String get switch_biometric {
    return Intl.message(
      'Biometric unlock',
      name: 'switch_biometric',
      desc: '',
      args: [],
    );
  }

  /// `Face ID / fingerprint on launch`
  String get switch_biometric_desc {
    return Intl.message(
      'Face ID / fingerprint on launch',
      name: 'switch_biometric_desc',
      desc: '',
      args: [],
    );
  }

  /// `Share usage data`
  String get switch_analytics {
    return Intl.message(
      'Share usage data',
      name: 'switch_analytics',
      desc: '',
      args: [],
    );
  }

  /// `Anonymous analytics that help improve the app`
  String get switch_analytics_desc {
    return Intl.message(
      'Anonymous analytics that help improve the app',
      name: 'switch_analytics_desc',
      desc: '',
      args: [],
    );
  }

  /// `Send crash reports`
  String get switch_crash_reports {
    return Intl.message(
      'Send crash reports',
      name: 'switch_crash_reports',
      desc: '',
      args: [],
    );
  }

  /// `Haptic feedback`
  String get switch_haptics {
    return Intl.message(
      'Haptic feedback',
      name: 'switch_haptics',
      desc: '',
      args: [],
    );
  }

  /// `Page {index} of {total}`
  String indicator_page_of(int index, int total) {
    return Intl.message(
      'Page $index of $total',
      name: 'indicator_page_of',
      desc: '',
      args: [index, total],
    );
  }

  /// `Go to page {index}`
  String indicator_go_to_page(int index) {
    return Intl.message(
      'Go to page $index',
      name: 'indicator_go_to_page',
      desc: '',
      args: [index],
    );
  }

  /// `Story {index} of {total}`
  String indicator_story_segment(int index, int total) {
    return Intl.message(
      'Story $index of $total',
      name: 'indicator_story_segment',
      desc: '',
      args: [index, total],
    );
  }

  /// `playing`
  String get indicator_story_playing {
    return Intl.message(
      'playing',
      name: 'indicator_story_playing',
      desc: '',
      args: [],
    );
  }

  /// `paused`
  String get indicator_story_paused {
    return Intl.message(
      'paused',
      name: 'indicator_story_paused',
      desc: '',
      args: [],
    );
  }

  /// `Step {index} of {total}`
  String stepper_step_of(int index, int total) {
    return Intl.message(
      'Step $index of $total',
      name: 'stepper_step_of',
      desc: '',
      args: [index, total],
    );
  }

  /// `current step`
  String get stepper_current {
    return Intl.message(
      'current step',
      name: 'stepper_current',
      desc: '',
      args: [],
    );
  }

  /// `completed`
  String get stepper_completed {
    return Intl.message(
      'completed',
      name: 'stepper_completed',
      desc: '',
      args: [],
    );
  }

  /// `not started`
  String get stepper_upcoming {
    return Intl.message(
      'not started',
      name: 'stepper_upcoming',
      desc: '',
      args: [],
    );
  }

  /// `needs attention`
  String get stepper_error {
    return Intl.message(
      'needs attention',
      name: 'stepper_error',
      desc: '',
      args: [],
    );
  }

  /// `unavailable`
  String get stepper_disabled {
    return Intl.message(
      'unavailable',
      name: 'stepper_disabled',
      desc: '',
      args: [],
    );
  }

  /// `Volume`
  String get slider_volume {
    return Intl.message('Volume', name: 'slider_volume', desc: '', args: []);
  }

  /// `Muted`
  String get slider_muted {
    return Intl.message('Muted', name: 'slider_muted', desc: '', args: []);
  }

  /// `Brightness`
  String get slider_brightness {
    return Intl.message(
      'Brightness',
      name: 'slider_brightness',
      desc: '',
      args: [],
    );
  }

  /// `Text size`
  String get slider_text_size {
    return Intl.message(
      'Text size',
      name: 'slider_text_size',
      desc: '',
      args: [],
    );
  }

  /// `Playback speed`
  String get slider_playback_speed {
    return Intl.message(
      'Playback speed',
      name: 'slider_playback_speed',
      desc: '',
      args: [],
    );
  }

  /// `Quality`
  String get slider_quality {
    return Intl.message('Quality', name: 'slider_quality', desc: '', args: []);
  }

  /// `Low`
  String get slider_quality_low {
    return Intl.message('Low', name: 'slider_quality_low', desc: '', args: []);
  }

  /// `Medium`
  String get slider_quality_medium {
    return Intl.message(
      'Medium',
      name: 'slider_quality_medium',
      desc: '',
      args: [],
    );
  }

  /// `High`
  String get slider_quality_high {
    return Intl.message(
      'High',
      name: 'slider_quality_high',
      desc: '',
      args: [],
    );
  }

  /// `Ultra`
  String get slider_quality_ultra {
    return Intl.message(
      'Ultra',
      name: 'slider_quality_ultra',
      desc: '',
      args: [],
    );
  }

  /// `Price range`
  String get slider_price_range {
    return Intl.message(
      'Price range',
      name: 'slider_price_range',
      desc: '',
      args: [],
    );
  }

  /// `Age range`
  String get slider_age_range {
    return Intl.message(
      'Age range',
      name: 'slider_age_range',
      desc: '',
      args: [],
    );
  }

  /// `yrs`
  String get slider_years {
    return Intl.message('yrs', name: 'slider_years', desc: '', args: []);
  }

  /// `Distance`
  String get slider_distance {
    return Intl.message(
      'Distance',
      name: 'slider_distance',
      desc: '',
      args: [],
    );
  }

  /// `km`
  String get slider_unit_km {
    return Intl.message('km', name: 'slider_unit_km', desc: '', args: []);
  }

  /// `mi`
  String get slider_unit_mi {
    return Intl.message('mi', name: 'slider_unit_mi', desc: '', args: []);
  }

  /// `Minimum rating`
  String get slider_min_rating {
    return Intl.message(
      'Minimum rating',
      name: 'slider_min_rating',
      desc: '',
      args: [],
    );
  }

  /// `Any`
  String get slider_any {
    return Intl.message('Any', name: 'slider_any', desc: '', args: []);
  }

  /// `More options`
  String get toggle_group_overflow_tooltip {
    return Intl.message(
      'More options',
      name: 'toggle_group_overflow_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `{count} more options`
  String toggle_group_overflow_label(int count) {
    return Intl.message(
      '$count more options',
      name: 'toggle_group_overflow_label',
      desc: '',
      args: [count],
    );
  }

  /// `No results for “{query}”`
  String empty_no_results_title(String query) {
    return Intl.message(
      'No results for “$query”',
      name: 'empty_no_results_title',
      desc: '',
      args: [query],
    );
  }

  /// `Try a different spelling, or fewer words.`
  String get empty_no_results_subtitle {
    return Intl.message(
      'Try a different spelling, or fewer words.',
      name: 'empty_no_results_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Clear search`
  String get empty_clear_search {
    return Intl.message(
      'Clear search',
      name: 'empty_clear_search',
      desc: '',
      args: [],
    );
  }

  /// `You're offline`
  String get empty_offline_title {
    return Intl.message(
      'You\'re offline',
      name: 'empty_offline_title',
      desc: '',
      args: [],
    );
  }

  /// `Check your connection and try again.`
  String get empty_offline_subtitle {
    return Intl.message(
      'Check your connection and try again.',
      name: 'empty_offline_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong`
  String get empty_failed_title {
    return Intl.message(
      'Something went wrong',
      name: 'empty_failed_title',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't load this. Try again in a moment.`
  String get empty_failed_subtitle {
    return Intl.message(
      'We couldn\'t load this. Try again in a moment.',
      name: 'empty_failed_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get empty_retry {
    return Intl.message('Try again', name: 'empty_retry', desc: '', args: []);
  }

  /// `{count} more`
  String avatar_more_count(int count) {
    return Intl.message(
      '$count more',
      name: 'avatar_more_count',
      desc: '',
      args: [count],
    );
  }

  /// `Rating`
  String get rating_semantic_label {
    return Intl.message(
      'Rating',
      name: 'rating_semantic_label',
      desc: '',
      args: [],
    );
  }

  /// `{value} out of {count}`
  String rating_value_out_of(String value, int count) {
    return Intl.message(
      '$value out of $count',
      name: 'rating_value_out_of',
      desc: '',
      args: [value, count],
    );
  }

  /// `Radio option`
  String get radio_semantic_label {
    return Intl.message(
      'Radio option',
      name: 'radio_semantic_label',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get radio_yes {
    return Intl.message('Yes', name: 'radio_yes', desc: '', args: []);
  }

  /// `No`
  String get radio_no {
    return Intl.message('No', name: 'radio_no', desc: '', args: []);
  }

  /// `I agree to the `
  String get consent_prefix {
    return Intl.message(
      'I agree to the ',
      name: 'consent_prefix',
      desc: '',
      args: [],
    );
  }

  /// `Terms of Service`
  String get consent_terms {
    return Intl.message(
      'Terms of Service',
      name: 'consent_terms',
      desc: '',
      args: [],
    );
  }

  /// ` and `
  String get consent_and {
    return Intl.message(' and ', name: 'consent_and', desc: '', args: []);
  }

  /// `Privacy Policy`
  String get consent_privacy {
    return Intl.message(
      'Privacy Policy',
      name: 'consent_privacy',
      desc: '',
      args: [],
    );
  }

  /// `You must accept the terms to continue`
  String get consent_required {
    return Intl.message(
      'You must accept the terms to continue',
      name: 'consent_required',
      desc: '',
      args: [],
    );
  }

  /// `I confirm I am {age} or older`
  String checkbox_age_confirm(int age) {
    return Intl.message(
      'I confirm I am $age or older',
      name: 'checkbox_age_confirm',
      desc: '',
      args: [age],
    );
  }

  /// `You must confirm your age to continue`
  String get checkbox_age_required {
    return Intl.message(
      'You must confirm your age to continue',
      name: 'checkbox_age_required',
      desc: '',
      args: [],
    );
  }

  /// `You must acknowledge this to continue`
  String get checkbox_acknowledge_required {
    return Intl.message(
      'You must acknowledge this to continue',
      name: 'checkbox_acknowledge_required',
      desc: '',
      args: [],
    );
  }

  /// `Send me offers and product updates`
  String get checkbox_marketing_opt_in {
    return Intl.message(
      'Send me offers and product updates',
      name: 'checkbox_marketing_opt_in',
      desc: '',
      args: [],
    );
  }

  /// `Don't show this again`
  String get checkbox_dont_show_again {
    return Intl.message(
      'Don\'t show this again',
      name: 'checkbox_dont_show_again',
      desc: '',
      args: [],
    );
  }

  /// `Save this card for future payments`
  String get checkbox_save_card {
    return Intl.message(
      'Save this card for future payments',
      name: 'checkbox_save_card',
      desc: '',
      args: [],
    );
  }

  /// `Set as default address`
  String get checkbox_default_address {
    return Intl.message(
      'Set as default address',
      name: 'checkbox_default_address',
      desc: '',
      args: [],
    );
  }

  /// `Shipping address same as billing`
  String get checkbox_same_as_billing {
    return Intl.message(
      'Shipping address same as billing',
      name: 'checkbox_same_as_billing',
      desc: '',
      args: [],
    );
  }

  /// `Toggle group`
  String get toggle_group_semantic_label {
    return Intl.message(
      'Toggle group',
      name: 'toggle_group_semantic_label',
      desc: '',
      args: [],
    );
  }

  /// `Ascending`
  String get toggle_group_sort_asc {
    return Intl.message(
      'Ascending',
      name: 'toggle_group_sort_asc',
      desc: '',
      args: [],
    );
  }

  /// `Descending`
  String get toggle_group_sort_desc {
    return Intl.message(
      'Descending',
      name: 'toggle_group_sort_desc',
      desc: '',
      args: [],
    );
  }

  /// `Bold`
  String get toggle_group_format_bold {
    return Intl.message(
      'Bold',
      name: 'toggle_group_format_bold',
      desc: '',
      args: [],
    );
  }

  /// `Italic`
  String get toggle_group_format_italic {
    return Intl.message(
      'Italic',
      name: 'toggle_group_format_italic',
      desc: '',
      args: [],
    );
  }

  /// `Underline`
  String get toggle_group_format_underline {
    return Intl.message(
      'Underline',
      name: 'toggle_group_format_underline',
      desc: '',
      args: [],
    );
  }

  /// `Strikethrough`
  String get toggle_group_format_strikethrough {
    return Intl.message(
      'Strikethrough',
      name: 'toggle_group_format_strikethrough',
      desc: '',
      args: [],
    );
  }

  /// `Align start`
  String get toggle_group_align_start {
    return Intl.message(
      'Align start',
      name: 'toggle_group_align_start',
      desc: '',
      args: [],
    );
  }

  /// `Align center`
  String get toggle_group_align_center {
    return Intl.message(
      'Align center',
      name: 'toggle_group_align_center',
      desc: '',
      args: [],
    );
  }

  /// `Align end`
  String get toggle_group_align_end {
    return Intl.message(
      'Align end',
      name: 'toggle_group_align_end',
      desc: '',
      args: [],
    );
  }

  /// `Justify`
  String get toggle_group_align_justify {
    return Intl.message(
      'Justify',
      name: 'toggle_group_align_justify',
      desc: '',
      args: [],
    );
  }

  /// `Push`
  String get toggle_group_channel_push {
    return Intl.message(
      'Push',
      name: 'toggle_group_channel_push',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get toggle_group_channel_email {
    return Intl.message(
      'Email',
      name: 'toggle_group_channel_email',
      desc: '',
      args: [],
    );
  }

  /// `SMS`
  String get toggle_group_channel_sms {
    return Intl.message(
      'SMS',
      name: 'toggle_group_channel_sms',
      desc: '',
      args: [],
    );
  }

  /// `Morning`
  String get toggle_group_daypart_morning {
    return Intl.message(
      'Morning',
      name: 'toggle_group_daypart_morning',
      desc: '',
      args: [],
    );
  }

  /// `Afternoon`
  String get toggle_group_daypart_afternoon {
    return Intl.message(
      'Afternoon',
      name: 'toggle_group_daypart_afternoon',
      desc: '',
      args: [],
    );
  }

  /// `Evening`
  String get toggle_group_daypart_evening {
    return Intl.message(
      'Evening',
      name: 'toggle_group_daypart_evening',
      desc: '',
      args: [],
    );
  }

  /// `Night`
  String get toggle_group_daypart_night {
    return Intl.message(
      'Night',
      name: 'toggle_group_daypart_night',
      desc: '',
      args: [],
    );
  }

  /// `Any`
  String get toggle_group_count_any {
    return Intl.message(
      'Any',
      name: 'toggle_group_count_any',
      desc: '',
      args: [],
    );
  }

  /// `Segmented control`
  String get segmented_control_semantic_label {
    return Intl.message(
      'Segmented control',
      name: 'segmented_control_semantic_label',
      desc: '',
      args: [],
    );
  }

  /// `List`
  String get segmented_control_view_list {
    return Intl.message(
      'List',
      name: 'segmented_control_view_list',
      desc: '',
      args: [],
    );
  }

  /// `Grid`
  String get segmented_control_view_grid {
    return Intl.message(
      'Grid',
      name: 'segmented_control_view_grid',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get segmented_control_period_day {
    return Intl.message(
      'Day',
      name: 'segmented_control_period_day',
      desc: '',
      args: [],
    );
  }

  /// `Week`
  String get segmented_control_period_week {
    return Intl.message(
      'Week',
      name: 'segmented_control_period_week',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get segmented_control_period_month {
    return Intl.message(
      'Month',
      name: 'segmented_control_period_month',
      desc: '',
      args: [],
    );
  }

  /// `Year`
  String get segmented_control_period_year {
    return Intl.message(
      'Year',
      name: 'segmented_control_period_year',
      desc: '',
      args: [],
    );
  }

  /// `Map`
  String get segmented_control_view_map {
    return Intl.message(
      'Map',
      name: 'segmented_control_view_map',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get segmented_control_status_all {
    return Intl.message(
      'All',
      name: 'segmented_control_status_all',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get segmented_control_status_active {
    return Intl.message(
      'Active',
      name: 'segmented_control_status_active',
      desc: '',
      args: [],
    );
  }

  /// `Archived`
  String get segmented_control_status_archived {
    return Intl.message(
      'Archived',
      name: 'segmented_control_status_archived',
      desc: '',
      args: [],
    );
  }

  /// `12h`
  String get segmented_control_time_12h {
    return Intl.message(
      '12h',
      name: 'segmented_control_time_12h',
      desc: '',
      args: [],
    );
  }

  /// `24h`
  String get segmented_control_time_24h {
    return Intl.message(
      '24h',
      name: 'segmented_control_time_24h',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get dialog_confirm {
    return Intl.message('Confirm', name: 'dialog_confirm', desc: '', args: []);
  }

  /// `Enter text...`
  String get dialog_enter_text_hint {
    return Intl.message(
      'Enter text...',
      name: 'dialog_enter_text_hint',
      desc: '',
      args: [],
    );
  }

  /// `Closing in {seconds}s`
  String dialog_closing_in(int seconds) {
    return Intl.message(
      'Closing in ${seconds}s',
      name: 'dialog_closing_in',
      desc: '',
      args: [seconds],
    );
  }

  /// `Popup opened`
  String get popup_opened_semantic {
    return Intl.message(
      'Popup opened',
      name: 'popup_opened_semantic',
      desc: '',
      args: [],
    );
  }

  /// `Popup closed`
  String get popup_closed_semantic {
    return Intl.message(
      'Popup closed',
      name: 'popup_closed_semantic',
      desc: '',
      args: [],
    );
  }

  /// `No results found`
  String get drawer_no_results {
    return Intl.message(
      'No results found',
      name: 'drawer_no_results',
      desc: '',
      args: [],
    );
  }

  /// `No items match "{query}"`
  String drawer_no_items_match(String query) {
    return Intl.message(
      'No items match "$query"',
      name: 'drawer_no_items_match',
      desc: '',
      args: [query],
    );
  }

  /// `Failed to load video`
  String get video_load_failed {
    return Intl.message(
      'Failed to load video',
      name: 'video_load_failed',
      desc: '',
      args: [],
    );
  }

  /// `Video player`
  String get video_player {
    return Intl.message(
      'Video player',
      name: 'video_player',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get video_play {
    return Intl.message('Play', name: 'video_play', desc: '', args: []);
  }

  /// `Pause`
  String get video_pause {
    return Intl.message('Pause', name: 'video_pause', desc: '', args: []);
  }

  /// `Replay from the start`
  String get video_replay {
    return Intl.message(
      'Replay from the start',
      name: 'video_replay',
      desc: '',
      args: [],
    );
  }

  /// `Mute`
  String get video_mute {
    return Intl.message('Mute', name: 'video_mute', desc: '', args: []);
  }

  /// `Unmute`
  String get video_unmute {
    return Intl.message('Unmute', name: 'video_unmute', desc: '', args: []);
  }

  /// `Enter fullscreen`
  String get video_enter_fullscreen {
    return Intl.message(
      'Enter fullscreen',
      name: 'video_enter_fullscreen',
      desc: '',
      args: [],
    );
  }

  /// `Exit fullscreen`
  String get video_exit_fullscreen {
    return Intl.message(
      'Exit fullscreen',
      name: 'video_exit_fullscreen',
      desc: '',
      args: [],
    );
  }

  /// `Playback settings`
  String get video_settings {
    return Intl.message(
      'Playback settings',
      name: 'video_settings',
      desc: '',
      args: [],
    );
  }

  /// `Take a screenshot`
  String get video_screenshot {
    return Intl.message(
      'Take a screenshot',
      name: 'video_screenshot',
      desc: '',
      args: [],
    );
  }

  /// `Next video`
  String get video_next {
    return Intl.message('Next video', name: 'video_next', desc: '', args: []);
  }

  /// `Previous video`
  String get video_previous {
    return Intl.message(
      'Previous video',
      name: 'video_previous',
      desc: '',
      args: [],
    );
  }

  /// `Playback position`
  String get video_seek {
    return Intl.message(
      'Playback position',
      name: 'video_seek',
      desc: '',
      args: [],
    );
  }

  /// `Playback speed`
  String get video_playback_speed {
    return Intl.message(
      'Playback speed',
      name: 'video_playback_speed',
      desc: '',
      args: [],
    );
  }

  /// `Subtitles`
  String get video_subtitles {
    return Intl.message(
      'Subtitles',
      name: 'video_subtitles',
      desc: '',
      args: [],
    );
  }

  /// `Audio track`
  String get video_audio_track {
    return Intl.message(
      'Audio track',
      name: 'video_audio_track',
      desc: '',
      args: [],
    );
  }

  /// `Quality`
  String get video_quality {
    return Intl.message('Quality', name: 'video_quality', desc: '', args: []);
  }

  /// `Lock screen`
  String get video_lock_screen {
    return Intl.message(
      'Lock screen',
      name: 'video_lock_screen',
      desc: '',
      args: [],
    );
  }

  /// `Unlock screen`
  String get video_unlock_screen {
    return Intl.message(
      'Unlock screen',
      name: 'video_unlock_screen',
      desc: '',
      args: [],
    );
  }

  /// `Up next`
  String get video_up_next {
    return Intl.message('Up next', name: 'video_up_next', desc: '', args: []);
  }

  /// `Cancel`
  String get video_cancel_autoplay {
    return Intl.message(
      'Cancel',
      name: 'video_cancel_autoplay',
      desc: '',
      args: [],
    );
  }

  /// `Play now`
  String get video_play_now {
    return Intl.message('Play now', name: 'video_play_now', desc: '', args: []);
  }

  /// `Subtitles on`
  String get video_subtitles_on {
    return Intl.message(
      'Subtitles on',
      name: 'video_subtitles_on',
      desc: '',
      args: [],
    );
  }

  /// `Subtitles off`
  String get video_subtitles_off {
    return Intl.message(
      'Subtitles off',
      name: 'video_subtitles_off',
      desc: '',
      args: [],
    );
  }

  /// `Chapters`
  String get video_chapters {
    return Intl.message('Chapters', name: 'video_chapters', desc: '', args: []);
  }

  /// `Play from start`
  String get video_replay_start {
    return Intl.message(
      'Play from start',
      name: 'video_replay_start',
      desc: '',
      args: [],
    );
  }

  /// `Fill the frame`
  String get video_zoom_fill {
    return Intl.message(
      'Fill the frame',
      name: 'video_zoom_fill',
      desc: '',
      args: [],
    );
  }

  /// `Fit the frame`
  String get video_zoom_fit {
    return Intl.message(
      'Fit the frame',
      name: 'video_zoom_fit',
      desc: '',
      args: [],
    );
  }

  /// `Sleep timer`
  String get video_sleep_timer {
    return Intl.message(
      'Sleep timer',
      name: 'video_sleep_timer',
      desc: '',
      args: [],
    );
  }

  /// `No timer`
  String get video_sleep_off {
    return Intl.message(
      'No timer',
      name: 'video_sleep_off',
      desc: '',
      args: [],
    );
  }

  /// `{count} min`
  String video_sleep_minutes(int count) {
    return Intl.message(
      '$count min',
      name: 'video_sleep_minutes',
      desc: '',
      args: [count],
    );
  }

  /// `End of this video`
  String get video_sleep_end {
    return Intl.message(
      'End of this video',
      name: 'video_sleep_end',
      desc: '',
      args: [],
    );
  }

  /// `Loop from here`
  String get video_loop_set_a {
    return Intl.message(
      'Loop from here',
      name: 'video_loop_set_a',
      desc: '',
      args: [],
    );
  }

  /// `Loop to here`
  String get video_loop_set_b {
    return Intl.message(
      'Loop to here',
      name: 'video_loop_set_b',
      desc: '',
      args: [],
    );
  }

  /// `Clear loop`
  String get video_loop_clear {
    return Intl.message(
      'Clear loop',
      name: 'video_loop_clear',
      desc: '',
      args: [],
    );
  }

  /// `Subtitle delay`
  String get video_subtitle_delay {
    return Intl.message(
      'Subtitle delay',
      name: 'video_subtitle_delay',
      desc: '',
      args: [],
    );
  }

  /// `Earlier`
  String get video_subtitle_earlier {
    return Intl.message(
      'Earlier',
      name: 'video_subtitle_earlier',
      desc: '',
      args: [],
    );
  }

  /// `Later`
  String get video_subtitle_later {
    return Intl.message(
      'Later',
      name: 'video_subtitle_later',
      desc: '',
      args: [],
    );
  }

  /// `In sync`
  String get video_subtitle_reset {
    return Intl.message(
      'In sync',
      name: 'video_subtitle_reset',
      desc: '',
      args: [],
    );
  }

  /// `Play on another screen`
  String get video_cast {
    return Intl.message(
      'Play on another screen',
      name: 'video_cast',
      desc: '',
      args: [],
    );
  }

  /// `Subtitle size`
  String get video_subtitle_size {
    return Intl.message(
      'Subtitle size',
      name: 'video_subtitle_size',
      desc: '',
      args: [],
    );
  }

  /// `Smaller`
  String get video_subtitle_smaller {
    return Intl.message(
      'Smaller',
      name: 'video_subtitle_smaller',
      desc: '',
      args: [],
    );
  }

  /// `Larger`
  String get video_subtitle_larger {
    return Intl.message(
      'Larger',
      name: 'video_subtitle_larger',
      desc: '',
      args: [],
    );
  }

  /// `Normal`
  String get video_subtitle_normal {
    return Intl.message(
      'Normal',
      name: 'video_subtitle_normal',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get audio_play {
    return Intl.message('Play', name: 'audio_play', desc: '', args: []);
  }

  /// `Pause`
  String get audio_pause {
    return Intl.message('Pause', name: 'audio_pause', desc: '', args: []);
  }

  /// `Loading`
  String get audio_loading {
    return Intl.message('Loading', name: 'audio_loading', desc: '', args: []);
  }

  /// `Could not play this audio`
  String get audio_error {
    return Intl.message(
      'Could not play this audio',
      name: 'audio_error',
      desc: '',
      args: [],
    );
  }

  /// `Back {count} seconds`
  String audio_skip_back(int count) {
    return Intl.message(
      'Back $count seconds',
      name: 'audio_skip_back',
      desc: '',
      args: [count],
    );
  }

  /// `Forward {count} seconds`
  String audio_skip_forward(int count) {
    return Intl.message(
      'Forward $count seconds',
      name: 'audio_skip_forward',
      desc: '',
      args: [count],
    );
  }

  /// `Playback speed`
  String get audio_speed {
    return Intl.message(
      'Playback speed',
      name: 'audio_speed',
      desc: '',
      args: [],
    );
  }

  /// `Repeat`
  String get audio_loop {
    return Intl.message('Repeat', name: 'audio_loop', desc: '', args: []);
  }

  /// `Position`
  String get audio_timeline {
    return Intl.message('Position', name: 'audio_timeline', desc: '', args: []);
  }

  /// `Scrub the audio`
  String get audio_waveform {
    return Intl.message(
      'Scrub the audio',
      name: 'audio_waveform',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get audio_retry {
    return Intl.message('Try again', name: 'audio_retry', desc: '', args: []);
  }

  /// `Next track`
  String get audio_next {
    return Intl.message('Next track', name: 'audio_next', desc: '', args: []);
  }

  /// `Previous track`
  String get audio_previous {
    return Intl.message(
      'Previous track',
      name: 'audio_previous',
      desc: '',
      args: [],
    );
  }

  /// `Sleep timer`
  String get audio_sleep {
    return Intl.message('Sleep timer', name: 'audio_sleep', desc: '', args: []);
  }

  /// `Sleep timer off`
  String get audio_sleep_off {
    return Intl.message(
      'Sleep timer off',
      name: 'audio_sleep_off',
      desc: '',
      args: [],
    );
  }

  /// `Stop at end of track`
  String get audio_sleep_end {
    return Intl.message(
      'Stop at end of track',
      name: 'audio_sleep_end',
      desc: '',
      args: [],
    );
  }

  /// `Stop in {minutes} minutes`
  String audio_sleep_minutes(int minutes) {
    return Intl.message(
      'Stop in $minutes minutes',
      name: 'audio_sleep_minutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `{minutes}m`
  String audio_sleep_short_minutes(int minutes) {
    return Intl.message(
      '${minutes}m',
      name: 'audio_sleep_short_minutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `End`
  String get audio_sleep_short_end {
    return Intl.message(
      'End',
      name: 'audio_sleep_short_end',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get video_off {
    return Intl.message('Off', name: 'video_off', desc: '', args: []);
  }

  /// `Skip forward {seconds} seconds`
  String video_seek_forward(int seconds) {
    return Intl.message(
      'Skip forward $seconds seconds',
      name: 'video_seek_forward',
      desc: '',
      args: [seconds],
    );
  }

  /// `Skip back {seconds} seconds`
  String video_seek_back(int seconds) {
    return Intl.message(
      'Skip back $seconds seconds',
      name: 'video_seek_back',
      desc: '',
      args: [seconds],
    );
  }

  /// `No audio output device`
  String get video_no_audio_device {
    return Intl.message(
      'No audio output device',
      name: 'video_no_audio_device',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load animation`
  String get animation_load_failed {
    return Intl.message(
      'Failed to load animation',
      name: 'animation_load_failed',
      desc: '',
      args: [],
    );
  }

  /// `Animation not found`
  String get animation_not_found {
    return Intl.message(
      'Animation not found',
      name: 'animation_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Access denied`
  String get animation_access_denied {
    return Intl.message(
      'Access denied',
      name: 'animation_access_denied',
      desc: '',
      args: [],
    );
  }

  /// `Network error`
  String get animation_network_error {
    return Intl.message(
      'Network error',
      name: 'animation_network_error',
      desc: '',
      args: [],
    );
  }

  /// `Invalid animation file`
  String get animation_invalid_file {
    return Intl.message(
      'Invalid animation file',
      name: 'animation_invalid_file',
      desc: '',
      args: [],
    );
  }

  /// `Play`
  String get animation_play {
    return Intl.message('Play', name: 'animation_play', desc: '', args: []);
  }

  /// `Pause`
  String get animation_pause {
    return Intl.message('Pause', name: 'animation_pause', desc: '', args: []);
  }

  /// `Replay from the start`
  String get animation_replay {
    return Intl.message(
      'Replay from the start',
      name: 'animation_replay',
      desc: '',
      args: [],
    );
  }

  /// `Playback position`
  String get animation_seek {
    return Intl.message(
      'Playback position',
      name: 'animation_seek',
      desc: '',
      args: [],
    );
  }

  /// `{percent}% played`
  String animation_percent_played(int percent) {
    return Intl.message(
      '$percent% played',
      name: 'animation_percent_played',
      desc: '',
      args: [percent],
    );
  }

  /// `Playback speed`
  String get animation_playback_speed {
    return Intl.message(
      'Playback speed',
      name: 'animation_playback_speed',
      desc: '',
      args: [],
    );
  }

  /// `{rate}x`
  String animation_speed_multiplier(String rate) {
    return Intl.message(
      '${rate}x',
      name: 'animation_speed_multiplier',
      desc: '',
      args: [rate],
    );
  }

  /// `Paused — reduce motion is on`
  String get animation_paused_reduced_motion {
    return Intl.message(
      'Paused — reduce motion is on',
      name: 'animation_paused_reduced_motion',
      desc: '',
      args: [],
    );
  }

  /// `Camera access blocked`
  String get scanner_camera_access_blocked {
    return Intl.message(
      'Camera access blocked',
      name: 'scanner_camera_access_blocked',
      desc: '',
      args: [],
    );
  }

  /// `Camera permission required`
  String get scanner_camera_permission_required {
    return Intl.message(
      'Camera permission required',
      name: 'scanner_camera_permission_required',
      desc: '',
      args: [],
    );
  }

  /// `Open Settings to allow camera access for this app.`
  String get scanner_open_settings_hint {
    return Intl.message(
      'Open Settings to allow camera access for this app.',
      name: 'scanner_open_settings_hint',
      desc: '',
      args: [],
    );
  }

  /// `Allow camera access to scan codes.`
  String get scanner_allow_camera_hint {
    return Intl.message(
      'Allow camera access to scan codes.',
      name: 'scanner_allow_camera_hint',
      desc: '',
      args: [],
    );
  }

  /// `Open settings`
  String get scanner_open_settings {
    return Intl.message(
      'Open settings',
      name: 'scanner_open_settings',
      desc: '',
      args: [],
    );
  }

  /// `Grant access`
  String get scanner_grant_access {
    return Intl.message(
      'Grant access',
      name: 'scanner_grant_access',
      desc: '',
      args: [],
    );
  }

  /// `Use this code`
  String get scanner_use_this_code {
    return Intl.message(
      'Use this code',
      name: 'scanner_use_this_code',
      desc: '',
      args: [],
    );
  }

  /// `Turn on the light`
  String get scanner_torch_on {
    return Intl.message(
      'Turn on the light',
      name: 'scanner_torch_on',
      desc: '',
      args: [],
    );
  }

  /// `Turn off the light`
  String get scanner_torch_off {
    return Intl.message(
      'Turn off the light',
      name: 'scanner_torch_off',
      desc: '',
      args: [],
    );
  }

  /// `Switch camera`
  String get scanner_flip_camera {
    return Intl.message(
      'Switch camera',
      name: 'scanner_flip_camera',
      desc: '',
      args: [],
    );
  }

  /// `Zoom`
  String get scanner_zoom {
    return Intl.message('Zoom', name: 'scanner_zoom', desc: '', args: []);
  }

  /// `Point the camera at a code`
  String get scanner_hint {
    return Intl.message(
      'Point the camera at a code',
      name: 'scanner_hint',
      desc: '',
      args: [],
    );
  }

  /// `Camera unavailable`
  String get scanner_camera_failed {
    return Intl.message(
      'Camera unavailable',
      name: 'scanner_camera_failed',
      desc: '',
      args: [],
    );
  }

  /// `The camera could not be started.`
  String get scanner_camera_failed_hint {
    return Intl.message(
      'The camera could not be started.',
      name: 'scanner_camera_failed_hint',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get scanner_retry {
    return Intl.message('Try again', name: 'scanner_retry', desc: '', args: []);
  }

  /// `Scanned code`
  String get scanner_pending_code {
    return Intl.message(
      'Scanned code',
      name: 'scanner_pending_code',
      desc: '',
      args: [],
    );
  }

  /// `(no data)`
  String get scanner_empty_value {
    return Intl.message(
      '(no data)',
      name: 'scanner_empty_value',
      desc: '',
      args: [],
    );
  }

  /// `Not a code this screen accepts`
  String get scanner_rejected {
    return Intl.message(
      'Not a code this screen accepts',
      name: 'scanner_rejected',
      desc: '',
      args: [],
    );
  }

  /// `Scan from an image`
  String get scanner_from_image {
    return Intl.message(
      'Scan from an image',
      name: 'scanner_from_image',
      desc: '',
      args: [],
    );
  }

  /// `No code found in that image`
  String get scanner_image_no_code {
    return Intl.message(
      'No code found in that image',
      name: 'scanner_image_no_code',
      desc: '',
      args: [],
    );
  }

  /// `Scan again`
  String get scanner_scan_again {
    return Intl.message(
      'Scan again',
      name: 'scanner_scan_again',
      desc: '',
      args: [],
    );
  }

  /// `Legal & information`
  String get legal_section_label {
    return Intl.message(
      'Legal & information',
      name: 'legal_section_label',
      desc: '',
      args: [],
    );
  }

  /// `Version {version}`
  String legal_version(String version) {
    return Intl.message(
      'Version $version',
      name: 'legal_version',
      desc: '',
      args: [version],
    );
  }

  /// `Version {version} · Build {build}`
  String legal_version_build(String version, String build) {
    return Intl.message(
      'Version $version · Build $build',
      name: 'legal_version_build',
      desc: '',
      args: [version, build],
    );
  }

  /// `About`
  String get legal_title_about {
    return Intl.message('About', name: 'legal_title_about', desc: '', args: []);
  }

  /// `Privacy Policy`
  String get legal_title_privacy {
    return Intl.message(
      'Privacy Policy',
      name: 'legal_title_privacy',
      desc: '',
      args: [],
    );
  }

  /// `Terms of Service`
  String get legal_title_tos {
    return Intl.message(
      'Terms of Service',
      name: 'legal_title_tos',
      desc: '',
      args: [],
    );
  }

  /// `Open-source Licenses`
  String get legal_title_licenses {
    return Intl.message(
      'Open-source Licenses',
      name: 'legal_title_licenses',
      desc: '',
      args: [],
    );
  }

  /// `End User License Agreement`
  String get legal_title_eula {
    return Intl.message(
      'End User License Agreement',
      name: 'legal_title_eula',
      desc: '',
      args: [],
    );
  }

  /// `Refund & Cancellation`
  String get legal_title_refund {
    return Intl.message(
      'Refund & Cancellation',
      name: 'legal_title_refund',
      desc: '',
      args: [],
    );
  }

  /// `Credits`
  String get legal_title_credits {
    return Intl.message(
      'Credits',
      name: 'legal_title_credits',
      desc: '',
      args: [],
    );
  }

  /// `Contact & Support`
  String get legal_title_contact {
    return Intl.message(
      'Contact & Support',
      name: 'legal_title_contact',
      desc: '',
      args: [],
    );
  }

  /// `{title} is unavailable`
  String legal_page_unavailable(String title) {
    return Intl.message(
      '$title is unavailable',
      name: 'legal_page_unavailable',
      desc: '',
      args: [title],
    );
  }

  /// `Couldn't load {title}`
  String legal_page_load_failed(String title) {
    return Intl.message(
      'Couldn\'t load $title',
      name: 'legal_page_load_failed',
      desc: '',
      args: [title],
    );
  }

  /// `This page is currently disabled.`
  String get legal_page_disabled_body {
    return Intl.message(
      'This page is currently disabled.',
      name: 'legal_page_disabled_body',
      desc: '',
      args: [],
    );
  }

  /// `Check your connection and try again.`
  String get legal_check_connection_body {
    return Intl.message(
      'Check your connection and try again.',
      name: 'legal_check_connection_body',
      desc: '',
      args: [],
    );
  }

  /// `We'll be right back`
  String get maintenance_default_title {
    return Intl.message(
      'We\'ll be right back',
      name: 'maintenance_default_title',
      desc: '',
      args: [],
    );
  }

  /// `The service is temporarily unavailable. Please check back shortly.`
  String get maintenance_default_message {
    return Intl.message(
      'The service is temporarily unavailable. Please check back shortly.',
      name: 'maintenance_default_message',
      desc: '',
      args: [],
    );
  }

  /// `We are performing scheduled maintenance. Please try again later.`
  String get maintenance_scheduled_message {
    return Intl.message(
      'We are performing scheduled maintenance. Please try again later.',
      name: 'maintenance_scheduled_message',
      desc: '',
      args: [],
    );
  }

  /// `any moment now`
  String get maintenance_eta_any_moment {
    return Intl.message(
      'any moment now',
      name: 'maintenance_eta_any_moment',
      desc: '',
      args: [],
    );
  }

  /// `in ~{hours}h {minutes}m`
  String maintenance_eta_hours_minutes(int hours, int minutes) {
    return Intl.message(
      'in ~${hours}h ${minutes}m',
      name: 'maintenance_eta_hours_minutes',
      desc: '',
      args: [hours, minutes],
    );
  }

  /// `in ~{minutes} min`
  String maintenance_eta_minutes(int minutes) {
    return Intl.message(
      'in ~$minutes min',
      name: 'maintenance_eta_minutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `in ~{seconds}s`
  String maintenance_eta_seconds(int seconds) {
    return Intl.message(
      'in ~${seconds}s',
      name: 'maintenance_eta_seconds',
      desc: '',
      args: [seconds],
    );
  }

  /// `Back {eta}`
  String maintenance_back_eta(String eta) {
    return Intl.message(
      'Back $eta',
      name: 'maintenance_back_eta',
      desc: '',
      args: [eta],
    );
  }

  /// `Retry in {seconds}s`
  String maintenance_retry_in_seconds(int seconds) {
    return Intl.message(
      'Retry in ${seconds}s',
      name: 'maintenance_retry_in_seconds',
      desc: '',
      args: [seconds],
    );
  }

  /// `You're offline`
  String get connectivity_offline {
    return Intl.message(
      'You\'re offline',
      name: 'connectivity_offline',
      desc: '',
      args: [],
    );
  }

  /// `You're offline — {count} queued`
  String connectivity_offline_queued(int count) {
    return Intl.message(
      'You\'re offline — $count queued',
      name: 'connectivity_offline_queued',
      desc: '',
      args: [count],
    );
  }

  /// `Back online`
  String get connectivity_back_online {
    return Intl.message(
      'Back online',
      name: 'connectivity_back_online',
      desc: '',
      args: [],
    );
  }

  /// `VPN detected — may impact some features`
  String get connectivity_vpn_warning {
    return Intl.message(
      'VPN detected — may impact some features',
      name: 'connectivity_vpn_warning',
      desc: '',
      args: [],
    );
  }

  /// `VPN must be disabled to continue`
  String get connectivity_vpn_blocked {
    return Intl.message(
      'VPN must be disabled to continue',
      name: 'connectivity_vpn_blocked',
      desc: '',
      args: [],
    );
  }

  /// `Offline`
  String get connectivity_quality_offline {
    return Intl.message(
      'Offline',
      name: 'connectivity_quality_offline',
      desc: '',
      args: [],
    );
  }

  /// `Poor`
  String get connectivity_quality_poor {
    return Intl.message(
      'Poor',
      name: 'connectivity_quality_poor',
      desc: '',
      args: [],
    );
  }

  /// `Fair`
  String get connectivity_quality_fair {
    return Intl.message(
      'Fair',
      name: 'connectivity_quality_fair',
      desc: '',
      args: [],
    );
  }

  /// `Good`
  String get connectivity_quality_good {
    return Intl.message(
      'Good',
      name: 'connectivity_quality_good',
      desc: '',
      args: [],
    );
  }

  /// `Excellent`
  String get connectivity_quality_excellent {
    return Intl.message(
      'Excellent',
      name: 'connectivity_quality_excellent',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get connectivity_quality_unknown {
    return Intl.message(
      'Unknown',
      name: 'connectivity_quality_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Offline`
  String get connectivity_type_offline {
    return Intl.message(
      'Offline',
      name: 'connectivity_type_offline',
      desc: '',
      args: [],
    );
  }

  /// `Wi-Fi`
  String get connectivity_type_wifi {
    return Intl.message(
      'Wi-Fi',
      name: 'connectivity_type_wifi',
      desc: '',
      args: [],
    );
  }

  /// `Ethernet`
  String get connectivity_type_ethernet {
    return Intl.message(
      'Ethernet',
      name: 'connectivity_type_ethernet',
      desc: '',
      args: [],
    );
  }

  /// `Mobile data`
  String get connectivity_type_mobile {
    return Intl.message(
      'Mobile data',
      name: 'connectivity_type_mobile',
      desc: '',
      args: [],
    );
  }

  /// `VPN`
  String get connectivity_type_vpn {
    return Intl.message(
      'VPN',
      name: 'connectivity_type_vpn',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get connectivity_type_other {
    return Intl.message(
      'Other',
      name: 'connectivity_type_other',
      desc: '',
      args: [],
    );
  }

  /// `Color theme`
  String get preferences_app_role_title {
    return Intl.message(
      'Color theme',
      name: 'preferences_app_role_title',
      desc: '',
      args: [],
    );
  }

  /// `Which palette the app wears`
  String get preferences_app_role_subtitle {
    return Intl.message(
      'Which palette the app wears',
      name: 'preferences_app_role_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Switch animation`
  String get preferences_reveal_shape_title {
    return Intl.message(
      'Switch animation',
      name: 'preferences_reveal_shape_title',
      desc: '',
      args: [],
    );
  }

  /// `The shape the reveal takes when the theme changes`
  String get preferences_reveal_shape_subtitle {
    return Intl.message(
      'The shape the reveal takes when the theme changes',
      name: 'preferences_reveal_shape_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Animation direction`
  String get preferences_reveal_direction_title {
    return Intl.message(
      'Animation direction',
      name: 'preferences_reveal_direction_title',
      desc: '',
      args: [],
    );
  }

  /// `Which way that shape moves`
  String get preferences_reveal_direction_subtitle {
    return Intl.message(
      'Which way that shape moves',
      name: 'preferences_reveal_direction_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Color saturation`
  String get preferences_color_saturation_title {
    return Intl.message(
      'Color saturation',
      name: 'preferences_color_saturation_title',
      desc: '',
      args: [],
    );
  }

  /// `How vivid the palette renders`
  String get preferences_color_saturation_subtitle {
    return Intl.message(
      'How vivid the palette renders',
      name: 'preferences_color_saturation_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Muted`
  String get preferences_saturation_muted {
    return Intl.message(
      'Muted',
      name: 'preferences_saturation_muted',
      desc: '',
      args: [],
    );
  }

  /// `Normal`
  String get preferences_saturation_normal {
    return Intl.message(
      'Normal',
      name: 'preferences_saturation_normal',
      desc: '',
      args: [],
    );
  }

  /// `Vibrant`
  String get preferences_saturation_vibrant {
    return Intl.message(
      'Vibrant',
      name: 'preferences_saturation_vibrant',
      desc: '',
      args: [],
    );
  }

  /// `Dynamic color`
  String get preferences_dynamic_color_title {
    return Intl.message(
      'Dynamic color',
      name: 'preferences_dynamic_color_title',
      desc: '',
      args: [],
    );
  }

  /// `Use system accent color (Android 12+).`
  String get preferences_dynamic_color_subtitle {
    return Intl.message(
      'Use system accent color (Android 12+).',
      name: 'preferences_dynamic_color_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Theme`
  String get preferences_theme_title {
    return Intl.message(
      'Theme',
      name: 'preferences_theme_title',
      desc: '',
      args: [],
    );
  }

  /// `Light · Dark · Match system`
  String get preferences_theme_subtitle {
    return Intl.message(
      'Light · Dark · Match system',
      name: 'preferences_theme_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Light`
  String get preferences_theme_light {
    return Intl.message(
      'Light',
      name: 'preferences_theme_light',
      desc: '',
      args: [],
    );
  }

  /// `Dark`
  String get preferences_theme_dark {
    return Intl.message(
      'Dark',
      name: 'preferences_theme_dark',
      desc: '',
      args: [],
    );
  }

  /// `System`
  String get preferences_theme_system {
    return Intl.message(
      'System',
      name: 'preferences_theme_system',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get preferences_language_title {
    return Intl.message(
      'Language',
      name: 'preferences_language_title',
      desc: '',
      args: [],
    );
  }

  /// `App display language`
  String get preferences_language_subtitle {
    return Intl.message(
      'App display language',
      name: 'preferences_language_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Small`
  String get preferences_font_scale_small {
    return Intl.message(
      'Small',
      name: 'preferences_font_scale_small',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get preferences_font_scale_default {
    return Intl.message(
      'Default',
      name: 'preferences_font_scale_default',
      desc: '',
      args: [],
    );
  }

  /// `Large`
  String get preferences_font_scale_large {
    return Intl.message(
      'Large',
      name: 'preferences_font_scale_large',
      desc: '',
      args: [],
    );
  }

  /// `Extra large`
  String get preferences_font_scale_extra_large {
    return Intl.message(
      'Extra large',
      name: 'preferences_font_scale_extra_large',
      desc: '',
      args: [],
    );
  }

  /// `Huge`
  String get preferences_font_scale_huge {
    return Intl.message(
      'Huge',
      name: 'preferences_font_scale_huge',
      desc: '',
      args: [],
    );
  }

  /// `Font size`
  String get preferences_font_size_title {
    return Intl.message(
      'Font size',
      name: 'preferences_font_size_title',
      desc: '',
      args: [],
    );
  }

  /// `Composes with system text scaling`
  String get preferences_font_size_subtitle {
    return Intl.message(
      'Composes with system text scaling',
      name: 'preferences_font_size_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The quick brown fox jumps over the lazy dog.`
  String get preferences_font_preview_sample {
    return Intl.message(
      'The quick brown fox jumps over the lazy dog.',
      name: 'preferences_font_preview_sample',
      desc: '',
      args: [],
    );
  }

  /// `Reset to defaults`
  String get preferences_reset_to_defaults {
    return Intl.message(
      'Reset to defaults',
      name: 'preferences_reset_to_defaults',
      desc: '',
      args: [],
    );
  }

  /// `Reset display preferences?`
  String get preferences_reset_confirm_title {
    return Intl.message(
      'Reset display preferences?',
      name: 'preferences_reset_confirm_title',
      desc: '',
      args: [],
    );
  }

  /// `Theme, saturation, font size, dynamic color, and reveal animation revert to defaults. Language and onboarding state are untouched.`
  String get preferences_reset_confirm_body {
    return Intl.message(
      'Theme, saturation, font size, dynamic color, and reveal animation revert to defaults. Language and onboarding state are untouched.',
      name: 'preferences_reset_confirm_body',
      desc: '',
      args: [],
    );
  }

  /// `Reset`
  String get preferences_reset_action {
    return Intl.message(
      'Reset',
      name: 'preferences_reset_action',
      desc: '',
      args: [],
    );
  }

  /// `Back`
  String get wizard_back {
    return Intl.message('Back', name: 'wizard_back', desc: '', args: []);
  }

  /// `Next`
  String get wizard_next {
    return Intl.message('Next', name: 'wizard_next', desc: '', args: []);
  }

  /// `Submit`
  String get wizard_submit {
    return Intl.message('Submit', name: 'wizard_submit', desc: '', args: []);
  }

  /// `Discard draft?`
  String get wizard_discard_draft_title {
    return Intl.message(
      'Discard draft?',
      name: 'wizard_discard_draft_title',
      desc: '',
      args: [],
    );
  }

  /// `Closing will keep your progress saved so you can pick up later.`
  String get wizard_discard_draft_body {
    return Intl.message(
      'Closing will keep your progress saved so you can pick up later.',
      name: 'wizard_discard_draft_body',
      desc: '',
      args: [],
    );
  }

  /// `Keep draft`
  String get wizard_keep_draft {
    return Intl.message(
      'Keep draft',
      name: 'wizard_keep_draft',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get wizard_discard {
    return Intl.message('Discard', name: 'wizard_discard', desc: '', args: []);
  }

  /// `Today`
  String get date_range_preset_today {
    return Intl.message(
      'Today',
      name: 'date_range_preset_today',
      desc: '',
      args: [],
    );
  }

  /// `Last 7 days`
  String get date_range_preset_last_7_days {
    return Intl.message(
      'Last 7 days',
      name: 'date_range_preset_last_7_days',
      desc: '',
      args: [],
    );
  }

  /// `Last 30 days`
  String get date_range_preset_last_30_days {
    return Intl.message(
      'Last 30 days',
      name: 'date_range_preset_last_30_days',
      desc: '',
      args: [],
    );
  }

  /// `This month`
  String get date_range_preset_this_month {
    return Intl.message(
      'This month',
      name: 'date_range_preset_this_month',
      desc: '',
      args: [],
    );
  }

  /// `Last month`
  String get date_range_preset_last_month {
    return Intl.message(
      'Last month',
      name: 'date_range_preset_last_month',
      desc: '',
      args: [],
    );
  }

  /// `Select range`
  String get date_range_select_range {
    return Intl.message(
      'Select range',
      name: 'date_range_select_range',
      desc: '',
      args: [],
    );
  }

  /// `Select Date Range`
  String get date_range_select_date_range {
    return Intl.message(
      'Select Date Range',
      name: 'date_range_select_date_range',
      desc: '',
      args: [],
    );
  }

  /// `Previous month`
  String get date_picker_previous_month {
    return Intl.message(
      'Previous month',
      name: 'date_picker_previous_month',
      desc: '',
      args: [],
    );
  }

  /// `Next month`
  String get date_picker_next_month {
    return Intl.message(
      'Next month',
      name: 'date_picker_next_month',
      desc: '',
      args: [],
    );
  }

  /// `Previous year`
  String get date_picker_previous_year {
    return Intl.message(
      'Previous year',
      name: 'date_picker_previous_year',
      desc: '',
      args: [],
    );
  }

  /// `Next year`
  String get date_picker_next_year {
    return Intl.message(
      'Next year',
      name: 'date_picker_next_year',
      desc: '',
      args: [],
    );
  }

  /// `Earlier years`
  String get date_picker_previous_years {
    return Intl.message(
      'Earlier years',
      name: 'date_picker_previous_years',
      desc: '',
      args: [],
    );
  }

  /// `Later years`
  String get date_picker_next_years {
    return Intl.message(
      'Later years',
      name: 'date_picker_next_years',
      desc: '',
      args: [],
    );
  }

  /// `Choose month`
  String get date_picker_choose_month {
    return Intl.message(
      'Choose month',
      name: 'date_picker_choose_month',
      desc: '',
      args: [],
    );
  }

  /// `Choose year`
  String get date_picker_choose_year {
    return Intl.message(
      'Choose year',
      name: 'date_picker_choose_year',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get date_picker_today {
    return Intl.message('Today', name: 'date_picker_today', desc: '', args: []);
  }

  /// `Selected`
  String get date_picker_selected {
    return Intl.message(
      'Selected',
      name: 'date_picker_selected',
      desc: '',
      args: [],
    );
  }

  /// `Range start`
  String get date_picker_range_start {
    return Intl.message(
      'Range start',
      name: 'date_picker_range_start',
      desc: '',
      args: [],
    );
  }

  /// `Range end`
  String get date_picker_range_end {
    return Intl.message(
      'Range end',
      name: 'date_picker_range_end',
      desc: '',
      args: [],
    );
  }

  /// `In range`
  String get date_picker_in_range {
    return Intl.message(
      'In range',
      name: 'date_picker_in_range',
      desc: '',
      args: [],
    );
  }

  /// `Unavailable`
  String get date_picker_unavailable {
    return Intl.message(
      'Unavailable',
      name: 'date_picker_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Select a range of at least {days} days`
  String date_picker_min_range_days(int days) {
    return Intl.message(
      'Select a range of at least $days days',
      name: 'date_picker_min_range_days',
      desc: '',
      args: [days],
    );
  }

  /// `Select a range of at most {days} days`
  String date_picker_max_range_days(int days) {
    return Intl.message(
      'Select a range of at most $days days',
      name: 'date_picker_max_range_days',
      desc: '',
      args: [days],
    );
  }

  /// `Hour`
  String get date_picker_hour {
    return Intl.message('Hour', name: 'date_picker_hour', desc: '', args: []);
  }

  /// `Minute`
  String get date_picker_minute {
    return Intl.message(
      'Minute',
      name: 'date_picker_minute',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get date_picker_month {
    return Intl.message('Month', name: 'date_picker_month', desc: '', args: []);
  }

  /// `Day`
  String get date_picker_day {
    return Intl.message('Day', name: 'date_picker_day', desc: '', args: []);
  }

  /// `Year`
  String get date_picker_year {
    return Intl.message('Year', name: 'date_picker_year', desc: '', args: []);
  }

  /// `Second`
  String get date_picker_second {
    return Intl.message(
      'Second',
      name: 'date_picker_second',
      desc: '',
      args: [],
    );
  }

  /// `Select a time range`
  String get date_picker_select_time_range {
    return Intl.message(
      'Select a time range',
      name: 'date_picker_select_time_range',
      desc: '',
      args: [],
    );
  }

  /// `Type a date`
  String get date_picker_type_a_date {
    return Intl.message(
      'Type a date',
      name: 'date_picker_type_a_date',
      desc: '',
      args: [],
    );
  }

  /// `Pick from the calendar`
  String get date_picker_pick_from_calendar {
    return Intl.message(
      'Pick from the calendar',
      name: 'date_picker_pick_from_calendar',
      desc: '',
      args: [],
    );
  }

  /// `AM or PM`
  String get date_picker_period {
    return Intl.message(
      'AM or PM',
      name: 'date_picker_period',
      desc: '',
      args: [],
    );
  }

  /// `Select time`
  String get date_picker_select_time {
    return Intl.message(
      'Select time',
      name: 'date_picker_select_time',
      desc: '',
      args: [],
    );
  }

  /// `Select date and time`
  String get date_picker_select_date_time {
    return Intl.message(
      'Select date and time',
      name: 'date_picker_select_date_time',
      desc: '',
      args: [],
    );
  }

  /// `Select month and year`
  String get date_picker_select_month_year {
    return Intl.message(
      'Select month and year',
      name: 'date_picker_select_month_year',
      desc: '',
      args: [],
    );
  }

  /// `Select year`
  String get date_picker_select_year {
    return Intl.message(
      'Select year',
      name: 'date_picker_select_year',
      desc: '',
      args: [],
    );
  }

  /// `{count} events`
  String date_picker_events(int count) {
    return Intl.message(
      '$count events',
      name: 'date_picker_events',
      desc: '',
      args: [count],
    );
  }

  /// `Close picker`
  String get date_picker_close {
    return Intl.message(
      'Close picker',
      name: 'date_picker_close',
      desc: '',
      args: [],
    );
  }

  /// `Select date`
  String get date_field_select_date {
    return Intl.message(
      'Select date',
      name: 'date_field_select_date',
      desc: '',
      args: [],
    );
  }

  /// `Help center`
  String get faq_help_center {
    return Intl.message(
      'Help center',
      name: 'faq_help_center',
      desc: '',
      args: [],
    );
  }

  /// `Search help…`
  String get faq_search_hint {
    return Intl.message(
      'Search help…',
      name: 'faq_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `No matching answers`
  String get faq_no_matching_answers {
    return Intl.message(
      'No matching answers',
      name: 'faq_no_matching_answers',
      desc: '',
      args: [],
    );
  }

  /// `Was this helpful?`
  String get faq_was_this_helpful {
    return Intl.message(
      'Was this helpful?',
      name: 'faq_was_this_helpful',
      desc: '',
      args: [],
    );
  }

  /// `Marked helpful`
  String get faq_marked_helpful {
    return Intl.message(
      'Marked helpful',
      name: 'faq_marked_helpful',
      desc: '',
      args: [],
    );
  }

  /// `Feedback recorded`
  String get faq_feedback_recorded {
    return Intl.message(
      'Feedback recorded',
      name: 'faq_feedback_recorded',
      desc: '',
      args: [],
    );
  }

  /// `Helpful`
  String get faq_helpful {
    return Intl.message('Helpful', name: 'faq_helpful', desc: '', args: []);
  }

  /// `Not helpful`
  String get faq_not_helpful {
    return Intl.message(
      'Not helpful',
      name: 'faq_not_helpful',
      desc: '',
      args: [],
    );
  }

  /// `Failed to load help center`
  String get faq_load_failed {
    return Intl.message(
      'Failed to load help center',
      name: 'faq_load_failed',
      desc: '',
      args: [],
    );
  }

  /// `No help articles yet`
  String get faq_no_articles_yet {
    return Intl.message(
      'No help articles yet',
      name: 'faq_no_articles_yet',
      desc: '',
      args: [],
    );
  }

  /// `Thanks — you marked this helpful`
  String get faq_thanks_marked_helpful {
    return Intl.message(
      'Thanks — you marked this helpful',
      name: 'faq_thanks_marked_helpful',
      desc: '',
      args: [],
    );
  }

  /// `Thanks — feedback recorded`
  String get faq_thanks_feedback_recorded {
    return Intl.message(
      'Thanks — feedback recorded',
      name: 'faq_thanks_feedback_recorded',
      desc: '',
      args: [],
    );
  }

  /// `This feature`
  String get coming_soon_this_feature {
    return Intl.message(
      'This feature',
      name: 'coming_soon_this_feature',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon`
  String get coming_soon_title {
    return Intl.message(
      'Coming soon',
      name: 'coming_soon_title',
      desc: '',
      args: [],
    );
  }

  /// `{feature} is on the way`
  String coming_soon_feature_on_the_way(String feature) {
    return Intl.message(
      '$feature is on the way',
      name: 'coming_soon_feature_on_the_way',
      desc: '',
      args: [feature],
    );
  }

  /// `We're working on it. Want a heads-up the moment it lands?`
  String get coming_soon_body {
    return Intl.message(
      'We\'re working on it. Want a heads-up the moment it lands?',
      name: 'coming_soon_body',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email`
  String get coming_soon_enter_email {
    return Intl.message(
      'Enter your email',
      name: 'coming_soon_enter_email',
      desc: '',
      args: [],
    );
  }

  /// `That email doesn't look right`
  String get coming_soon_email_invalid {
    return Intl.message(
      'That email doesn\'t look right',
      name: 'coming_soon_email_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Notify me`
  String get coming_soon_notify_me {
    return Intl.message(
      'Notify me',
      name: 'coming_soon_notify_me',
      desc: '',
      args: [],
    );
  }

  /// `You're on the list`
  String get coming_soon_success_title {
    return Intl.message(
      'You\'re on the list',
      name: 'coming_soon_success_title',
      desc: '',
      args: [],
    );
  }

  /// `We'll email {email} when it ships.`
  String coming_soon_success_body(String email) {
    return Intl.message(
      'We\'ll email $email when it ships.',
      name: 'coming_soon_success_body',
      desc: '',
      args: [email],
    );
  }

  /// `Back to home`
  String get nav_back_to_home {
    return Intl.message(
      'Back to home',
      name: 'nav_back_to_home',
      desc: '',
      args: [],
    );
  }

  /// `The page you're looking for doesn't exist or has moved.`
  String get nav_page_not_found_body {
    return Intl.message(
      'The page you\'re looking for doesn\'t exist or has moved.',
      name: 'nav_page_not_found_body',
      desc: '',
      args: [],
    );
  }

  /// `Go back`
  String get nav_go_back {
    return Intl.message('Go back', name: 'nav_go_back', desc: '', args: []);
  }

  /// `Tab {index} of {total}`
  String nav_tab_position(int index, int total) {
    return Intl.message(
      'Tab $index of $total',
      name: 'nav_tab_position',
      desc: '',
      args: [index, total],
    );
  }

  /// `Breadcrumbs`
  String get nav_breadcrumbs {
    return Intl.message(
      'Breadcrumbs',
      name: 'nav_breadcrumbs',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{1 more step} other{{count} more steps}}`
  String nav_breadcrumbs_hidden(int count) {
    return Intl.plural(
      count,
      one: '1 more step',
      other: '$count more steps',
      name: 'nav_breadcrumbs_hidden',
      desc: '',
      args: [count],
    );
  }

  /// `Copy URL`
  String get nav_copy_url {
    return Intl.message('Copy URL', name: 'nav_copy_url', desc: '', args: []);
  }

  /// `Path copied — done`
  String get nav_path_copied {
    return Intl.message(
      'Path copied — done',
      name: 'nav_path_copied',
      desc: '',
      args: [],
    );
  }

  /// `Diagnostics copied to clipboard`
  String get error_diagnostics_copied {
    return Intl.message(
      'Diagnostics copied to clipboard',
      name: 'error_diagnostics_copied',
      desc: '',
      args: [],
    );
  }

  /// `No email app available`
  String get error_no_email_app {
    return Intl.message(
      'No email app available',
      name: 'error_no_email_app',
      desc: '',
      args: [],
    );
  }

  /// `We hit an unexpected error. You can try again — if it keeps happening, send us the diagnostics so we can fix it.`
  String get error_default_message {
    return Intl.message(
      'We hit an unexpected error. You can try again — if it keeps happening, send us the diagnostics so we can fix it.',
      name: 'error_default_message',
      desc: '',
      args: [],
    );
  }

  /// `Report sent — thanks`
  String get error_report_sent {
    return Intl.message(
      'Report sent — thanks',
      name: 'error_report_sent',
      desc: '',
      args: [],
    );
  }

  /// `Report this`
  String get error_report_this {
    return Intl.message(
      'Report this',
      name: 'error_report_this',
      desc: '',
      args: [],
    );
  }

  /// `Copy diagnostics`
  String get error_copy_diagnostics {
    return Intl.message(
      'Copy diagnostics',
      name: 'error_copy_diagnostics',
      desc: '',
      args: [],
    );
  }

  /// `Email support`
  String get error_email_support {
    return Intl.message(
      'Email support',
      name: 'error_email_support',
      desc: '',
      args: [],
    );
  }

  /// `You're offline. The error may go away once you reconnect.`
  String get error_offline_hint {
    return Intl.message(
      'You\'re offline. The error may go away once you reconnect.',
      name: 'error_offline_hint',
      desc: '',
      args: [],
    );
  }

  /// `This part didn't load`
  String get error_boundary_release_title {
    return Intl.message(
      'This part didn\'t load',
      name: 'error_boundary_release_title',
      desc: '',
      args: [],
    );
  }

  /// `Try again in a moment.`
  String get error_boundary_release_body {
    return Intl.message(
      'Try again in a moment.',
      name: 'error_boundary_release_body',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong`
  String get error_boundary_fallback_title {
    return Intl.message(
      'Something went wrong',
      name: 'error_boundary_fallback_title',
      desc: '',
      args: [],
    );
  }

  /// `File is {size} MB; max {max} MB.`
  String media_file_too_large(String size, String max) {
    return Intl.message(
      'File is $size MB; max $max MB.',
      name: 'media_file_too_large',
      desc: '',
      args: [size, max],
    );
  }

  /// `Only {extensions} allowed.`
  String media_extension_not_allowed(String extensions) {
    return Intl.message(
      'Only $extensions allowed.',
      name: 'media_extension_not_allowed',
      desc: '',
      args: [extensions],
    );
  }

  /// `Image must be at least {side}px on the shortest side.`
  String media_image_too_small(int side) {
    return Intl.message(
      'Image must be at least ${side}px on the shortest side.',
      name: 'media_image_too_small',
      desc: '',
      args: [side],
    );
  }

  /// `Image must be at most {side}px on the longest side.`
  String media_image_too_large(int side) {
    return Intl.message(
      'Image must be at most ${side}px on the longest side.',
      name: 'media_image_too_large',
      desc: '',
      args: [side],
    );
  }

  /// `Aspect ratio {ratio} — expected {expected}.`
  String media_wrong_aspect_ratio(String ratio, String expected) {
    return Intl.message(
      'Aspect ratio $ratio — expected $expected.',
      name: 'media_wrong_aspect_ratio',
      desc: '',
      args: [ratio, expected],
    );
  }

  /// `Photo`
  String get media_photo {
    return Intl.message('Photo', name: 'media_photo', desc: '', args: []);
  }

  /// `Video`
  String get media_video {
    return Intl.message('Video', name: 'media_video', desc: '', args: []);
  }

  /// `File`
  String get media_file {
    return Intl.message('File', name: 'media_file', desc: '', args: []);
  }

  /// `Gallery`
  String get media_gallery {
    return Intl.message('Gallery', name: 'media_gallery', desc: '', args: []);
  }

  /// `Camera`
  String get media_camera {
    return Intl.message('Camera', name: 'media_camera', desc: '', args: []);
  }

  /// `Clipboard`
  String get media_clipboard {
    return Intl.message(
      'Clipboard',
      name: 'media_clipboard',
      desc: '',
      args: [],
    );
  }

  /// `Browse`
  String get media_browse {
    return Intl.message('Browse', name: 'media_browse', desc: '', args: []);
  }

  /// `Record`
  String get media_record {
    return Intl.message('Record', name: 'media_record', desc: '', args: []);
  }

  /// `Image copied to clipboard`
  String get media_image_copied {
    return Intl.message(
      'Image copied to clipboard',
      name: 'media_image_copied',
      desc: '',
      args: [],
    );
  }

  /// `Video copied to clipboard`
  String get media_video_copied {
    return Intl.message(
      'Video copied to clipboard',
      name: 'media_video_copied',
      desc: '',
      args: [],
    );
  }

  /// `File copied to clipboard`
  String get media_file_copied {
    return Intl.message(
      'File copied to clipboard',
      name: 'media_file_copied',
      desc: '',
      args: [],
    );
  }

  /// `Copy failed`
  String get media_copy_failed {
    return Intl.message(
      'Copy failed',
      name: 'media_copy_failed',
      desc: '',
      args: [],
    );
  }

  /// `Copy image to clipboard`
  String get media_copy_image_tooltip {
    return Intl.message(
      'Copy image to clipboard',
      name: 'media_copy_image_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Copy video to clipboard`
  String get media_copy_video_tooltip {
    return Intl.message(
      'Copy video to clipboard',
      name: 'media_copy_video_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Copy file to clipboard`
  String get media_copy_file_tooltip {
    return Intl.message(
      'Copy file to clipboard',
      name: 'media_copy_file_tooltip',
      desc: '',
      args: [],
    );
  }

  /// `Trim video`
  String get media_trim_video {
    return Intl.message(
      'Trim video',
      name: 'media_trim_video',
      desc: '',
      args: [],
    );
  }

  /// `Choose file`
  String get media_choose_file {
    return Intl.message(
      'Choose file',
      name: 'media_choose_file',
      desc: '',
      args: [],
    );
  }

  /// `Add attachment`
  String get media_add_attachment {
    return Intl.message(
      'Add attachment',
      name: 'media_add_attachment',
      desc: '',
      args: [],
    );
  }

  /// `Review`
  String get media_crop_review_title {
    return Intl.message(
      'Review',
      name: 'media_crop_review_title',
      desc: '',
      args: [],
    );
  }

  /// `Tap a tile to crop. Red tiles must be cropped to continue.`
  String get media_crop_review_subtitle {
    return Intl.message(
      'Tap a tile to crop. Red tiles must be cropped to continue.',
      name: 'media_crop_review_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Must crop`
  String get media_must_crop {
    return Intl.message(
      'Must crop',
      name: 'media_must_crop',
      desc: '',
      args: [],
    );
  }

  /// `NEW`
  String get media_new_badge {
    return Intl.message('NEW', name: 'media_new_badge', desc: '', args: []);
  }

  /// `EARLIER`
  String get media_existing_badge {
    return Intl.message(
      'EARLIER',
      name: 'media_existing_badge',
      desc: '',
      args: [],
    );
  }

  /// `Crop`
  String get media_crop_title {
    return Intl.message('Crop', name: 'media_crop_title', desc: '', args: []);
  }

  /// `Clipboard (empty)`
  String get media_clipboard_empty {
    return Intl.message(
      'Clipboard (empty)',
      name: 'media_clipboard_empty',
      desc: '',
      args: [],
    );
  }

  /// `Add a photo`
  String get media_add_photo {
    return Intl.message(
      'Add a photo',
      name: 'media_add_photo',
      desc: '',
      args: [],
    );
  }

  /// `Add a video`
  String get media_add_video {
    return Intl.message(
      'Add a video',
      name: 'media_add_video',
      desc: '',
      args: [],
    );
  }

  /// `Add a file`
  String get media_add_file {
    return Intl.message(
      'Add a file',
      name: 'media_add_file',
      desc: '',
      args: [],
    );
  }

  /// `Item {index} of {total}`
  String media_item_of(int index, int total) {
    return Intl.message(
      'Item $index of $total',
      name: 'media_item_of',
      desc: '',
      args: [index, total],
    );
  }

  /// `Remove`
  String get media_remove_item {
    return Intl.message(
      'Remove',
      name: 'media_remove_item',
      desc: '',
      args: [],
    );
  }

  /// `Download`
  String get media_download_item {
    return Intl.message(
      'Download',
      name: 'media_download_item',
      desc: '',
      args: [],
    );
  }

  /// `Not uploaded yet`
  String get media_new_item {
    return Intl.message(
      'Not uploaded yet',
      name: 'media_new_item',
      desc: '',
      args: [],
    );
  }

  /// `Already uploaded`
  String get media_existing_item {
    return Intl.message(
      'Already uploaded',
      name: 'media_existing_item',
      desc: '',
      args: [],
    );
  }

  /// `Uploading`
  String get media_uploading {
    return Intl.message(
      'Uploading',
      name: 'media_uploading',
      desc: '',
      args: [],
    );
  }

  /// `Drag to reorder`
  String get media_reorder_hint {
    return Intl.message(
      'Drag to reorder',
      name: 'media_reorder_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count} not added — the limit is {max}`
  String media_limit_dropped(int count, int max) {
    return Intl.message(
      '$count not added — the limit is $max',
      name: 'media_limit_dropped',
      desc: '',
      args: [count, max],
    );
  }

  /// `Already added`
  String get media_duplicate_skipped {
    return Intl.message(
      'Already added',
      name: 'media_duplicate_skipped',
      desc: '',
      args: [],
    );
  }

  /// `Preparing…`
  String get media_preparing {
    return Intl.message(
      'Preparing…',
      name: 'media_preparing',
      desc: '',
      args: [],
    );
  }

  /// `Stop uploading`
  String get media_upload_cancel {
    return Intl.message(
      'Stop uploading',
      name: 'media_upload_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Upload stopped`
  String get media_upload_cancelled {
    return Intl.message(
      'Upload stopped',
      name: 'media_upload_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Upload again`
  String get media_upload_retry {
    return Intl.message(
      'Upload again',
      name: 'media_upload_retry',
      desc: '',
      args: [],
    );
  }

  /// `Share`
  String get media_share {
    return Intl.message('Share', name: 'media_share', desc: '', args: []);
  }

  /// `More actions`
  String get media_more_actions {
    return Intl.message(
      'More actions',
      name: 'media_more_actions',
      desc: '',
      args: [],
    );
  }

  /// `Move left`
  String get media_move_left {
    return Intl.message(
      'Move left',
      name: 'media_move_left',
      desc: '',
      args: [],
    );
  }

  /// `Move right`
  String get media_move_right {
    return Intl.message(
      'Move right',
      name: 'media_move_right',
      desc: '',
      args: [],
    );
  }

  /// `Moved to position {index}`
  String media_moved_to(int index) {
    return Intl.message(
      'Moved to position $index',
      name: 'media_moved_to',
      desc: '',
      args: [index],
    );
  }

  /// `Choose from your photos`
  String get media_gallery_subtitle {
    return Intl.message(
      'Choose from your photos',
      name: 'media_gallery_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Take a new photo`
  String get media_camera_subtitle {
    return Intl.message(
      'Take a new photo',
      name: 'media_camera_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Paste what you copied`
  String get media_clipboard_subtitle {
    return Intl.message(
      'Paste what you copied',
      name: 'media_clipboard_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Choose from your files`
  String get media_browse_subtitle {
    return Intl.message(
      'Choose from your files',
      name: 'media_browse_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Cannot preview this — it has not been saved yet`
  String get media_cannot_preview_bytes {
    return Intl.message(
      'Cannot preview this — it has not been saved yet',
      name: 'media_cannot_preview_bytes',
      desc: '',
      args: [],
    );
  }

  /// `Recent`
  String get media_recent {
    return Intl.message('Recent', name: 'media_recent', desc: '', args: []);
  }

  /// `Limit reached`
  String get media_limit_reached {
    return Intl.message(
      'Limit reached',
      name: 'media_limit_reached',
      desc: '',
      args: [],
    );
  }

  /// `Open failed: {message}`
  String media_open_failed(String message) {
    return Intl.message(
      'Open failed: $message',
      name: 'media_open_failed',
      desc: '',
      args: [message],
    );
  }

  /// `URL copied to clipboard`
  String get media_url_copied {
    return Intl.message(
      'URL copied to clipboard',
      name: 'media_url_copied',
      desc: '',
      args: [],
    );
  }

  /// `Play / pause`
  String get media_play_pause {
    return Intl.message(
      'Play / pause',
      name: 'media_play_pause',
      desc: '',
      args: [],
    );
  }

  /// `Resumed at page {page}`
  String pdf_resumed_at_page(int page) {
    return Intl.message(
      'Resumed at page $page',
      name: 'pdf_resumed_at_page',
      desc: '',
      args: [page],
    );
  }

  /// `Start over`
  String get pdf_start_over {
    return Intl.message(
      'Start over',
      name: 'pdf_start_over',
      desc: '',
      args: [],
    );
  }

  /// `Save PDF`
  String get pdf_save_dialog_title {
    return Intl.message(
      'Save PDF',
      name: 'pdf_save_dialog_title',
      desc: '',
      args: [],
    );
  }

  /// `Downloading… {percent}%`
  String pdf_downloading_percent(String percent) {
    return Intl.message(
      'Downloading… $percent%',
      name: 'pdf_downloading_percent',
      desc: '',
      args: [percent],
    );
  }

  /// `Failed to load PDF`
  String get pdf_load_failed {
    return Intl.message(
      'Failed to load PDF',
      name: 'pdf_load_failed',
      desc: '',
      args: [],
    );
  }

  /// `Password required`
  String get pdf_password_required {
    return Intl.message(
      'Password required',
      name: 'pdf_password_required',
      desc: '',
      args: [],
    );
  }

  /// `PDF not found`
  String get pdf_not_found {
    return Intl.message(
      'PDF not found',
      name: 'pdf_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Check the source URL or your connection.`
  String get pdf_load_failed_detail {
    return Intl.message(
      'Check the source URL or your connection.',
      name: 'pdf_load_failed_detail',
      desc: '',
      args: [],
    );
  }

  /// `The document is encrypted. Provide a password to continue.`
  String get pdf_encrypted_detail {
    return Intl.message(
      'The document is encrypted. Provide a password to continue.',
      name: 'pdf_encrypted_detail',
      desc: '',
      args: [],
    );
  }

  /// `The file at this URL returned 404.`
  String get pdf_not_found_detail {
    return Intl.message(
      'The file at this URL returned 404.',
      name: 'pdf_not_found_detail',
      desc: '',
      args: [],
    );
  }

  /// `Rotate 90°`
  String get pdf_rotate_90 {
    return Intl.message(
      'Rotate 90°',
      name: 'pdf_rotate_90',
      desc: '',
      args: [],
    );
  }

  /// `Save as…`
  String get pdf_save_as {
    return Intl.message('Save as…', name: 'pdf_save_as', desc: '', args: []);
  }

  /// `Print`
  String get pdf_print {
    return Intl.message('Print', name: 'pdf_print', desc: '', args: []);
  }

  /// `{count, plural, one{{count} page} other{{count} pages}}`
  String pdf_page_count(int count) {
    return Intl.plural(
      count,
      one: '$count page',
      other: '$count pages',
      name: 'pdf_page_count',
      desc: '',
      args: [count],
    );
  }

  /// `Zoom out`
  String get pdf_zoom_out {
    return Intl.message('Zoom out', name: 'pdf_zoom_out', desc: '', args: []);
  }

  /// `Zoom in`
  String get pdf_zoom_in {
    return Intl.message('Zoom in', name: 'pdf_zoom_in', desc: '', args: []);
  }

  /// `Jump to page`
  String get pdf_jump_to_page {
    return Intl.message(
      'Jump to page',
      name: 'pdf_jump_to_page',
      desc: '',
      args: [],
    );
  }

  /// `Page {page} of {total}`
  String pdf_page_of(int page, int total) {
    return Intl.message(
      'Page $page of $total',
      name: 'pdf_page_of',
      desc: '',
      args: [page, total],
    );
  }

  /// `No bookmarks yet for this document`
  String get pdf_no_bookmarks {
    return Intl.message(
      'No bookmarks yet for this document',
      name: 'pdf_no_bookmarks',
      desc: '',
      args: [],
    );
  }

  /// `Page {page}`
  String pdf_page_number(int page) {
    return Intl.message(
      'Page $page',
      name: 'pdf_page_number',
      desc: '',
      args: [page],
    );
  }

  /// `Remove bookmark`
  String get pdf_remove_bookmark {
    return Intl.message(
      'Remove bookmark',
      name: 'pdf_remove_bookmark',
      desc: '',
      args: [],
    );
  }

  /// `Bookmark page`
  String get pdf_bookmark_page {
    return Intl.message(
      'Bookmark page',
      name: 'pdf_bookmark_page',
      desc: '',
      args: [],
    );
  }

  /// `long-press for list`
  String get pdf_bookmark_list_hint {
    return Intl.message(
      'long-press for list',
      name: 'pdf_bookmark_list_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count} pp`
  String pdf_page_count_short(int count) {
    return Intl.message(
      '$count pp',
      name: 'pdf_page_count_short',
      desc: '',
      args: [count],
    );
  }

  /// `Match {index} of {total}`
  String pdf_match_of(int index, int total) {
    return Intl.message(
      'Match $index of $total',
      name: 'pdf_match_of',
      desc: '',
      args: [index, total],
    );
  }

  /// `No matches`
  String get pdf_no_matches {
    return Intl.message(
      'No matches',
      name: 'pdf_no_matches',
      desc: '',
      args: [],
    );
  }

  /// `Searching`
  String get pdf_searching {
    return Intl.message('Searching', name: 'pdf_searching', desc: '', args: []);
  }

  /// `Open {name}`
  String pdf_open_document(String name) {
    return Intl.message(
      'Open $name',
      name: 'pdf_open_document',
      desc: '',
      args: [name],
    );
  }

  /// `No outline / TOC in this PDF`
  String get pdf_no_outline {
    return Intl.message(
      'No outline / TOC in this PDF',
      name: 'pdf_no_outline',
      desc: '',
      args: [],
    );
  }

  /// `No documents opened yet`
  String get pdf_no_recent_documents {
    return Intl.message(
      'No documents opened yet',
      name: 'pdf_no_recent_documents',
      desc: '',
      args: [],
    );
  }

  /// `Send feedback`
  String get feedback_title {
    return Intl.message(
      'Send feedback',
      name: 'feedback_title',
      desc: '',
      args: [],
    );
  }

  /// `We read everything. Tell us what's up.`
  String get feedback_subtitle {
    return Intl.message(
      'We read everything. Tell us what\'s up.',
      name: 'feedback_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get feedback_type_label {
    return Intl.message(
      'Type',
      name: 'feedback_type_label',
      desc: '',
      args: [],
    );
  }

  /// `Severity`
  String get feedback_severity_label {
    return Intl.message(
      'Severity',
      name: 'feedback_severity_label',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get feedback_description_label {
    return Intl.message(
      'Description',
      name: 'feedback_description_label',
      desc: '',
      args: [],
    );
  }

  /// `What happened? What did you expect?`
  String get feedback_description_hint {
    return Intl.message(
      'What happened? What did you expect?',
      name: 'feedback_description_hint',
      desc: '',
      args: [],
    );
  }

  /// `Description is required`
  String get feedback_description_required {
    return Intl.message(
      'Description is required',
      name: 'feedback_description_required',
      desc: '',
      args: [],
    );
  }

  /// `Steps to reproduce`
  String get feedback_repro_label {
    return Intl.message(
      'Steps to reproduce',
      name: 'feedback_repro_label',
      desc: '',
      args: [],
    );
  }

  /// `1. Open …\n2. Tap …\n3. See …`
  String get feedback_repro_hint {
    return Intl.message(
      '1. Open …\n2. Tap …\n3. See …',
      name: 'feedback_repro_hint',
      desc: '',
      args: [],
    );
  }

  /// `Email (optional)`
  String get feedback_email_label {
    return Intl.message(
      'Email (optional)',
      name: 'feedback_email_label',
      desc: '',
      args: [],
    );
  }

  /// `That email doesn't look right`
  String get feedback_email_invalid {
    return Intl.message(
      'That email doesn\'t look right',
      name: 'feedback_email_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Attachments`
  String get feedback_attachments_label {
    return Intl.message(
      'Attachments',
      name: 'feedback_attachments_label',
      desc: '',
      args: [],
    );
  }

  /// `Diagnostics`
  String get feedback_diagnostics_label {
    return Intl.message(
      'Diagnostics',
      name: 'feedback_diagnostics_label',
      desc: '',
      args: [],
    );
  }

  /// `Device, app version, and recent activity. Helps us reproduce.`
  String get feedback_diagnostics_hint {
    return Intl.message(
      'Device, app version, and recent activity. Helps us reproduce.',
      name: 'feedback_diagnostics_hint',
      desc: '',
      args: [],
    );
  }

  /// `From gallery`
  String get feedback_pick_gallery {
    return Intl.message(
      'From gallery',
      name: 'feedback_pick_gallery',
      desc: '',
      args: [],
    );
  }

  /// `From camera`
  String get feedback_pick_camera {
    return Intl.message(
      'From camera',
      name: 'feedback_pick_camera',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get feedback_submit {
    return Intl.message('Send', name: 'feedback_submit', desc: '', args: []);
  }

  /// `Sending…`
  String get feedback_submitting {
    return Intl.message(
      'Sending…',
      name: 'feedback_submitting',
      desc: '',
      args: [],
    );
  }

  /// `Thanks for the heads-up`
  String get feedback_success_title {
    return Intl.message(
      'Thanks for the heads-up',
      name: 'feedback_success_title',
      desc: '',
      args: [],
    );
  }

  /// `We got it. We'll follow up at your email if you left one.`
  String get feedback_success_body {
    return Intl.message(
      'We got it. We\'ll follow up at your email if you left one.',
      name: 'feedback_success_body',
      desc: '',
      args: [],
    );
  }

  /// `Slow down`
  String get feedback_cooldown_title {
    return Intl.message(
      'Slow down',
      name: 'feedback_cooldown_title',
      desc: '',
      args: [],
    );
  }

  /// `Hold on a moment before sending another.`
  String get feedback_cooldown_hint {
    return Intl.message(
      'Hold on a moment before sending another.',
      name: 'feedback_cooldown_hint',
      desc: '',
      args: [],
    );
  }

  /// `You're offline`
  String get feedback_offline_queued_title {
    return Intl.message(
      'You\'re offline',
      name: 'feedback_offline_queued_title',
      desc: '',
      args: [],
    );
  }

  /// `Saved for later — will send when you reconnect.`
  String get feedback_offline_queued_body {
    return Intl.message(
      'Saved for later — will send when you reconnect.',
      name: 'feedback_offline_queued_body',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't send`
  String get feedback_failure_title {
    return Intl.message(
      'Couldn\'t send',
      name: 'feedback_failure_title',
      desc: '',
      args: [],
    );
  }

  /// `Something blocked the submission. Try again?`
  String get feedback_failure_body {
    return Intl.message(
      'Something blocked the submission. Try again?',
      name: 'feedback_failure_body',
      desc: '',
      args: [],
    );
  }

  /// `Feedback is unavailable.`
  String get feedback_disabled {
    return Intl.message(
      'Feedback is unavailable.',
      name: 'feedback_disabled',
      desc: '',
      args: [],
    );
  }

  /// `Send feedback`
  String get feedback_send_feedback {
    return Intl.message(
      'Send feedback',
      name: 'feedback_send_feedback',
      desc: '',
      args: [],
    );
  }

  /// `Attachment too large after compression`
  String get feedback_attachment_too_large {
    return Intl.message(
      'Attachment too large after compression',
      name: 'feedback_attachment_too_large',
      desc: '',
      args: [],
    );
  }

  /// `Bug`
  String get feedback_type_bug {
    return Intl.message('Bug', name: 'feedback_type_bug', desc: '', args: []);
  }

  /// `Something is broken or wrong`
  String get feedback_type_bug_subtitle {
    return Intl.message(
      'Something is broken or wrong',
      name: 'feedback_type_bug_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Suggestion`
  String get feedback_type_suggestion {
    return Intl.message(
      'Suggestion',
      name: 'feedback_type_suggestion',
      desc: '',
      args: [],
    );
  }

  /// `Idea for an improvement`
  String get feedback_type_suggestion_subtitle {
    return Intl.message(
      'Idea for an improvement',
      name: 'feedback_type_suggestion_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Question`
  String get feedback_type_question {
    return Intl.message(
      'Question',
      name: 'feedback_type_question',
      desc: '',
      args: [],
    );
  }

  /// `Need help figuring something out`
  String get feedback_type_question_subtitle {
    return Intl.message(
      'Need help figuring something out',
      name: 'feedback_type_question_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get feedback_type_other {
    return Intl.message(
      'Other',
      name: 'feedback_type_other',
      desc: '',
      args: [],
    );
  }

  /// `Anything else`
  String get feedback_type_other_subtitle {
    return Intl.message(
      'Anything else',
      name: 'feedback_type_other_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Low`
  String get feedback_severity_low {
    return Intl.message(
      'Low',
      name: 'feedback_severity_low',
      desc: '',
      args: [],
    );
  }

  /// `Minor — easy workaround`
  String get feedback_severity_low_subtitle {
    return Intl.message(
      'Minor — easy workaround',
      name: 'feedback_severity_low_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Medium`
  String get feedback_severity_medium {
    return Intl.message(
      'Medium',
      name: 'feedback_severity_medium',
      desc: '',
      args: [],
    );
  }

  /// `Affects normal flow`
  String get feedback_severity_medium_subtitle {
    return Intl.message(
      'Affects normal flow',
      name: 'feedback_severity_medium_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `High`
  String get feedback_severity_high {
    return Intl.message(
      'High',
      name: 'feedback_severity_high',
      desc: '',
      args: [],
    );
  }

  /// `Hard to work around`
  String get feedback_severity_high_subtitle {
    return Intl.message(
      'Hard to work around',
      name: 'feedback_severity_high_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Blocking`
  String get feedback_severity_blocking {
    return Intl.message(
      'Blocking',
      name: 'feedback_severity_blocking',
      desc: '',
      args: [],
    );
  }

  /// `Cannot use the app`
  String get feedback_severity_blocking_subtitle {
    return Intl.message(
      'Cannot use the app',
      name: 'feedback_severity_blocking_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No email app available`
  String get feedback_error_no_email_app {
    return Intl.message(
      'No email app available',
      name: 'feedback_error_no_email_app',
      desc: '',
      args: [],
    );
  }

  /// `Failed to open email: {error}`
  String feedback_error_email_open_failed(String error) {
    return Intl.message(
      'Failed to open email: $error',
      name: 'feedback_error_email_open_failed',
      desc: '',
      args: [error],
    );
  }

  /// `No feedback endpoint configured`
  String get feedback_error_no_endpoint {
    return Intl.message(
      'No feedback endpoint configured',
      name: 'feedback_error_no_endpoint',
      desc: '',
      args: [],
    );
  }

  /// `Update required`
  String get update_hard_title {
    return Intl.message(
      'Update required',
      name: 'update_hard_title',
      desc: '',
      args: [],
    );
  }

  /// `You're running an older version. Update to keep using the app.`
  String get update_hard_message {
    return Intl.message(
      'You\'re running an older version. Update to keep using the app.',
      name: 'update_hard_message',
      desc: '',
      args: [],
    );
  }

  /// `Update now`
  String get update_hard_button {
    return Intl.message(
      'Update now',
      name: 'update_hard_button',
      desc: '',
      args: [],
    );
  }

  /// `New version available`
  String get update_soft_title {
    return Intl.message(
      'New version available',
      name: 'update_soft_title',
      desc: '',
      args: [],
    );
  }

  /// `A newer version is ready. Update for the latest improvements.`
  String get update_soft_message {
    return Intl.message(
      'A newer version is ready. Update for the latest improvements.',
      name: 'update_soft_message',
      desc: '',
      args: [],
    );
  }

  /// `Update`
  String get update_soft_update_button {
    return Intl.message(
      'Update',
      name: 'update_soft_update_button',
      desc: '',
      args: [],
    );
  }

  /// `Maybe later`
  String get update_soft_later_button {
    return Intl.message(
      'Maybe later',
      name: 'update_soft_later_button',
      desc: '',
      args: [],
    );
  }

  /// `Skip this version`
  String get update_soft_skip_button {
    return Intl.message(
      'Skip this version',
      name: 'update_soft_skip_button',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get update_version_label {
    return Intl.message(
      'Version',
      name: 'update_version_label',
      desc: '',
      args: [],
    );
  }

  /// `Update unavailable`
  String get update_unavailable_title {
    return Intl.message(
      'Update unavailable',
      name: 'update_unavailable_title',
      desc: '',
      args: [],
    );
  }

  /// `We can't open the store right now. Try again from your home screen.`
  String get update_unavailable_message {
    return Intl.message(
      'We can\'t open the store right now. Try again from your home screen.',
      name: 'update_unavailable_message',
      desc: '',
      args: [],
    );
  }

  /// `Skip`
  String get onboarding_skip {
    return Intl.message('Skip', name: 'onboarding_skip', desc: '', args: []);
  }

  /// `Next`
  String get onboarding_next {
    return Intl.message('Next', name: 'onboarding_next', desc: '', args: []);
  }

  /// `Back`
  String get onboarding_back {
    return Intl.message('Back', name: 'onboarding_back', desc: '', args: []);
  }

  /// `Let's start`
  String get onboarding_get_started {
    return Intl.message(
      'Let\'s start',
      name: 'onboarding_get_started',
      desc: '',
      args: [],
    );
  }

  /// `Allow`
  String get onboarding_allow {
    return Intl.message('Allow', name: 'onboarding_allow', desc: '', args: []);
  }

  /// `Not now`
  String get onboarding_not_now {
    return Intl.message(
      'Not now',
      name: 'onboarding_not_now',
      desc: '',
      args: [],
    );
  }

  /// `You can change this later in Settings.`
  String get onboarding_permission_denied_hint {
    return Intl.message(
      'You can change this later in Settings.',
      name: 'onboarding_permission_denied_hint',
      desc: '',
      args: [],
    );
  }

  /// `Make your piece by hand`
  String get onboarding_make_title {
    return Intl.message(
      'Make your piece by hand',
      name: 'onboarding_make_title',
      desc: '',
      args: [],
    );
  }

  /// `Pick a workshop, sit with the instructor, and shape or paint a clay piece that is yours.`
  String get onboarding_make_body {
    return Intl.message(
      'Pick a workshop, sit with the instructor, and shape or paint a clay piece that is yours.',
      name: 'onboarding_make_body',
      desc: '',
      args: [],
    );
  }

  /// `The workshop experience`
  String get onboarding_workshop_title {
    return Intl.message(
      'The workshop experience',
      name: 'onboarding_workshop_title',
      desc: '',
      args: [],
    );
  }

  /// `Hands-on sessions led by instructors. Shape or paint your piece, step by step, inside the studio.`
  String get onboarding_workshop_body {
    return Intl.message(
      'Hands-on sessions led by instructors. Shape or paint your piece, step by step, inside the studio.',
      name: 'onboarding_workshop_body',
      desc: '',
      args: [],
    );
  }

  /// `Follow your order, step by step`
  String get onboarding_track_title {
    return Intl.message(
      'Follow your order, step by step',
      name: 'onboarding_track_title',
      desc: '',
      args: [],
    );
  }

  /// `From the kiln, to ready, to your front door — a notification reaches you at every change.`
  String get onboarding_track_body {
    return Intl.message(
      'From the kiln, to ready, to your front door — a notification reaches you at every change.',
      name: 'onboarding_track_body',
      desc: '',
      args: [],
    );
  }

  /// `Orders & Transactions`
  String get notifications_channel_transactional_name {
    return Intl.message(
      'Orders & Transactions',
      name: 'notifications_channel_transactional_name',
      desc: '',
      args: [],
    );
  }

  /// `Order updates, receipts, delivery notifications.`
  String get notifications_channel_transactional_description {
    return Intl.message(
      'Order updates, receipts, delivery notifications.',
      name: 'notifications_channel_transactional_description',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get notifications_channel_messages_name {
    return Intl.message(
      'Messages',
      name: 'notifications_channel_messages_name',
      desc: '',
      args: [],
    );
  }

  /// `Direct messages, mentions, chat notifications.`
  String get notifications_channel_messages_description {
    return Intl.message(
      'Direct messages, mentions, chat notifications.',
      name: 'notifications_channel_messages_description',
      desc: '',
      args: [],
    );
  }

  /// `Promotions`
  String get notifications_channel_promo_name {
    return Intl.message(
      'Promotions',
      name: 'notifications_channel_promo_name',
      desc: '',
      args: [],
    );
  }

  /// `Marketing, promotions, and special offers.`
  String get notifications_channel_promo_description {
    return Intl.message(
      'Marketing, promotions, and special offers.',
      name: 'notifications_channel_promo_description',
      desc: '',
      args: [],
    );
  }

  /// `System & Security`
  String get notifications_channel_system_name {
    return Intl.message(
      'System & Security',
      name: 'notifications_channel_system_name',
      desc: '',
      args: [],
    );
  }

  /// `App updates, security alerts, critical messages.`
  String get notifications_channel_system_description {
    return Intl.message(
      'App updates, security alerts, critical messages.',
      name: 'notifications_channel_system_description',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get notifications_channel_general_name {
    return Intl.message(
      'General',
      name: 'notifications_channel_general_name',
      desc: '',
      args: [],
    );
  }

  /// `Miscellaneous notifications.`
  String get notifications_channel_general_description {
    return Intl.message(
      'Miscellaneous notifications.',
      name: 'notifications_channel_general_description',
      desc: '',
      args: [],
    );
  }

  /// `Form is invalid`
  String get validator_form_invalid {
    return Intl.message(
      'Form is invalid',
      name: 'validator_form_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Your name`
  String get field_hint_name {
    return Intl.message(
      'Your name',
      name: 'field_hint_name',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get field_label_email {
    return Intl.message('Email', name: 'field_label_email', desc: '', args: []);
  }

  /// `Password`
  String get field_label_password {
    return Intl.message(
      'Password',
      name: 'field_label_password',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password`
  String get field_label_confirm_password {
    return Intl.message(
      'Confirm password',
      name: 'field_label_confirm_password',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get field_label_phone {
    return Intl.message('Phone', name: 'field_label_phone', desc: '', args: []);
  }

  /// `Name`
  String get field_label_name {
    return Intl.message('Name', name: 'field_label_name', desc: '', args: []);
  }

  /// `Username`
  String get field_label_username {
    return Intl.message(
      'Username',
      name: 'field_label_username',
      desc: '',
      args: [],
    );
  }

  /// `URL`
  String get field_label_url {
    return Intl.message('URL', name: 'field_label_url', desc: '', args: []);
  }

  /// `Code`
  String get field_label_code {
    return Intl.message('Code', name: 'field_label_code', desc: '', args: []);
  }

  /// `Number`
  String get field_label_number {
    return Intl.message(
      'Number',
      name: 'field_label_number',
      desc: '',
      args: [],
    );
  }

  /// `Welcome back`
  String get auth_login_title {
    return Intl.message(
      'Welcome back',
      name: 'auth_login_title',
      desc: '',
      args: [],
    );
  }

  /// `See every available workshop and book the slot that suits you.`
  String get auth_login_subtitle {
    return Intl.message(
      'See every available workshop and book the slot that suits you.',
      name: 'auth_login_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account?`
  String get auth_no_account_prompt {
    return Intl.message(
      'Don\'t have an account?',
      name: 'auth_no_account_prompt',
      desc: '',
      args: [],
    );
  }

  /// `Create one`
  String get auth_create_account {
    return Intl.message(
      'Create one',
      name: 'auth_create_account',
      desc: '',
      args: [],
    );
  }

  /// `Welcome to Terracotta`
  String get auth_register_title {
    return Intl.message(
      'Welcome to Terracotta',
      name: 'auth_register_title',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get auth_have_account_prompt {
    return Intl.message(
      'Already have an account?',
      name: 'auth_have_account_prompt',
      desc: '',
      args: [],
    );
  }

  /// `Enter the code`
  String get auth_otp_title {
    return Intl.message(
      'Enter the code',
      name: 'auth_otp_title',
      desc: '',
      args: [],
    );
  }

  /// `Resend code`
  String get auth_otp_resend {
    return Intl.message(
      'Resend code',
      name: 'auth_otp_resend',
      desc: '',
      args: [],
    );
  }

  /// `Verify`
  String get auth_verify {
    return Intl.message('Verify', name: 'auth_verify', desc: '', args: []);
  }

  /// `Your account is ready`
  String get auth_register_success_title {
    return Intl.message(
      'Your account is ready',
      name: 'auth_register_success_title',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get auth_continue {
    return Intl.message('Continue', name: 'auth_continue', desc: '', args: []);
  }

  /// `Enter your phone number`
  String get auth_forgot_title {
    return Intl.message(
      'Enter your phone number',
      name: 'auth_forgot_title',
      desc: '',
      args: [],
    );
  }

  /// `We'll send you a code to reset your password.`
  String get auth_forgot_subtitle {
    return Intl.message(
      'We\'ll send you a code to reset your password.',
      name: 'auth_forgot_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Send code`
  String get auth_send_code {
    return Intl.message(
      'Send code',
      name: 'auth_send_code',
      desc: '',
      args: [],
    );
  }

  /// `Change your password`
  String get auth_reset_title {
    return Intl.message(
      'Change your password',
      name: 'auth_reset_title',
      desc: '',
      args: [],
    );
  }

  /// `New password`
  String get auth_new_password {
    return Intl.message(
      'New password',
      name: 'auth_new_password',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get auth_change {
    return Intl.message('Change', name: 'auth_change', desc: '', args: []);
  }

  /// `Something went wrong. Please try again.`
  String get auth_error_generic {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'auth_error_generic',
      desc: '',
      args: [],
    );
  }

  /// `We sent a {digits}-digit code to your phone.`
  String auth_otp_subtitle(int digits) {
    return Intl.message(
      'We sent a $digits-digit code to your phone.',
      name: 'auth_otp_subtitle',
      desc: '',
      args: [digits],
    );
  }

  /// `Your verification code`
  String get auth_dev_otp_title {
    return Intl.message(
      'Your verification code',
      name: 'auth_dev_otp_title',
      desc: '',
      args: [],
    );
  }

  /// `Verify your number`
  String get auth_verify_card_title {
    return Intl.message(
      'Verify your number',
      name: 'auth_verify_card_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter the code we sent you to book a workshop or place an order.`
  String get auth_verify_card_body {
    return Intl.message(
      'Enter the code we sent you to book a workshop or place an order.',
      name: 'auth_verify_card_body',
      desc: '',
      args: [],
    );
  }

  /// `Verify now`
  String get auth_verify_card_cta {
    return Intl.message(
      'Verify now',
      name: 'auth_verify_card_cta',
      desc: '',
      args: [],
    );
  }

  /// `Verify your number first`
  String get auth_verify_needed_title {
    return Intl.message(
      'Verify your number first',
      name: 'auth_verify_needed_title',
      desc: '',
      args: [],
    );
  }

  /// `Verify now`
  String get auth_verify_needed_confirm {
    return Intl.message(
      'Verify now',
      name: 'auth_verify_needed_confirm',
      desc: '',
      args: [],
    );
  }

  /// `We sent you a new code`
  String get auth_verify_sent {
    return Intl.message(
      'We sent you a new code',
      name: 'auth_verify_sent',
      desc: '',
      args: [],
    );
  }

  /// `Booking a workshop needs a verified number. It takes a moment.`
  String get auth_verify_needed_book {
    return Intl.message(
      'Booking a workshop needs a verified number. It takes a moment.',
      name: 'auth_verify_needed_book',
      desc: '',
      args: [],
    );
  }

  /// `Placing an order needs a verified number. It takes a moment.`
  String get auth_verify_needed_buy {
    return Intl.message(
      'Placing an order needs a verified number. It takes a moment.',
      name: 'auth_verify_needed_buy',
      desc: '',
      args: [],
    );
  }

  /// `Resend code {timer}`
  String auth_otp_resend_timer(String timer) {
    return Intl.message(
      'Resend code $timer',
      name: 'auth_otp_resend_timer',
      desc: '',
      args: [timer],
    );
  }

  /// `Confirm password`
  String get auth_confirm_password {
    return Intl.message(
      'Confirm password',
      name: 'auth_confirm_password',
      desc: '',
      args: [],
    );
  }

  /// `Full name`
  String get auth_full_name {
    return Intl.message(
      'Full name',
      name: 'auth_full_name',
      desc: '',
      args: [],
    );
  }

  /// `I agree to the Terms and Privacy Policy`
  String get auth_policy_agree {
    return Intl.message(
      'I agree to the Terms and Privacy Policy',
      name: 'auth_policy_agree',
      desc: '',
      args: [],
    );
  }

  /// `You must accept the terms to continue`
  String get auth_policy_required {
    return Intl.message(
      'You must accept the terms to continue',
      name: 'auth_policy_required',
      desc: '',
      args: [],
    );
  }

  /// `Every workshop sets its own deadline for cancelling or rescheduling. You will see yours on the booking itself.`
  String get auth_register_success_body {
    return Intl.message(
      'Every workshop sets its own deadline for cancelling or rescheduling. You will see yours on the booking itself.',
      name: 'auth_register_success_body',
      desc: '',
      args: [],
    );
  }

  /// `Good evening, {name}`
  String home_greeting(String name) {
    return Intl.message(
      'Good evening, $name',
      name: 'home_greeting',
      desc: '',
      args: [name],
    );
  }

  /// `Gallery`
  String get nav_tab_gallery {
    return Intl.message('Gallery', name: 'nav_tab_gallery', desc: '', args: []);
  }

  /// `Workshops`
  String get nav_tab_workshops {
    return Intl.message(
      'Workshops',
      name: 'nav_tab_workshops',
      desc: '',
      args: [],
    );
  }

  /// `Shop`
  String get nav_tab_shop {
    return Intl.message('Shop', name: 'nav_tab_shop', desc: '', args: []);
  }

  /// `Profile`
  String get nav_tab_profile {
    return Intl.message('Profile', name: 'nav_tab_profile', desc: '', args: []);
  }

  /// `Awaiting payment`
  String get booking_status_pending_payment {
    return Intl.message(
      'Awaiting payment',
      name: 'booking_status_pending_payment',
      desc: '',
      args: [],
    );
  }

  /// `This session cannot be cancelled`
  String get booking_no_cancel_title {
    return Intl.message(
      'This session cannot be cancelled',
      name: 'booking_no_cancel_title',
      desc: '',
      args: [],
    );
  }

  /// `It starts too soon to fall inside the cancellation window. Book it and the seat is yours to keep — you will not be able to cancel or reschedule it afterwards.`
  String get booking_no_cancel_body {
    return Intl.message(
      'It starts too soon to fall inside the cancellation window. Book it and the seat is yours to keep — you will not be able to cancel or reschedule it afterwards.',
      name: 'booking_no_cancel_body',
      desc: '',
      args: [],
    );
  }

  /// `Book it anyway`
  String get booking_no_cancel_confirm {
    return Intl.message(
      'Book it anyway',
      name: 'booking_no_cancel_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel before {when} and the full amount goes back to your Terracotta balance.`
  String booking_cancel_policy(String when) {
    return Intl.message(
      'Cancel before $when and the full amount goes back to your Terracotta balance.',
      name: 'booking_cancel_policy',
      desc: '',
      args: [when],
    );
  }

  /// `This session starts too soon to be cancelled or rescheduled.`
  String get booking_cancel_policy_none {
    return Intl.message(
      'This session starts too soon to be cancelled or rescheduled.',
      name: 'booking_cancel_policy_none',
      desc: '',
      args: [],
    );
  }

  /// `to`
  String get booking_time_to {
    return Intl.message('to', name: 'booking_time_to', desc: '', args: []);
  }

  /// `SAR`
  String get money_currency {
    return Intl.message('SAR', name: 'money_currency', desc: '', args: []);
  }

  /// `Home`
  String get home_title {
    return Intl.message('Home', name: 'home_title', desc: '', args: []);
  }

  /// `Continue your workshop`
  String get home_continue_workshop {
    return Intl.message(
      'Continue your workshop',
      name: 'home_continue_workshop',
      desc: '',
      args: [],
    );
  }

  /// `Your order`
  String get home_live_order {
    return Intl.message(
      'Your order',
      name: 'home_live_order',
      desc: '',
      args: [],
    );
  }

  /// `Happening now`
  String get home_live_workshop {
    return Intl.message(
      'Happening now',
      name: 'home_live_workshop',
      desc: '',
      args: [],
    );
  }

  /// `Arriving {when}`
  String home_live_order_eta(String when) {
    return Intl.message(
      'Arriving $when',
      name: 'home_live_order_eta',
      desc: '',
      args: [when],
    );
  }

  /// `Until {time}`
  String home_live_workshop_until(String time) {
    return Intl.message(
      'Until $time',
      name: 'home_live_workshop_until',
      desc: '',
      args: [time],
    );
  }

  /// `Show my code`
  String get home_live_show_code {
    return Intl.message(
      'Show my code',
      name: 'home_live_show_code',
      desc: '',
      args: [],
    );
  }

  /// `Your next workshop`
  String get home_next_booking {
    return Intl.message(
      'Your next workshop',
      name: 'home_next_booking',
      desc: '',
      args: [],
    );
  }

  /// `{date} · {time}`
  String home_next_booking_when(String date, String time) {
    return Intl.message(
      '$date · $time',
      name: 'home_next_booking_when',
      desc: '',
      args: [date, time],
    );
  }

  /// `{count, plural, =1{1 piece} other{{count} pieces}}`
  String home_live_items(int count) {
    return Intl.plural(
      count,
      one: '1 piece',
      other: '$count pieces',
      name: 'home_live_items',
      desc: '',
      args: [count],
    );
  }

  /// `Featured pieces`
  String get home_featured {
    return Intl.message(
      'Featured pieces',
      name: 'home_featured',
      desc: '',
      args: [],
    );
  }

  /// `Latest offers`
  String get home_offers {
    return Intl.message(
      'Latest offers',
      name: 'home_offers',
      desc: '',
      args: [],
    );
  }

  /// `Browse categories`
  String get home_browse_categories {
    return Intl.message(
      'Browse categories',
      name: 'home_browse_categories',
      desc: '',
      args: [],
    );
  }

  /// `See all`
  String get home_see_all {
    return Intl.message('See all', name: 'home_see_all', desc: '', args: []);
  }

  /// `See all ({count})`
  String home_see_all_count(String count) {
    return Intl.message(
      'See all ($count)',
      name: 'home_see_all_count',
      desc: '',
      args: [count],
    );
  }

  /// `Featured`
  String get home_badge_featured {
    return Intl.message(
      'Featured',
      name: 'home_badge_featured',
      desc: '',
      args: [],
    );
  }

  /// `Terracotta`
  String get page_section_title {
    return Intl.message(
      'Terracotta',
      name: 'page_section_title',
      desc: '',
      args: [],
    );
  }

  /// `Terms and conditions`
  String get page_terms {
    return Intl.message(
      'Terms and conditions',
      name: 'page_terms',
      desc: '',
      args: [],
    );
  }

  /// `Privacy policy`
  String get page_privacy {
    return Intl.message(
      'Privacy policy',
      name: 'page_privacy',
      desc: '',
      args: [],
    );
  }

  /// `Returns and exchanges`
  String get page_returns {
    return Intl.message(
      'Returns and exchanges',
      name: 'page_returns',
      desc: '',
      args: [],
    );
  }

  /// `Shipping and delivery`
  String get page_shipping {
    return Intl.message(
      'Shipping and delivery',
      name: 'page_shipping',
      desc: '',
      args: [],
    );
  }

  /// `About Terracotta`
  String get page_about {
    return Intl.message(
      'About Terracotta',
      name: 'page_about',
      desc: '',
      args: [],
    );
  }

  /// `Nothing here yet`
  String get page_missing {
    return Intl.message(
      'Nothing here yet',
      name: 'page_missing',
      desc: '',
      args: [],
    );
  }

  /// `The studio has not written this page.`
  String get page_missing_body {
    return Intl.message(
      'The studio has not written this page.',
      name: 'page_missing_body',
      desc: '',
      args: [],
    );
  }

  /// `-{percent}%`
  String shop_discount_badge(String percent) {
    return Intl.message(
      '-$percent%',
      name: 'shop_discount_badge',
      desc: 'How much a sale price takes off, on a product card badge.',
      args: [percent],
    );
  }

  /// `Terracotta moments`
  String get gallery_title {
    return Intl.message(
      'Terracotta moments',
      name: 'gallery_title',
      desc: '',
      args: [],
    );
  }

  /// `Pieces made by visitors like you — every picture is clay turning into something real.`
  String get gallery_subtitle {
    return Intl.message(
      'Pieces made by visitors like you — every picture is clay turning into something real.',
      name: 'gallery_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `{photos} photos · {videos} videos`
  String gallery_counts(int photos, int videos) {
    return Intl.message(
      '$photos photos · $videos videos',
      name: 'gallery_counts',
      desc: '',
      args: [photos, videos],
    );
  }

  /// `{photos} photos`
  String gallery_counts_photos(int photos) {
    return Intl.message(
      '$photos photos',
      name: 'gallery_counts_photos',
      desc: '',
      args: [photos],
    );
  }

  /// `{videos} videos`
  String gallery_counts_videos(int videos) {
    return Intl.message(
      '$videos videos',
      name: 'gallery_counts_videos',
      desc: '',
      args: [videos],
    );
  }

  /// `No photos in this album yet`
  String get gallery_album_empty {
    return Intl.message(
      'No photos in this album yet',
      name: 'gallery_album_empty',
      desc: '',
      args: [],
    );
  }

  /// `No albums yet`
  String get gallery_empty {
    return Intl.message(
      'No albums yet',
      name: 'gallery_empty',
      desc: '',
      args: [],
    );
  }

  /// `Terracotta workshops`
  String get workshop_title {
    return Intl.message(
      'Terracotta workshops',
      name: 'workshop_title',
      desc: '',
      args: [],
    );
  }

  /// `The studio`
  String get workshop_studio_location {
    return Intl.message(
      'The studio',
      name: 'workshop_studio_location',
      desc: '',
      args: [],
    );
  }

  /// `Open in Maps`
  String get workshop_open_in_maps {
    return Intl.message(
      'Open in Maps',
      name: 'workshop_open_in_maps',
      desc: '',
      args: [],
    );
  }

  /// `The map opens here once the studio's key is wired.`
  String get workshop_map_pending {
    return Intl.message(
      'The map opens here once the studio\'s key is wired.',
      name: 'workshop_map_pending',
      desc: '',
      args: [],
    );
  }

  /// `The studio has not published a location yet.`
  String get workshop_no_location {
    return Intl.message(
      'The studio has not published a location yet.',
      name: 'workshop_no_location',
      desc: '',
      args: [],
    );
  }

  /// `See every available workshop and book the slot that suits you.`
  String get workshop_subtitle {
    return Intl.message(
      'See every available workshop and book the slot that suits you.',
      name: 'workshop_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `My workshops`
  String get workshop_tab_mine {
    return Intl.message(
      'My workshops',
      name: 'workshop_tab_mine',
      desc: '',
      args: [],
    );
  }

  /// `Book a workshop`
  String get workshop_tab_book {
    return Intl.message(
      'Book a workshop',
      name: 'workshop_tab_book',
      desc: '',
      args: [],
    );
  }

  /// `Book`
  String get workshop_book {
    return Intl.message('Book', name: 'workshop_book', desc: '', args: []);
  }

  /// `Location`
  String get workshop_location {
    return Intl.message(
      'Location',
      name: 'workshop_location',
      desc: '',
      args: [],
    );
  }

  /// `{price} per person`
  String workshop_price_per_person(String price) {
    return Intl.message(
      '$price per person',
      name: 'workshop_price_per_person',
      desc: '',
      args: [price],
    );
  }

  /// `{count} per session`
  String workshop_seats_per_session(String count) {
    return Intl.message(
      '$count per session',
      name: 'workshop_seats_per_session',
      desc: '',
      args: [count],
    );
  }

  /// `1 hour`
  String get workshop_duration_hour {
    return Intl.message(
      '1 hour',
      name: 'workshop_duration_hour',
      desc: '',
      args: [],
    );
  }

  /// `{minutes} min`
  String workshop_duration_minutes(int minutes) {
    return Intl.message(
      '$minutes min',
      name: 'workshop_duration_minutes',
      desc: '',
      args: [minutes],
    );
  }

  /// `Gift`
  String get workshop_gift {
    return Intl.message('Gift', name: 'workshop_gift', desc: '', args: []);
  }

  /// `Terracotta balance`
  String get workshop_wallet_balance {
    return Intl.message(
      'Terracotta balance',
      name: 'workshop_wallet_balance',
      desc: '',
      args: [],
    );
  }

  /// `View transactions`
  String get workshop_view_transactions {
    return Intl.message(
      'View transactions',
      name: 'workshop_view_transactions',
      desc: '',
      args: [],
    );
  }

  /// `Not specified`
  String get workshop_not_specified {
    return Intl.message(
      'Not specified',
      name: 'workshop_not_specified',
      desc: '',
      args: [],
    );
  }

  /// `No workshops available right now`
  String get workshop_empty {
    return Intl.message(
      'No workshops available right now',
      name: 'workshop_empty',
      desc: '',
      args: [],
    );
  }

  /// `Pick a time`
  String get booking_pick_slot {
    return Intl.message(
      'Pick a time',
      name: 'booking_pick_slot',
      desc: '',
      args: [],
    );
  }

  /// `{count} people`
  String booking_people_count(String count) {
    return Intl.message(
      '$count people',
      name: 'booking_people_count',
      desc: '',
      args: [count],
    );
  }

  /// `Session {start} to {end}`
  String booking_session_time(String start, String end) {
    return Intl.message(
      'Session $start to $end',
      name: 'booking_session_time',
      desc: '',
      args: [start, end],
    );
  }

  /// `{left} / {total} seats`
  String booking_seats_left(String left, String total) {
    return Intl.message(
      '$left / $total seats',
      name: 'booking_seats_left',
      desc: '',
      args: [left, total],
    );
  }

  /// `Booking for {count}`
  String booking_for_people(String count) {
    return Intl.message(
      'Booking for $count',
      name: 'booking_for_people',
      desc: '',
      args: [count],
    );
  }

  /// `Pick your pieces`
  String get booking_pick_pieces {
    return Intl.message(
      'Pick your pieces',
      name: 'booking_pick_pieces',
      desc: '',
      args: [],
    );
  }

  /// `Selected pieces {count}`
  String booking_selected_pieces(int count) {
    return Intl.message(
      'Selected pieces $count',
      name: 'booking_selected_pieces',
      desc: '',
      args: [count],
    );
  }

  /// `Choose between {min} and {max} pieces`
  String booking_pieces_range(int min, int max) {
    return Intl.message(
      'Choose between $min and $max pieces',
      name: 'booking_pieces_range',
      desc: '',
      args: [min, max],
    );
  }

  /// `Choose {count} pieces`
  String booking_pieces_exact(int count) {
    return Intl.message(
      'Choose $count pieces',
      name: 'booking_pieces_exact',
      desc: '',
      args: [count],
    );
  }

  /// `Total`
  String get booking_pieces_total {
    return Intl.message(
      'Total',
      name: 'booking_pieces_total',
      desc: '',
      args: [],
    );
  }

  /// `Choose at least {min} pieces`
  String booking_pieces_min_only(int min) {
    return Intl.message(
      'Choose at least $min pieces',
      name: 'booking_pieces_min_only',
      desc: '',
      args: [min],
    );
  }

  /// `This workshop has no pieces yet.`
  String get booking_pieces_empty {
    return Intl.message(
      'This workshop has no pieces yet.',
      name: 'booking_pieces_empty',
      desc: '',
      args: [],
    );
  }

  /// `Piece`
  String get booking_piece_untitled {
    return Intl.message(
      'Piece',
      name: 'booking_piece_untitled',
      desc: '',
      args: [],
    );
  }

  /// `Booked in to paint · {workshop}, {date}`
  String booking_piece_painting_on(Object workshop, Object date) {
    return Intl.message(
      'Booked in to paint · $workshop, $date',
      name: 'booking_piece_painting_on',
      desc: '',
      args: [workshop, date],
    );
  }

  /// `Painted at {workshop}`
  String booking_piece_painted_at(Object workshop) {
    return Intl.message(
      'Painted at $workshop',
      name: 'booking_piece_painted_at',
      desc: '',
      args: [workshop],
    );
  }

  /// `My pieces`
  String get booking_own_pieces {
    return Intl.message(
      'My pieces',
      name: 'booking_own_pieces',
      desc: '',
      args: [],
    );
  }

  /// `Made {date}`
  String booking_own_piece_made_on(String date) {
    return Intl.message(
      'Made $date',
      name: 'booking_own_piece_made_on',
      desc: '',
      args: [date],
    );
  }

  /// `Pieces you made yourself, ready to be painted.`
  String get booking_own_pieces_hint {
    return Intl.message(
      'Pieces you made yourself, ready to be painted.',
      name: 'booking_own_pieces_hint',
      desc: '',
      args: [],
    );
  }

  /// `Your workshop is booked!`
  String get booking_confirmed_title {
    return Intl.message(
      'Your workshop is booked!',
      name: 'booking_confirmed_title',
      desc: '',
      args: [],
    );
  }

  /// `You can cancel or reschedule up to {when}, and the full amount returns to your Terracotta balance.`
  String booking_confirmed_body(String when) {
    return Intl.message(
      'You can cancel or reschedule up to $when, and the full amount returns to your Terracotta balance.',
      name: 'booking_confirmed_body',
      desc: '',
      args: [when],
    );
  }

  /// `Track booking`
  String get booking_track {
    return Intl.message(
      'Track booking',
      name: 'booking_track',
      desc: '',
      args: [],
    );
  }

  /// `Booking confirmed`
  String get booking_detail_confirmed {
    return Intl.message(
      'Booking confirmed',
      name: 'booking_detail_confirmed',
      desc: '',
      args: [],
    );
  }

  /// `Show this code when you arrive — {days} to go.`
  String booking_scan_on_arrival(String days) {
    return Intl.message(
      'Show this code when you arrive — $days to go.',
      name: 'booking_scan_on_arrival',
      desc: '',
      args: [days],
    );
  }

  /// `Scan code`
  String get booking_scan_code {
    return Intl.message(
      'Scan code',
      name: 'booking_scan_code',
      desc: '',
      args: [],
    );
  }

  /// `Show this QR when you arrive to check in.`
  String get booking_qr_instructions {
    return Intl.message(
      'Show this QR when you arrive to check in.',
      name: 'booking_qr_instructions',
      desc: '',
      args: [],
    );
  }

  /// `Edit`
  String get booking_reschedule {
    return Intl.message('Edit', name: 'booking_reschedule', desc: '', args: []);
  }

  /// `Change your time`
  String get booking_reschedule_title {
    return Intl.message(
      'Change your time',
      name: 'booking_reschedule_title',
      desc: '',
      args: [],
    );
  }

  /// `Change`
  String get booking_change {
    return Intl.message('Change', name: 'booking_change', desc: '', args: []);
  }

  /// `Cancel`
  String get booking_cancel {
    return Intl.message('Cancel', name: 'booking_cancel', desc: '', args: []);
  }

  /// `Cancel booking`
  String get booking_cancel_title {
    return Intl.message(
      'Cancel booking',
      name: 'booking_cancel_title',
      desc: '',
      args: [],
    );
  }

  /// `Are you sure you want to cancel this booking?`
  String get booking_cancel_confirm {
    return Intl.message(
      'Are you sure you want to cancel this booking?',
      name: 'booking_cancel_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get booking_yes {
    return Intl.message('Yes', name: 'booking_yes', desc: '', args: []);
  }

  /// `No`
  String get booking_no {
    return Intl.message('No', name: 'booking_no', desc: '', args: []);
  }

  /// `Close`
  String get booking_close {
    return Intl.message('Close', name: 'booking_close', desc: '', args: []);
  }

  /// `With a celebration`
  String get booking_with_celebration {
    return Intl.message(
      'With a celebration',
      name: 'booking_with_celebration',
      desc: '',
      args: [],
    );
  }

  /// `Add a celebration`
  String get booking_add_celebration {
    return Intl.message(
      'Add a celebration',
      name: 'booking_add_celebration',
      desc: '',
      args: [],
    );
  }

  /// `Remove the celebration`
  String get booking_remove_celebration {
    return Intl.message(
      'Remove the celebration',
      name: 'booking_remove_celebration',
      desc: '',
      args: [],
    );
  }

  /// `My bookings`
  String get booking_my_bookings {
    return Intl.message(
      'My bookings',
      name: 'booking_my_bookings',
      desc: '',
      args: [],
    );
  }

  /// `You have no bookings yet`
  String get booking_empty {
    return Intl.message(
      'You have no bookings yet',
      name: 'booking_empty',
      desc: '',
      args: [],
    );
  }

  /// `Full`
  String get booking_slot_full {
    return Intl.message('Full', name: 'booking_slot_full', desc: '', args: []);
  }

  /// `You already have a booking then`
  String get booking_slot_conflict {
    return Intl.message(
      'You already have a booking then',
      name: 'booking_slot_conflict',
      desc: '',
      args: [],
    );
  }

  /// `Payment`
  String get checkout_title {
    return Intl.message('Payment', name: 'checkout_title', desc: '', args: []);
  }

  /// `Confirm and pay`
  String get checkout_confirm_and_pay {
    return Intl.message(
      'Confirm and pay',
      name: 'checkout_confirm_and_pay',
      desc: '',
      args: [],
    );
  }

  /// `Subtotal`
  String get checkout_subtotal {
    return Intl.message(
      'Subtotal',
      name: 'checkout_subtotal',
      desc: '',
      args: [],
    );
  }

  /// `Discount`
  String get checkout_discount {
    return Intl.message(
      'Discount',
      name: 'checkout_discount',
      desc: '',
      args: [],
    );
  }

  /// `Delivery`
  String get checkout_delivery_fee {
    return Intl.message(
      'Delivery',
      name: 'checkout_delivery_fee',
      desc: '',
      args: [],
    );
  }

  /// `VAT included ({rate})`
  String checkout_vat(String rate) {
    return Intl.message(
      'VAT included ($rate)',
      name: 'checkout_vat',
      desc: '',
      args: [rate],
    );
  }

  /// `Total`
  String get checkout_total {
    return Intl.message('Total', name: 'checkout_total', desc: '', args: []);
  }

  /// `Terracotta balance`
  String get checkout_wallet_applied {
    return Intl.message(
      'Terracotta balance',
      name: 'checkout_wallet_applied',
      desc: '',
      args: [],
    );
  }

  /// `Amount due`
  String get checkout_amount_due {
    return Intl.message(
      'Amount due',
      name: 'checkout_amount_due',
      desc: '',
      args: [],
    );
  }

  /// `Already covered by your balance`
  String get checkout_already_settled {
    return Intl.message(
      'Already covered by your balance',
      name: 'checkout_already_settled',
      desc: '',
      args: [],
    );
  }

  /// `Discount code`
  String get checkout_discount_code {
    return Intl.message(
      'Discount code',
      name: 'checkout_discount_code',
      desc: '',
      args: [],
    );
  }

  /// `SAVE10`
  String get checkout_discount_code_hint {
    return Intl.message(
      'SAVE10',
      name: 'checkout_discount_code_hint',
      desc: '',
      args: [],
    );
  }

  /// `Apply`
  String get checkout_apply {
    return Intl.message('Apply', name: 'checkout_apply', desc: '', args: []);
  }

  /// `Free`
  String get checkout_free {
    return Intl.message('Free', name: 'checkout_free', desc: '', args: []);
  }

  /// `{value}% off`
  String checkout_code_off_percent(String value) {
    return Intl.message(
      '$value% off',
      name: 'checkout_code_off_percent',
      desc: '',
      args: [value],
    );
  }

  /// `{amount} off`
  String checkout_code_off_fixed(String amount) {
    return Intl.message(
      '$amount off',
      name: 'checkout_code_off_fixed',
      desc: '',
      args: [amount],
    );
  }

  /// `on orders over {amount}`
  String checkout_code_min_order(String amount) {
    return Intl.message(
      'on orders over $amount',
      name: 'checkout_code_min_order',
      desc: '',
      args: [amount],
    );
  }

  /// `Payment method`
  String get checkout_pay_method {
    return Intl.message(
      'Payment method',
      name: 'checkout_pay_method',
      desc: '',
      args: [],
    );
  }

  /// `You already have an order awaiting payment. Finish or cancel it first.`
  String get checkout_open_order {
    return Intl.message(
      'You already have an order awaiting payment. Finish or cancel it first.',
      name: 'checkout_open_order',
      desc: '',
      args: [],
    );
  }

  /// `View my orders`
  String get checkout_open_order_action {
    return Intl.message(
      'View my orders',
      name: 'checkout_open_order_action',
      desc: '',
      args: [],
    );
  }

  /// `The hold on this order has run out. Please start again.`
  String get checkout_hold_expired {
    return Intl.message(
      'The hold on this order has run out. Please start again.',
      name: 'checkout_hold_expired',
      desc: '',
      args: [],
    );
  }

  /// `Browse {category}`
  String shop_browse_sub_categories(String category) {
    return Intl.message(
      'Browse $category',
      name: 'shop_browse_sub_categories',
      desc: '',
      args: [category],
    );
  }

  /// `Nothing matches that`
  String get shop_no_results {
    return Intl.message(
      'Nothing matches that',
      name: 'shop_no_results',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No results} one{{count} result} other{{count} results}}`
  String shop_results_count(int count) {
    return Intl.plural(
      count,
      zero: 'No results',
      one: '$count result',
      other: '$count results',
      name: 'shop_results_count',
      desc: '',
      args: [count],
    );
  }

  /// `Filters`
  String get shop_filters {
    return Intl.message('Filters', name: 'shop_filters', desc: '', args: []);
  }

  /// `Featured only`
  String get shop_filter_featured {
    return Intl.message(
      'Featured only',
      name: 'shop_filter_featured',
      desc: '',
      args: [],
    );
  }

  /// `On sale`
  String get shop_filter_on_sale {
    return Intl.message(
      'On sale',
      name: 'shop_filter_on_sale',
      desc: '',
      args: [],
    );
  }

  /// `Show results`
  String get shop_filter_apply {
    return Intl.message(
      'Show results',
      name: 'shop_filter_apply',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get shop_filter_clear {
    return Intl.message('Clear', name: 'shop_filter_clear', desc: '', args: []);
  }

  /// `Terracotta shop`
  String get shop_title {
    return Intl.message(
      'Terracotta shop',
      name: 'shop_title',
      desc: '',
      args: [],
    );
  }

  /// `Handmade pieces, ready to take home.`
  String get shop_subtitle {
    return Intl.message(
      'Handmade pieces, ready to take home.',
      name: 'shop_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Raw materials and tools`
  String get shop_materials {
    return Intl.message(
      'Raw materials and tools',
      name: 'shop_materials',
      desc: '',
      args: [],
    );
  }

  /// `Clay, glazes and the tools the studio works with`
  String get shop_materials_subtitle {
    return Intl.message(
      'Clay, glazes and the tools the studio works with',
      name: 'shop_materials_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Shop materials`
  String get shop_materials_cta {
    return Intl.message(
      'Shop materials',
      name: 'shop_materials_cta',
      desc: '',
      args: [],
    );
  }

  /// `Materials go in the same basket as everything else.`
  String get shop_materials_one_basket {
    return Intl.message(
      'Materials go in the same basket as everything else.',
      name: 'shop_materials_one_basket',
      desc: '',
      args: [],
    );
  }

  /// `Search...`
  String get shop_search_hint {
    return Intl.message(
      'Search...',
      name: 'shop_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `My cart`
  String get shop_my_cart {
    return Intl.message('My cart', name: 'shop_my_cart', desc: '', args: []);
  }

  /// `My favourites`
  String get shop_my_favorites {
    return Intl.message(
      'My favourites',
      name: 'shop_my_favorites',
      desc: '',
      args: [],
    );
  }

  /// `My orders`
  String get shop_my_orders {
    return Intl.message(
      'My orders',
      name: 'shop_my_orders',
      desc: '',
      args: [],
    );
  }

  /// `Browse {category}`
  String shop_browse_category(String category) {
    return Intl.message(
      'Browse $category',
      name: 'shop_browse_category',
      desc: '',
      args: [category],
    );
  }

  /// `You may also like`
  String get shop_you_may_like {
    return Intl.message(
      'You may also like',
      name: 'shop_you_may_like',
      desc: '',
      args: [],
    );
  }

  /// `Category`
  String get shop_category {
    return Intl.message('Category', name: 'shop_category', desc: '', args: []);
  }

  /// `Colour`
  String get shop_colour {
    return Intl.message('Colour', name: 'shop_colour', desc: '', args: []);
  }

  /// `Size`
  String get shop_size {
    return Intl.message('Size', name: 'shop_size', desc: '', args: []);
  }

  /// `Add`
  String get shop_add_to_cart {
    return Intl.message('Add', name: 'shop_add_to_cart', desc: '', args: []);
  }

  /// `Qty {count}`
  String shop_quantity(String count) {
    return Intl.message(
      'Qty $count',
      name: 'shop_quantity',
      desc: '',
      args: [count],
    );
  }

  /// `Filter`
  String get shop_filter {
    return Intl.message('Filter', name: 'shop_filter', desc: '', args: []);
  }

  /// `Nothing here yet`
  String get shop_empty {
    return Intl.message(
      'Nothing here yet',
      name: 'shop_empty',
      desc: '',
      args: [],
    );
  }

  /// `No favourites yet`
  String get shop_favorites_empty {
    return Intl.message(
      'No favourites yet',
      name: 'shop_favorites_empty',
      desc: '',
      args: [],
    );
  }

  /// `No orders yet`
  String get shop_orders_empty {
    return Intl.message(
      'No orders yet',
      name: 'shop_orders_empty',
      desc: '',
      args: [],
    );
  }

  /// `Order #{number}`
  String order_number(String number) {
    return Intl.message(
      'Order #$number',
      name: 'order_number',
      desc: '',
      args: [number],
    );
  }

  /// `Placed {date}`
  String order_placed_on(String date) {
    return Intl.message(
      'Placed $date',
      name: 'order_placed_on',
      desc: '',
      args: [date],
    );
  }

  /// `{count, plural, =0{No items} =1{1 item} other{{count} items}}`
  String order_items_count(int count) {
    return Intl.plural(
      count,
      zero: 'No items',
      one: '1 item',
      other: '$count items',
      name: 'order_items_count',
      desc: '',
      args: [count],
    );
  }

  /// `Awaiting payment`
  String get order_status_awaiting_payment {
    return Intl.message(
      'Awaiting payment',
      name: 'order_status_awaiting_payment',
      desc: '',
      args: [],
    );
  }

  /// `Confirmed`
  String get order_status_pending {
    return Intl.message(
      'Confirmed',
      name: 'order_status_pending',
      desc: '',
      args: [],
    );
  }

  /// `Being packed`
  String get order_status_preparing {
    return Intl.message(
      'Being packed',
      name: 'order_status_preparing',
      desc: '',
      args: [],
    );
  }

  /// `On the way`
  String get order_status_out_for_delivery {
    return Intl.message(
      'On the way',
      name: 'order_status_out_for_delivery',
      desc: '',
      args: [],
    );
  }

  /// `Delivered`
  String get order_status_completed {
    return Intl.message(
      'Delivered',
      name: 'order_status_completed',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get order_status_cancelled {
    return Intl.message(
      'Cancelled',
      name: 'order_status_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Being processed`
  String get order_status_unknown {
    return Intl.message(
      'Being processed',
      name: 'order_status_unknown',
      desc: '',
      args: [],
    );
  }

  /// `What you ordered`
  String get order_items_heading {
    return Intl.message(
      'What you ordered',
      name: 'order_items_heading',
      desc: '',
      args: [],
    );
  }

  /// `Delivery`
  String get order_delivery_heading {
    return Intl.message(
      'Delivery',
      name: 'order_delivery_heading',
      desc: '',
      args: [],
    );
  }

  /// `Delivering to`
  String get order_delivery_to {
    return Intl.message(
      'Delivering to',
      name: 'order_delivery_to',
      desc: '',
      args: [],
    );
  }

  /// `Note for the courier`
  String get order_delivery_notes {
    return Intl.message(
      'Note for the courier',
      name: 'order_delivery_notes',
      desc: '',
      args: [],
    );
  }

  /// `Short address`
  String get order_short_address {
    return Intl.message(
      'Short address',
      name: 'order_short_address',
      desc: '',
      args: [],
    );
  }

  /// `{count} × {price}`
  String order_quantity(int count, String price) {
    return Intl.message(
      '$count × $price',
      name: 'order_quantity',
      desc: '',
      args: [count, price],
    );
  }

  /// `Pay now`
  String get order_pay_now {
    return Intl.message('Pay now', name: 'order_pay_now', desc: '', args: []);
  }

  /// `Pay before {time}`
  String order_pay_before(String time) {
    return Intl.message(
      'Pay before $time',
      name: 'order_pay_before',
      desc: '',
      args: [time],
    );
  }

  /// `Cancel order`
  String get order_cancel {
    return Intl.message(
      'Cancel order',
      name: 'order_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Cancel this order?`
  String get order_cancel_title {
    return Intl.message(
      'Cancel this order?',
      name: 'order_cancel_title',
      desc: '',
      args: [],
    );
  }

  /// `Anything already paid comes back as Terracotta balance, not to your card. This cannot be undone.`
  String get order_cancel_body {
    return Intl.message(
      'Anything already paid comes back as Terracotta balance, not to your card. This cannot be undone.',
      name: 'order_cancel_body',
      desc: '',
      args: [],
    );
  }

  /// `{amount} is back in your Terracotta balance.`
  String order_cancel_refunded(Object amount) {
    return Intl.message(
      '$amount is back in your Terracotta balance.',
      name: 'order_cancel_refunded',
      desc: '',
      args: [amount],
    );
  }

  /// `Yes, cancel it`
  String get order_cancel_yes {
    return Intl.message(
      'Yes, cancel it',
      name: 'order_cancel_yes',
      desc: '',
      args: [],
    );
  }

  /// `Keep it`
  String get order_cancel_no {
    return Intl.message('Keep it', name: 'order_cancel_no', desc: '', args: []);
  }

  /// `Cancelled {date}`
  String order_cancelled_on(String date) {
    return Intl.message(
      'Cancelled $date',
      name: 'order_cancelled_on',
      desc: '',
      args: [date],
    );
  }

  /// `This order could not be opened`
  String get order_not_found {
    return Intl.message(
      'This order could not be opened',
      name: 'order_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Paid in full`
  String get order_settled {
    return Intl.message(
      'Paid in full',
      name: 'order_settled',
      desc: '',
      args: [],
    );
  }

  /// `Your order is placed!`
  String get order_confirmed_title {
    return Intl.message(
      'Your order is placed!',
      name: 'order_confirmed_title',
      desc: '',
      args: [],
    );
  }

  /// `We are preparing it now. You can follow it from your orders at any time.`
  String get order_confirmed_body {
    return Intl.message(
      'We are preparing it now. You can follow it from your orders at any time.',
      name: 'order_confirmed_body',
      desc: '',
      args: [],
    );
  }

  /// `Track order`
  String get order_track {
    return Intl.message('Track order', name: 'order_track', desc: '', args: []);
  }

  /// `Anything you order from the studio shows up here.`
  String get shop_orders_empty_body {
    return Intl.message(
      'Anything you order from the studio shows up here.',
      name: 'shop_orders_empty_body',
      desc: '',
      args: [],
    );
  }

  /// `My pieces`
  String get pieces_title {
    return Intl.message('My pieces', name: 'pieces_title', desc: '', args: []);
  }

  /// `Nothing made yet`
  String get pieces_empty {
    return Intl.message(
      'Nothing made yet',
      name: 'pieces_empty',
      desc: '',
      args: [],
    );
  }

  /// `Pieces you make at the studio are kept here, ready to be painted.`
  String get pieces_empty_body {
    return Intl.message(
      'Pieces you make at the studio are kept here, ready to be painted.',
      name: 'pieces_empty_body',
      desc: '',
      args: [],
    );
  }

  /// `Not available right now`
  String get pieces_no_source {
    return Intl.message(
      'Not available right now',
      name: 'pieces_no_source',
      desc: '',
      args: [],
    );
  }

  /// `The studio is not taking pieces back at the moment. Yours are safe.`
  String get pieces_no_source_body {
    return Intl.message(
      'The studio is not taking pieces back at the moment. Yours are safe.',
      name: 'pieces_no_source_body',
      desc: '',
      args: [],
    );
  }

  /// `Made {date}`
  String pieces_made_on(String date) {
    return Intl.message(
      'Made $date',
      name: 'pieces_made_on',
      desc: '',
      args: [date],
    );
  }

  /// `Untitled piece`
  String get pieces_untitled {
    return Intl.message(
      'Untitled piece',
      name: 'pieces_untitled',
      desc: '',
      args: [],
    );
  }

  /// `Painted`
  String get pieces_painted {
    return Intl.message('Painted', name: 'pieces_painted', desc: '', args: []);
  }

  /// `Ready to paint`
  String get pieces_available {
    return Intl.message(
      'Ready to paint',
      name: 'pieces_available',
      desc: '',
      args: [],
    );
  }

  /// `Paint one for {amount}`
  String pieces_paint_price(String amount) {
    return Intl.message(
      'Paint one for $amount',
      name: 'pieces_paint_price',
      desc: '',
      args: [amount],
    );
  }

  /// `Your cart is empty`
  String get shop_cart_empty {
    return Intl.message(
      'Your cart is empty',
      name: 'shop_cart_empty',
      desc: '',
      args: [],
    );
  }

  /// `{title} x {count}`
  String shop_line_item(String title, String count) {
    return Intl.message(
      '$title x $count',
      name: 'shop_line_item',
      desc: '',
      args: [title, count],
    );
  }

  /// `Confirm payment`
  String get shop_checkout {
    return Intl.message(
      'Confirm payment',
      name: 'shop_checkout',
      desc: '',
      args: [],
    );
  }

  /// `Your piece is ready`
  String get delivery_piece_ready {
    return Intl.message(
      'Your piece is ready',
      name: 'delivery_piece_ready',
      desc: '',
      args: [],
    );
  }

  /// `Your piece is ready for pickup or delivery.`
  String get delivery_piece_ready_body {
    return Intl.message(
      'Your piece is ready for pickup or delivery.',
      name: 'delivery_piece_ready_body',
      desc: '',
      args: [],
    );
  }

  /// `Deliver`
  String get delivery_deliver {
    return Intl.message(
      'Deliver',
      name: 'delivery_deliver',
      desc: '',
      args: [],
    );
  }

  /// `Pick up`
  String get delivery_pickup {
    return Intl.message('Pick up', name: 'delivery_pickup', desc: '', args: []);
  }

  /// `Paint my cup`
  String get delivery_paint_it {
    return Intl.message(
      'Paint my cup',
      name: 'delivery_paint_it',
      desc: '',
      args: [],
    );
  }

  /// `Where would you like to paint it?`
  String get delivery_paint_pick_title {
    return Intl.message(
      'Where would you like to paint it?',
      name: 'delivery_paint_pick_title',
      desc: '',
      args: [],
    );
  }

  /// `Delivery phone number`
  String get delivery_phone {
    return Intl.message(
      'Delivery phone number',
      name: 'delivery_phone',
      desc: '',
      args: [],
    );
  }

  /// `Heads up`
  String get delivery_warning_title {
    return Intl.message(
      'Heads up',
      name: 'delivery_warning_title',
      desc: '',
      args: [],
    );
  }

  /// `{left} left to collect your piece or ask for delivery. After that the studio cannot hold it.`
  String delivery_warning_body(String left) {
    return Intl.message(
      '$left left to collect your piece or ask for delivery. After that the studio cannot hold it.',
      name: 'delivery_warning_body',
      desc: '',
      args: [left],
    );
  }

  /// `Piece delivery`
  String get delivery_fee_line {
    return Intl.message(
      'Piece delivery',
      name: 'delivery_fee_line',
      desc: '',
      args: [],
    );
  }

  /// `Confirm delivery and pay`
  String get delivery_confirm_and_pay {
    return Intl.message(
      'Confirm delivery and pay',
      name: 'delivery_confirm_and_pay',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get delivery_close {
    return Intl.message('Close', name: 'delivery_close', desc: '', args: []);
  }

  /// `Gift a balance`
  String get gift_title {
    return Intl.message(
      'Gift a balance',
      name: 'gift_title',
      desc: '',
      args: [],
    );
  }

  /// `Gift {amount}`
  String gift_amount(String amount) {
    return Intl.message(
      'Gift $amount',
      name: 'gift_amount',
      desc: '',
      args: [amount],
    );
  }

  /// `Recipient name`
  String get gift_recipient_name {
    return Intl.message(
      'Recipient name',
      name: 'gift_recipient_name',
      desc: '',
      args: [],
    );
  }

  /// `Recipient phone`
  String get gift_recipient_phone {
    return Intl.message(
      'Recipient phone',
      name: 'gift_recipient_phone',
      desc: '',
      args: [],
    );
  }

  /// `05XXXXXXXX`
  String get gift_recipient_phone_hint {
    return Intl.message(
      '05XXXXXXXX',
      name: 'gift_recipient_phone_hint',
      desc: '',
      args: [],
    );
  }

  /// `Message`
  String get gift_message {
    return Intl.message('Message', name: 'gift_message', desc: '', args: []);
  }

  /// `Send a balance to someone you love, for pottery and ceramics workshops`
  String get gift_hero_body {
    return Intl.message(
      'Send a balance to someone you love, for pottery and ceramics workshops',
      name: 'gift_hero_body',
      desc: '',
      args: [],
    );
  }

  /// `Copy the link and send it to whoever the gift is for, to enjoy Terracotta workshops`
  String get gift_purchased_body {
    return Intl.message(
      'Copy the link and send it to whoever the gift is for, to enjoy Terracotta workshops',
      name: 'gift_purchased_body',
      desc: '',
      args: [],
    );
  }

  /// `Sara`
  String get gift_recipient_hint {
    return Intl.message(
      'Sara',
      name: 'gift_recipient_hint',
      desc: '',
      args: [],
    );
  }

  /// `Write your message here...`
  String get gift_message_hint {
    return Intl.message(
      'Write your message here...',
      name: 'gift_message_hint',
      desc: '',
      args: [],
    );
  }

  /// `Confirm gift and pay`
  String get gift_confirm_and_pay {
    return Intl.message(
      'Confirm gift and pay',
      name: 'gift_confirm_and_pay',
      desc: '',
      args: [],
    );
  }

  /// `Gift purchased!`
  String get gift_purchased_title {
    return Intl.message(
      'Gift purchased!',
      name: 'gift_purchased_title',
      desc: '',
      args: [],
    );
  }

  /// `Share the link`
  String get gift_share_link {
    return Intl.message(
      'Share the link',
      name: 'gift_share_link',
      desc: '',
      args: [],
    );
  }

  /// `You have not sent any gifts yet`
  String get gift_empty {
    return Intl.message(
      'You have not sent any gifts yet',
      name: 'gift_empty',
      desc: '',
      args: [],
    );
  }

  /// `Send a gift`
  String get gift_tab_send {
    return Intl.message(
      'Send a gift',
      name: 'gift_tab_send',
      desc: '',
      args: [],
    );
  }

  /// `My gifts`
  String get gift_tab_mine {
    return Intl.message('My gifts', name: 'gift_tab_mine', desc: '', args: []);
  }

  /// `Claimed`
  String get gift_state_claimed {
    return Intl.message(
      'Claimed',
      name: 'gift_state_claimed',
      desc: '',
      args: [],
    );
  }

  /// `Not claimed yet`
  String get gift_state_unclaimed {
    return Intl.message(
      'Not claimed yet',
      name: 'gift_state_unclaimed',
      desc: '',
      args: [],
    );
  }

  /// `Not paid`
  String get gift_state_unpaid {
    return Intl.message(
      'Not paid',
      name: 'gift_state_unpaid',
      desc: '',
      args: [],
    );
  }

  /// `Copy link`
  String get gift_copy_link {
    return Intl.message(
      'Copy link',
      name: 'gift_copy_link',
      desc: '',
      args: [],
    );
  }

  /// `Link copied`
  String get gift_link_copied {
    return Intl.message(
      'Link copied',
      name: 'gift_link_copied',
      desc: '',
      args: [],
    );
  }

  /// `For {name}`
  String gift_for(String name) {
    return Intl.message('For $name', name: 'gift_for', desc: '', args: [name]);
  }

  /// `From {name}`
  String gift_from(String name) {
    return Intl.message(
      'From $name',
      name: 'gift_from',
      desc: '',
      args: [name],
    );
  }

  /// `A gift you claimed`
  String get gift_from_someone {
    return Intl.message(
      'A gift you claimed',
      name: 'gift_from_someone',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get gift_filter_all {
    return Intl.message('All', name: 'gift_filter_all', desc: '', args: []);
  }

  /// `Sent`
  String get gift_filter_sent {
    return Intl.message('Sent', name: 'gift_filter_sent', desc: '', args: []);
  }

  /// `Claimed`
  String get gift_filter_received {
    return Intl.message(
      'Claimed',
      name: 'gift_filter_received',
      desc: '',
      args: [],
    );
  }

  /// `You have not sent any gifts yet`
  String get gift_none_sent {
    return Intl.message(
      'You have not sent any gifts yet',
      name: 'gift_none_sent',
      desc: '',
      args: [],
    );
  }

  /// `You have not claimed any gifts yet`
  String get gift_none_received {
    return Intl.message(
      'You have not claimed any gifts yet',
      name: 'gift_none_received',
      desc: '',
      args: [],
    );
  }

  /// `Expired unpaid`
  String get gift_state_cancelled {
    return Intl.message(
      'Expired unpaid',
      name: 'gift_state_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `My account`
  String get profile_title {
    return Intl.message(
      'My account',
      name: 'profile_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit profile`
  String get profile_edit {
    return Intl.message(
      'Edit profile',
      name: 'profile_edit',
      desc: '',
      args: [],
    );
  }

  /// `My addresses`
  String get profile_addresses {
    return Intl.message(
      'My addresses',
      name: 'profile_addresses',
      desc: '',
      args: [],
    );
  }

  /// `My wallet`
  String get profile_wallet {
    return Intl.message(
      'My wallet',
      name: 'profile_wallet',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get profile_notifications {
    return Intl.message(
      'Notifications',
      name: 'profile_notifications',
      desc: '',
      args: [],
    );
  }

  /// `My orders`
  String get profile_orders {
    return Intl.message(
      'My orders',
      name: 'profile_orders',
      desc: '',
      args: [],
    );
  }

  /// `Devices`
  String get profile_devices {
    return Intl.message('Devices', name: 'profile_devices', desc: '', args: []);
  }

  /// `Change password`
  String get profile_change_password {
    return Intl.message(
      'Change password',
      name: 'profile_change_password',
      desc: '',
      args: [],
    );
  }

  /// `Sign out`
  String get profile_logout {
    return Intl.message('Sign out', name: 'profile_logout', desc: '', args: []);
  }

  /// `Delete account`
  String get profile_delete_account {
    return Intl.message(
      'Delete account',
      name: 'profile_delete_account',
      desc: '',
      args: [],
    );
  }

  /// `This permanently deletes your account. It cannot be undone.`
  String get profile_delete_warning {
    return Intl.message(
      'This permanently deletes your account. It cannot be undone.',
      name: 'profile_delete_warning',
      desc: '',
      args: [],
    );
  }

  /// `Add an address`
  String get profile_add_address {
    return Intl.message(
      'Add an address',
      name: 'profile_add_address',
      desc: '',
      args: [],
    );
  }

  /// `Set as default`
  String get profile_set_default {
    return Intl.message(
      'Set as default',
      name: 'profile_set_default',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get profile_default {
    return Intl.message('Default', name: 'profile_default', desc: '', args: []);
  }

  /// `No saved addresses`
  String get profile_no_addresses {
    return Intl.message(
      'No saved addresses',
      name: 'profile_no_addresses',
      desc: '',
      args: [],
    );
  }

  /// `No notifications`
  String get profile_no_notifications {
    return Intl.message(
      'No notifications',
      name: 'profile_no_notifications',
      desc: '',
      args: [],
    );
  }

  /// `Mark all read`
  String get profile_mark_all_read {
    return Intl.message(
      'Mark all read',
      name: 'profile_mark_all_read',
      desc: '',
      args: [],
    );
  }

  /// `No other devices`
  String get profile_no_devices {
    return Intl.message(
      'No other devices',
      name: 'profile_no_devices',
      desc: '',
      args: [],
    );
  }

  /// `Sign out this device`
  String get profile_revoke {
    return Intl.message(
      'Sign out this device',
      name: 'profile_revoke',
      desc: '',
      args: [],
    );
  }

  /// `This device`
  String get profile_this_device {
    return Intl.message(
      'This device',
      name: 'profile_this_device',
      desc: '',
      args: [],
    );
  }

  /// `No transactions yet`
  String get profile_no_transactions {
    return Intl.message(
      'No transactions yet',
      name: 'profile_no_transactions',
      desc: '',
      args: [],
    );
  }

  /// `Everything added to your balance, and everything taken from it, shows up here.`
  String get wallet_empty_body {
    return Intl.message(
      'Everything added to your balance, and everything taken from it, shows up here.',
      name: 'wallet_empty_body',
      desc: '',
      args: [],
    );
  }

  /// `Delivery fee`
  String get wallet_reason_delivery_fee {
    return Intl.message(
      'Delivery fee',
      name: 'wallet_reason_delivery_fee',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled booking refund`
  String get wallet_reason_booking_cancelled {
    return Intl.message(
      'Cancelled booking refund',
      name: 'wallet_reason_booking_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Workshop booking`
  String get wallet_reason_booking_payment {
    return Intl.message(
      'Workshop booking',
      name: 'wallet_reason_booking_payment',
      desc: '',
      args: [],
    );
  }

  /// `Shop order`
  String get wallet_reason_order_payment {
    return Intl.message(
      'Shop order',
      name: 'wallet_reason_order_payment',
      desc: '',
      args: [],
    );
  }

  /// `Gift balance`
  String get wallet_reason_gift {
    return Intl.message(
      'Gift balance',
      name: 'wallet_reason_gift',
      desc: '',
      args: [],
    );
  }

  /// `Booking changed`
  String get wallet_reason_booking_rescheduled {
    return Intl.message(
      'Booking changed',
      name: 'wallet_reason_booking_rescheduled',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled order`
  String get wallet_reason_shop_order_cancelled {
    return Intl.message(
      'Cancelled order',
      name: 'wallet_reason_shop_order_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Adjusted by the studio`
  String get wallet_reason_admin_adjustment {
    return Intl.message(
      'Adjusted by the studio',
      name: 'wallet_reason_admin_adjustment',
      desc: '',
      args: [],
    );
  }

  /// `Gift bought`
  String get wallet_reason_gift_purchase {
    return Intl.message(
      'Gift bought',
      name: 'wallet_reason_gift_purchase',
      desc: '',
      args: [],
    );
  }

  /// `No-show refund`
  String get wallet_reason_booking_absent {
    return Intl.message(
      'No-show refund',
      name: 'wallet_reason_booking_absent',
      desc: '',
      args: [],
    );
  }

  /// `Added to balance`
  String get wallet_credit {
    return Intl.message(
      'Added to balance',
      name: 'wallet_credit',
      desc: '',
      args: [],
    );
  }

  /// `Taken from balance`
  String get wallet_debit {
    return Intl.message(
      'Taken from balance',
      name: 'wallet_debit',
      desc: '',
      args: [],
    );
  }

  /// `Balance after: {amount}`
  String wallet_balance_after(String amount) {
    return Intl.message(
      'Balance after: $amount',
      name: 'wallet_balance_after',
      desc: '',
      args: [amount],
    );
  }

  /// `Order details`
  String get profile_order_detail {
    return Intl.message(
      'Order details',
      name: 'profile_order_detail',
      desc: '',
      args: [],
    );
  }

  /// `Cancel order`
  String get profile_cancel_order {
    return Intl.message(
      'Cancel order',
      name: 'profile_cancel_order',
      desc: '',
      args: [],
    );
  }

  /// `You can now set a new password for your account.`
  String get auth_reset_subtitle {
    return Intl.message(
      'You can now set a new password for your account.',
      name: 'auth_reset_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `We sent a {digits}-digit code to {phone}`
  String auth_otp_subtitle_phone(int digits, String phone) {
    return Intl.message(
      'We sent a $digits-digit code to $phone',
      name: 'auth_otp_subtitle_phone',
      desc: '',
      args: [digits, phone],
    );
  }

  /// `Enter the full verification code`
  String get auth_otp_incomplete {
    return Intl.message(
      'Enter the full verification code',
      name: 'auth_otp_incomplete',
      desc: '',
      args: [],
    );
  }

  /// `Product details`
  String get shop_product_details {
    return Intl.message(
      'Product details',
      name: 'shop_product_details',
      desc: '',
      args: [],
    );
  }

  /// `height`
  String get shop_dimension_height {
    return Intl.message(
      'height',
      name: 'shop_dimension_height',
      desc: '',
      args: [],
    );
  }

  /// `width`
  String get shop_dimension_width {
    return Intl.message(
      'width',
      name: 'shop_dimension_width',
      desc: '',
      args: [],
    );
  }

  /// `length`
  String get shop_dimension_length {
    return Intl.message(
      'length',
      name: 'shop_dimension_length',
      desc: '',
      args: [],
    );
  }

  /// `cm`
  String get shop_dimension_unit {
    return Intl.message('cm', name: 'shop_dimension_unit', desc: '', args: []);
  }

  /// `Black`
  String get color_name_black {
    return Intl.message('Black', name: 'color_name_black', desc: '', args: []);
  }

  /// `White`
  String get color_name_white {
    return Intl.message('White', name: 'color_name_white', desc: '', args: []);
  }

  /// `Grey`
  String get color_name_grey {
    return Intl.message('Grey', name: 'color_name_grey', desc: '', args: []);
  }

  /// `Beige`
  String get color_name_beige {
    return Intl.message('Beige', name: 'color_name_beige', desc: '', args: []);
  }

  /// `Brown`
  String get color_name_brown {
    return Intl.message('Brown', name: 'color_name_brown', desc: '', args: []);
  }

  /// `Terracotta`
  String get color_name_terracotta {
    return Intl.message(
      'Terracotta',
      name: 'color_name_terracotta',
      desc: '',
      args: [],
    );
  }

  /// `Orange`
  String get color_name_orange {
    return Intl.message(
      'Orange',
      name: 'color_name_orange',
      desc: '',
      args: [],
    );
  }

  /// `Red`
  String get color_name_red {
    return Intl.message('Red', name: 'color_name_red', desc: '', args: []);
  }

  /// `Pink`
  String get color_name_pink {
    return Intl.message('Pink', name: 'color_name_pink', desc: '', args: []);
  }

  /// `Purple`
  String get color_name_purple {
    return Intl.message(
      'Purple',
      name: 'color_name_purple',
      desc: '',
      args: [],
    );
  }

  /// `Navy`
  String get color_name_navy {
    return Intl.message('Navy', name: 'color_name_navy', desc: '', args: []);
  }

  /// `Blue`
  String get color_name_blue {
    return Intl.message('Blue', name: 'color_name_blue', desc: '', args: []);
  }

  /// `Teal`
  String get color_name_teal {
    return Intl.message('Teal', name: 'color_name_teal', desc: '', args: []);
  }

  /// `Green`
  String get color_name_green {
    return Intl.message('Green', name: 'color_name_green', desc: '', args: []);
  }

  /// `Olive`
  String get color_name_olive {
    return Intl.message('Olive', name: 'color_name_olive', desc: '', args: []);
  }

  /// `Yellow`
  String get color_name_yellow {
    return Intl.message(
      'Yellow',
      name: 'color_name_yellow',
      desc: '',
      args: [],
    );
  }

  /// `Sign out?`
  String get profile_sign_out_title {
    return Intl.message(
      'Sign out?',
      name: 'profile_sign_out_title',
      desc: '',
      args: [],
    );
  }

  /// `You will need your phone number and password to get back in. Nothing in your cart or bookings is lost.`
  String get profile_sign_out_message {
    return Intl.message(
      'You will need your phone number and password to get back in. Nothing in your cart or bookings is lost.',
      name: 'profile_sign_out_message',
      desc: '',
      args: [],
    );
  }

  /// `Delete permanently`
  String get profile_delete_confirm {
    return Intl.message(
      'Delete permanently',
      name: 'profile_delete_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Your bookings, orders and Terracotta balance go with it. This happens straight away and cannot be undone.`
  String get profile_delete_message {
    return Intl.message(
      'Your bookings, orders and Terracotta balance go with it. This happens straight away and cannot be undone.',
      name: 'profile_delete_message',
      desc: '',
      args: [],
    );
  }

  /// `Current password`
  String get profile_current_password {
    return Intl.message(
      'Current password',
      name: 'profile_current_password',
      desc: '',
      args: [],
    );
  }

  /// `Enter your current password`
  String get profile_current_password_hint {
    return Intl.message(
      'Enter your current password',
      name: 'profile_current_password_hint',
      desc: '',
      args: [],
    );
  }

  /// `Your password has been changed.`
  String get profile_password_changed {
    return Intl.message(
      'Your password has been changed.',
      name: 'profile_password_changed',
      desc: '',
      args: [],
    );
  }

  /// `You will stay signed in on this device.`
  String get profile_change_password_message {
    return Intl.message(
      'You will stay signed in on this device.',
      name: 'profile_change_password_message',
      desc: '',
      args: [],
    );
  }

  /// `Edit name`
  String get profile_edit_name {
    return Intl.message(
      'Edit name',
      name: 'profile_edit_name',
      desc: '',
      args: [],
    );
  }

  /// `Your name`
  String get profile_name_label {
    return Intl.message(
      'Your name',
      name: 'profile_name_label',
      desc: '',
      args: [],
    );
  }

  /// `Enter your name`
  String get profile_name_hint {
    return Intl.message(
      'Enter your name',
      name: 'profile_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Your name has been updated.`
  String get profile_name_updated {
    return Intl.message(
      'Your name has been updated.',
      name: 'profile_name_updated',
      desc: '',
      args: [],
    );
  }

  /// `Take it out?`
  String get shop_remove_line_title {
    return Intl.message(
      'Take it out?',
      name: 'shop_remove_line_title',
      desc: '',
      args: [],
    );
  }

  /// `{title} will be taken out of your cart. You can always add it again.`
  String shop_remove_line_message(String title) {
    return Intl.message(
      '$title will be taken out of your cart. You can always add it again.',
      name: 'shop_remove_line_message',
      desc: '',
      args: [title],
    );
  }

  /// `Confirmed`
  String get booking_status_confirmed {
    return Intl.message(
      'Confirmed',
      name: 'booking_status_confirmed',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get booking_status_completed {
    return Intl.message(
      'Done',
      name: 'booking_status_completed',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get booking_status_cancelled {
    return Intl.message(
      'Cancelled',
      name: 'booking_status_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get booking_status_expired {
    return Intl.message(
      'Expired',
      name: 'booking_status_expired',
      desc: '',
      args: [],
    );
  }

  /// `You have not booked a workshop yet.`
  String get booking_mine_empty {
    return Intl.message(
      'You have not booked a workshop yet.',
      name: 'booking_mine_empty',
      desc: '',
      args: [],
    );
  }

  /// `{people} · {date} · {time}`
  String booking_meta(String people, String date, String time) {
    return Intl.message(
      '$people · $date · $time',
      name: 'booking_meta',
      desc: '',
      args: [people, date, time],
    );
  }

  /// `{count, plural, one{person} other{people}}`
  String booking_people_unit(int count) {
    return Intl.plural(
      count,
      one: 'person',
      other: 'people',
      name: 'booking_people_unit',
      desc: '',
      args: [count],
    );
  }

  /// `No sessions on this day.`
  String get booking_no_slots {
    return Intl.message(
      'No sessions on this day.',
      name: 'booking_no_slots',
      desc: '',
      args: [],
    );
  }

  /// `How many are coming?`
  String get booking_pick_people {
    return Intl.message(
      'How many are coming?',
      name: 'booking_pick_people',
      desc: '',
      args: [],
    );
  }

  /// `{left} of {total}`
  String booking_slot_seats(String left, String total) {
    return Intl.message(
      '$left of $total',
      name: 'booking_slot_seats',
      desc: '',
      args: [left, total],
    );
  }

  /// `Workshop from {start} to {end}`
  String booking_slot_label(String start, String end) {
    return Intl.message(
      'Workshop from $start to $end',
      name: 'booking_slot_label',
      desc: '',
      args: [start, end],
    );
  }

  /// `Fully booked`
  String get booking_full_up {
    return Intl.message(
      'Fully booked',
      name: 'booking_full_up',
      desc: '',
      args: [],
    );
  }

  /// `{title} for {people}`
  String checkout_workshop_line(String title, String people) {
    return Intl.message(
      '$title for $people',
      name: 'checkout_workshop_line',
      desc: '',
      args: [title, people],
    );
  }

  /// `Celebrate with Terracotta`
  String get celebration_title {
    return Intl.message(
      'Celebrate with Terracotta',
      name: 'celebration_title',
      desc: '',
      args: [],
    );
  }

  /// `Balloons, a little cake and the room set for it — we take care of the whole thing while you make your piece.`
  String get celebration_body {
    return Intl.message(
      'Balloons, a little cake and the room set for it — we take care of the whole thing while you make your piece.',
      name: 'celebration_body',
      desc: '',
      args: [],
    );
  }

  /// `Add for {price}`
  String celebration_add_price(String price) {
    return Intl.message(
      'Add for $price',
      name: 'celebration_add_price',
      desc: '',
      args: [price],
    );
  }

  /// `{count, plural, one{1 person} other{{count} people}}`
  String booking_party(int count) {
    return Intl.plural(
      count,
      one: '1 person',
      other: '$count people',
      name: 'booking_party',
      desc: '',
      args: [count],
    );
  }

  /// `Use my Terracotta balance`
  String get checkout_use_wallet {
    return Intl.message(
      'Use my Terracotta balance',
      name: 'checkout_use_wallet',
      desc: '',
      args: [],
    );
  }

  /// `Covers {amount} of it`
  String checkout_wallet_covers(String amount) {
    return Intl.message(
      'Covers $amount of it',
      name: 'checkout_wallet_covers',
      desc: '',
      args: [amount],
    );
  }

  /// `Left to pay`
  String get checkout_left_to_pay {
    return Intl.message(
      'Left to pay',
      name: 'checkout_left_to_pay',
      desc: '',
      args: [],
    );
  }

  /// `Your session has ended`
  String get auth_session_expired_title {
    return Intl.message(
      'Your session has ended',
      name: 'auth_session_expired_title',
      desc: '',
      args: [],
    );
  }

  /// `You were signed out. Sign in again to reach your cart, bookings and balance.`
  String get auth_session_expired_message {
    return Intl.message(
      'You were signed out. Sign in again to reach your cart, bookings and balance.',
      name: 'auth_session_expired_message',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to continue`
  String get auth_sign_in_required_title {
    return Intl.message(
      'Sign in to continue',
      name: 'auth_sign_in_required_title',
      desc: '',
      args: [],
    );
  }

  /// `This one needs an account. Sign in to reach your cart, bookings and balance.`
  String get auth_sign_in_required_message {
    return Intl.message(
      'This one needs an account. Sign in to reach your cart, bookings and balance.',
      name: 'auth_sign_in_required_message',
      desc: '',
      args: [],
    );
  }

  /// `Browse as a guest`
  String get auth_continue_as_guest {
    return Intl.message(
      'Browse as a guest',
      name: 'auth_continue_as_guest',
      desc: '',
      args: [],
    );
  }

  /// `or`
  String get auth_or {
    return Intl.message('or', name: 'auth_or', desc: '', args: []);
  }

  /// `Guest`
  String get profile_guest {
    return Intl.message('Guest', name: 'profile_guest', desc: '', args: []);
  }

  /// `Sign in to keep your cart, bookings and balance.`
  String get profile_guest_hint {
    return Intl.message(
      'Sign in to keep your cart, bookings and balance.',
      name: 'profile_guest_hint',
      desc: '',
      args: [],
    );
  }

  /// `Out of stock`
  String get shop_out_of_stock {
    return Intl.message(
      'Out of stock',
      name: 'shop_out_of_stock',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 left} other{{count} left}}`
  String shop_stock_left(int count) {
    return Intl.plural(
      count,
      one: '1 left',
      other: '$count left',
      name: 'shop_stock_left',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{Only 1 available} other{Only {count} available}}`
  String shop_max_reached(int count) {
    return Intl.plural(
      count,
      one: 'Only 1 available',
      other: 'Only $count available',
      name: 'shop_max_reached',
      desc: '',
      args: [count],
    );
  }

  /// `100 per order is the most we can take`
  String get shop_max_per_order {
    return Intl.message(
      '100 per order is the most we can take',
      name: 'shop_max_per_order',
      desc: '',
      args: [],
    );
  }

  /// `Bring your picks with you?`
  String get transfer_title {
    return Intl.message(
      'Bring your picks with you?',
      name: 'transfer_title',
      desc: '',
      args: [],
    );
  }

  /// `You collected these before signing in. They live on this phone only — we can move them to your account now.`
  String get transfer_body {
    return Intl.message(
      'You collected these before signing in. They live on this phone only — we can move them to your account now.',
      name: 'transfer_body',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 piece in your basket} other{{count} pieces in your basket}}`
  String transfer_basket(int count) {
    return Intl.plural(
      count,
      one: '1 piece in your basket',
      other: '$count pieces in your basket',
      name: 'transfer_basket',
      desc: '',
      args: [count],
    );
  }

  /// `One step left`
  String get auth_needed_title {
    return Intl.message(
      'One step left',
      name: 'auth_needed_title',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to confirm this booking. Your date, your seats and everything you picked are kept exactly as they are.`
  String get auth_needed_booking {
    return Intl.message(
      'Sign in to confirm this booking. Your date, your seats and everything you picked are kept exactly as they are.',
      name: 'auth_needed_booking',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to pay. Your basket, your addresses and your saved pieces come with you.`
  String get auth_needed_cart {
    return Intl.message(
      'Sign in to pay. Your basket, your addresses and your saved pieces come with you.',
      name: 'auth_needed_cart',
      desc: '',
      args: [],
    );
  }

  /// `Sign in`
  String get auth_needed_confirm {
    return Intl.message(
      'Sign in',
      name: 'auth_needed_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Not now`
  String get auth_needed_later {
    return Intl.message(
      'Not now',
      name: 'auth_needed_later',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 saved address} other{{count} saved addresses}}`
  String transfer_addresses(int count) {
    return Intl.plural(
      count,
      one: '1 saved address',
      other: '$count saved addresses',
      name: 'transfer_addresses',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 saved piece} other{{count} saved pieces}}`
  String transfer_saved(int count) {
    return Intl.plural(
      count,
      one: '1 saved piece',
      other: '$count saved pieces',
      name: 'transfer_saved',
      desc: '',
      args: [count],
    );
  }

  /// `Move them to my account`
  String get transfer_confirm {
    return Intl.message(
      'Move them to my account',
      name: 'transfer_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Not these`
  String get transfer_skip {
    return Intl.message('Not these', name: 'transfer_skip', desc: '', args: []);
  }

  /// `Leave them behind?`
  String get transfer_discard_title {
    return Intl.message(
      'Leave them behind?',
      name: 'transfer_discard_title',
      desc: '',
      args: [],
    );
  }

  /// `They only live on this phone, so they will be gone once you continue. Nothing is charged either way.`
  String get transfer_discard_body {
    return Intl.message(
      'They only live on this phone, so they will be gone once you continue. Nothing is charged either way.',
      name: 'transfer_discard_body',
      desc: '',
      args: [],
    );
  }

  /// `Leave them`
  String get transfer_discard_confirm {
    return Intl.message(
      'Leave them',
      name: 'transfer_discard_confirm',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 piece moved over} other{{count} pieces moved over}}`
  String transfer_done(int count) {
    return Intl.plural(
      count,
      one: '1 piece moved over',
      other: '$count pieces moved over',
      name: 'transfer_done',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 piece could not be moved — the studio has run out} other{{count} pieces could not be moved — the studio has run out}}`
  String transfer_partial(int count) {
    return Intl.plural(
      count,
      one: '1 piece could not be moved — the studio has run out',
      other: '$count pieces could not be moved — the studio has run out',
      name: 'transfer_partial',
      desc: '',
      args: [count],
    );
  }

  /// `Some pieces ran out`
  String get cart_stock_title {
    return Intl.message(
      'Some pieces ran out',
      name: 'cart_stock_title',
      desc: '',
      args: [],
    );
  }

  /// `The studio sold some of these while you were browsing. Here is what changed:`
  String get cart_stock_body {
    return Intl.message(
      'The studio sold some of these while you were browsing. Here is what changed:',
      name: 'cart_stock_body',
      desc: '',
      args: [],
    );
  }

  /// `{title}: you have {wanted}, only {left} left`
  String cart_stock_line_left(String title, int wanted, int left) {
    return Intl.message(
      '$title: you have $wanted, only $left left',
      name: 'cart_stock_line_left',
      desc: '',
      args: [title, wanted, left],
    );
  }

  /// `{title}: sold out`
  String cart_stock_line_gone(String title) {
    return Intl.message(
      '$title: sold out',
      name: 'cart_stock_line_gone',
      desc: '',
      args: [title],
    );
  }

  /// `Fix my basket for me`
  String get cart_stock_fix {
    return Intl.message(
      'Fix my basket for me',
      name: 'cart_stock_fix',
      desc: '',
      args: [],
    );
  }

  /// `We will lower what we can and take out what is gone.`
  String get cart_stock_fix_note {
    return Intl.message(
      'We will lower what we can and take out what is gone.',
      name: 'cart_stock_fix_note',
      desc: '',
      args: [],
    );
  }

  /// `Leave it as it is`
  String get cart_stock_keep {
    return Intl.message(
      'Leave it as it is',
      name: 'cart_stock_keep',
      desc: '',
      args: [],
    );
  }

  /// `You can change it yourself. Checkout stays closed until you do.`
  String get cart_stock_keep_note {
    return Intl.message(
      'You can change it yourself. Checkout stays closed until you do.',
      name: 'cart_stock_keep_note',
      desc: '',
      args: [],
    );
  }

  /// `Your basket is ready`
  String get cart_stock_fixed {
    return Intl.message(
      'Your basket is ready',
      name: 'cart_stock_fixed',
      desc: '',
      args: [],
    );
  }

  /// `Only {left} left`
  String cart_line_over(int left) {
    return Intl.message(
      'Only $left left',
      name: 'cart_line_over',
      desc: '',
      args: [left],
    );
  }

  /// `You did not attend`
  String get booking_absent_title {
    return Intl.message(
      'You did not attend',
      name: 'booking_absent_title',
      desc: '',
      args: [],
    );
  }

  /// `You did not attend, and the amount will be returned to your in-app balance to use later.`
  String get booking_absent_body {
    return Intl.message(
      'You did not attend, and the amount will be returned to your in-app balance to use later.',
      name: 'booking_absent_body',
      desc: '',
      args: [],
    );
  }

  /// `Attending`
  String get booking_attending_title {
    return Intl.message(
      'Attending',
      name: 'booking_attending_title',
      desc: '',
      args: [],
    );
  }

  /// `Your attendance is recorded — you are in the workshop now.`
  String get booking_attending_body {
    return Intl.message(
      'Your attendance is recorded — you are in the workshop now.',
      name: 'booking_attending_body',
      desc: '',
      args: [],
    );
  }

  /// `Upload a photo of your piece`
  String get booking_upload_piece {
    return Intl.message(
      'Upload a photo of your piece',
      name: 'booking_upload_piece',
      desc: '',
      args: [],
    );
  }

  /// `Upload the remaining photos`
  String get booking_upload_remaining {
    return Intl.message(
      'Upload the remaining photos',
      name: 'booking_upload_remaining',
      desc: '',
      args: [],
    );
  }

  /// `Attending`
  String get booking_status_attending {
    return Intl.message(
      'Attending',
      name: 'booking_status_attending',
      desc: '',
      args: [],
    );
  }

  /// `Did not attend`
  String get booking_status_absent {
    return Intl.message(
      'Did not attend',
      name: 'booking_status_absent',
      desc: '',
      args: [],
    );
  }

  /// `Being prepared`
  String get booking_status_preparing {
    return Intl.message(
      'Being prepared',
      name: 'booking_status_preparing',
      desc: '',
      args: [],
    );
  }

  /// `Being prepared`
  String get booking_preparing_title {
    return Intl.message(
      'Being prepared',
      name: 'booking_preparing_title',
      desc: '',
      args: [],
    );
  }

  /// `Your piece is being finished with care.`
  String get booking_preparing_body {
    return Intl.message(
      'Your piece is being finished with care.',
      name: 'booking_preparing_body',
      desc: '',
      args: [],
    );
  }

  /// `Your piece is being finished with care — ready in {span}.`
  String booking_preparing_body_in(String span) {
    return Intl.message(
      'Your piece is being finished with care — ready in $span.',
      name: 'booking_preparing_body_in',
      desc: '',
      args: [span],
    );
  }

  /// `Your piece is being prepared; the details will be confirmed shortly.`
  String get booking_preparing_body_painted {
    return Intl.message(
      'Your piece is being prepared; the details will be confirmed shortly.',
      name: 'booking_preparing_body_painted',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get booking_cancelled_title {
    return Intl.message(
      'Cancelled',
      name: 'booking_cancelled_title',
      desc: '',
      args: [],
    );
  }

  /// `The workshop has been cancelled. We will let you know about any updates or another date.`
  String get booking_cancelled_body {
    return Intl.message(
      'The workshop has been cancelled. We will let you know about any updates or another date.',
      name: 'booking_cancelled_body',
      desc: '',
      args: [],
    );
  }

  /// `Being wrapped`
  String get booking_packing_title {
    return Intl.message(
      'Being wrapped',
      name: 'booking_packing_title',
      desc: '',
      args: [],
    );
  }

  /// `Your piece is being wrapped and made ready for delivery.`
  String get booking_packing_body {
    return Intl.message(
      'Your piece is being wrapped and made ready for delivery.',
      name: 'booking_packing_body',
      desc: '',
      args: [],
    );
  }

  /// `Out for delivery`
  String get booking_on_the_way_title {
    return Intl.message(
      'Out for delivery',
      name: 'booking_on_the_way_title',
      desc: '',
      args: [],
    );
  }

  /// `Your piece is on its way to you and will arrive soon.`
  String get booking_on_the_way_body {
    return Intl.message(
      'Your piece is on its way to you and will arrive soon.',
      name: 'booking_on_the_way_body',
      desc: '',
      args: [],
    );
  }

  /// `Delivered`
  String get booking_handed_over_title {
    return Intl.message(
      'Delivered',
      name: 'booking_handed_over_title',
      desc: '',
      args: [],
    );
  }

  /// `The workshop is finished and the piece is yours.`
  String get booking_handed_over_body {
    return Intl.message(
      'The workshop is finished and the piece is yours.',
      name: 'booking_handed_over_body',
      desc: '',
      args: [],
    );
  }

  /// `Ready to collect`
  String get delivery_status_awaiting_pickup {
    return Intl.message(
      'Ready to collect',
      name: 'delivery_status_awaiting_pickup',
      desc: '',
      args: [],
    );
  }

  /// `Being wrapped`
  String get delivery_status_getting_ready {
    return Intl.message(
      'Being wrapped',
      name: 'delivery_status_getting_ready',
      desc: '',
      args: [],
    );
  }

  /// `Out for delivery`
  String get delivery_status_on_the_way {
    return Intl.message(
      'Out for delivery',
      name: 'delivery_status_on_the_way',
      desc: '',
      args: [],
    );
  }

  /// `Delivered`
  String get delivery_status_completed {
    return Intl.message(
      'Delivered',
      name: 'delivery_status_completed',
      desc: '',
      args: [],
    );
  }

  /// `Add an address`
  String get address_add {
    return Intl.message(
      'Add an address',
      name: 'address_add',
      desc: '',
      args: [],
    );
  }

  /// `Edit address`
  String get address_edit {
    return Intl.message(
      'Edit address',
      name: 'address_edit',
      desc: '',
      args: [],
    );
  }

  /// `Save address`
  String get address_save {
    return Intl.message(
      'Save address',
      name: 'address_save',
      desc: '',
      args: [],
    );
  }

  /// `Default`
  String get address_default {
    return Intl.message('Default', name: 'address_default', desc: '', args: []);
  }

  /// `Make default`
  String get address_make_default {
    return Intl.message(
      'Make default',
      name: 'address_make_default',
      desc: '',
      args: [],
    );
  }

  /// `Delete`
  String get address_delete {
    return Intl.message('Delete', name: 'address_delete', desc: '', args: []);
  }

  /// `Delete this address?`
  String get address_delete_title {
    return Intl.message(
      'Delete this address?',
      name: 'address_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `You can add it again any time. Nothing else changes.`
  String get address_delete_body {
    return Intl.message(
      'You can add it again any time. Nothing else changes.',
      name: 'address_delete_body',
      desc: '',
      args: [],
    );
  }

  /// `Short national address`
  String get address_short_label {
    return Intl.message(
      'Short national address',
      name: 'address_short_label',
      desc: '',
      args: [],
    );
  }

  /// `ABCD1234`
  String get address_short_hint {
    return Intl.message(
      'ABCD1234',
      name: 'address_short_hint',
      desc: '',
      args: [],
    );
  }

  /// `Eight characters — four letters then four digits. We will fill the rest in for you.`
  String get address_short_help {
    return Intl.message(
      'Eight characters — four letters then four digits. We will fill the rest in for you.',
      name: 'address_short_help',
      desc: '',
      args: [],
    );
  }

  /// `Find`
  String get address_short_find {
    return Intl.message('Find', name: 'address_short_find', desc: '', args: []);
  }

  /// `Four letters then four digits, like ABCD1234.`
  String get address_short_invalid {
    return Intl.message(
      'Four letters then four digits, like ABCD1234.',
      name: 'address_short_invalid',
      desc: '',
      args: [],
    );
  }

  /// `We could not find that code. You can type the address below instead.`
  String get address_short_not_found {
    return Intl.message(
      'We could not find that code. You can type the address below instead.',
      name: 'address_short_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Lookup is not available right now. You can type the address below instead.`
  String get address_short_unavailable {
    return Intl.message(
      'Lookup is not available right now. You can type the address below instead.',
      name: 'address_short_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Give it a moment before trying again.`
  String get address_short_too_fast {
    return Intl.message(
      'Give it a moment before trying again.',
      name: 'address_short_too_fast',
      desc: '',
      args: [],
    );
  }

  /// `Found it — check the details below.`
  String get address_short_found {
    return Intl.message(
      'Found it — check the details below.',
      name: 'address_short_found',
      desc: '',
      args: [],
    );
  }

  /// `or enter it yourself`
  String get address_or_manual {
    return Intl.message(
      'or enter it yourself',
      name: 'address_or_manual',
      desc: '',
      args: [],
    );
  }

  /// `Name this address`
  String get address_label_field {
    return Intl.message(
      'Name this address',
      name: 'address_label_field',
      desc: '',
      args: [],
    );
  }

  /// `Home, work…`
  String get address_label_hint {
    return Intl.message(
      'Home, work…',
      name: 'address_label_hint',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get address_city {
    return Intl.message('City', name: 'address_city', desc: '', args: []);
  }

  /// `Street`
  String get address_street {
    return Intl.message('Street', name: 'address_street', desc: '', args: []);
  }

  /// `District`
  String get address_district {
    return Intl.message(
      'District',
      name: 'address_district',
      desc: '',
      args: [],
    );
  }

  /// `Building number`
  String get address_building {
    return Intl.message(
      'Building number',
      name: 'address_building',
      desc: '',
      args: [],
    );
  }

  /// `Additional number`
  String get address_additional {
    return Intl.message(
      'Additional number',
      name: 'address_additional',
      desc: '',
      args: [],
    );
  }

  /// `Postal code`
  String get address_postal {
    return Intl.message(
      'Postal code',
      name: 'address_postal',
      desc: '',
      args: [],
    );
  }

  /// `Unit number`
  String get address_unit {
    return Intl.message(
      'Unit number',
      name: 'address_unit',
      desc: '',
      args: [],
    );
  }

  /// `Notes for the courier`
  String get address_notes {
    return Intl.message(
      'Notes for the courier',
      name: 'address_notes',
      desc: '',
      args: [],
    );
  }

  /// `Phone for the courier`
  String get address_phone {
    return Intl.message(
      'Phone for the courier',
      name: 'address_phone',
      desc: '',
      args: [],
    );
  }

  /// `Pin on the map`
  String get address_pin {
    return Intl.message(
      'Pin on the map',
      name: 'address_pin',
      desc: '',
      args: [],
    );
  }

  /// `Location set`
  String get address_pin_set {
    return Intl.message(
      'Location set',
      name: 'address_pin_set',
      desc: '',
      args: [],
    );
  }

  /// `Drop a pin so the courier can find you.`
  String get address_pin_missing {
    return Intl.message(
      'Drop a pin so the courier can find you.',
      name: 'address_pin_missing',
      desc: '',
      args: [],
    );
  }

  /// `Address saved`
  String get address_saved {
    return Intl.message(
      'Address saved',
      name: 'address_saved',
      desc: '',
      args: [],
    );
  }

  /// `Address deleted`
  String get address_deleted {
    return Intl.message(
      'Address deleted',
      name: 'address_deleted',
      desc: '',
      args: [],
    );
  }

  /// `{field} is needed`
  String address_required(String field) {
    return Intl.message(
      '$field is needed',
      name: 'address_required',
      desc: '',
      args: [field],
    );
  }

  /// `{count} digits`
  String address_digits_exactly(int count) {
    return Intl.message(
      '$count digits',
      name: 'address_digits_exactly',
      desc: '',
      args: [count],
    );
  }

  /// `e.g. Abi Al Karam Street`
  String get address_hint_street {
    return Intl.message(
      'e.g. Abi Al Karam Street',
      name: 'address_hint_street',
      desc: '',
      args: [],
    );
  }

  /// `e.g. Al Dhobbat`
  String get address_hint_district {
    return Intl.message(
      'e.g. Al Dhobbat',
      name: 'address_hint_district',
      desc: '',
      args: [],
    );
  }

  /// `4359`
  String get address_hint_building {
    return Intl.message(
      '4359',
      name: 'address_hint_building',
      desc: '',
      args: [],
    );
  }

  /// `2817`
  String get address_hint_additional {
    return Intl.message(
      '2817',
      name: 'address_hint_additional',
      desc: '',
      args: [],
    );
  }

  /// `12627`
  String get address_hint_postal {
    return Intl.message(
      '12627',
      name: 'address_hint_postal',
      desc: '',
      args: [],
    );
  }

  /// `12`
  String get address_hint_unit {
    return Intl.message('12', name: 'address_hint_unit', desc: '', args: []);
  }

  /// `05XXXXXXXX`
  String get address_hint_phone {
    return Intl.message(
      '05XXXXXXXX',
      name: 'address_hint_phone',
      desc: '',
      args: [],
    );
  }

  /// `Blue door, second floor`
  String get address_hint_notes {
    return Intl.message(
      'Blue door, second floor',
      name: 'address_hint_notes',
      desc: '',
      args: [],
    );
  }

  /// `Map is unavailable — we set your city centre for now.`
  String get address_pin_fallback {
    return Intl.message(
      'Map is unavailable — we set your city centre for now.',
      name: 'address_pin_fallback',
      desc: '',
      args: [],
    );
  }

  /// `Saved address`
  String get address_unnamed {
    return Intl.message(
      'Saved address',
      name: 'address_unnamed',
      desc: '',
      args: [],
    );
  }

  /// `Bldg {n}`
  String address_building_short(String n) {
    return Intl.message(
      'Bldg $n',
      name: 'address_building_short',
      desc: '',
      args: [n],
    );
  }

  /// `Unit {n}`
  String address_unit_short(String n) {
    return Intl.message(
      'Unit $n',
      name: 'address_unit_short',
      desc: '',
      args: [n],
    );
  }

  /// `P.O. {n}`
  String address_postal_short(String n) {
    return Intl.message(
      'P.O. $n',
      name: 'address_postal_short',
      desc: '',
      args: [n],
    );
  }

  /// `Collect it yourself?`
  String get delivery_pickup_confirm_title {
    return Intl.message(
      'Collect it yourself?',
      name: 'delivery_pickup_confirm_title',
      desc: '',
      args: [],
    );
  }

  /// `We will hold your piece at the studio, and you can switch back to delivery any time before you collect it.`
  String get delivery_pickup_confirm_body {
    return Intl.message(
      'We will hold your piece at the studio, and you can switch back to delivery any time before you collect it.',
      name: 'delivery_pickup_confirm_body',
      desc: '',
      args: [],
    );
  }

  /// `We will hold your piece at the studio. {amount} goes back to your Terracotta balance — not to your card — and you can switch back any time before you collect it.`
  String delivery_pickup_confirm_body_refund(Object amount) {
    return Intl.message(
      'We will hold your piece at the studio. $amount goes back to your Terracotta balance — not to your card — and you can switch back any time before you collect it.',
      name: 'delivery_pickup_confirm_body_refund',
      desc: '',
      args: [amount],
    );
  }

  /// `{amount} is back in your Terracotta balance.`
  String delivery_pickup_credited(Object amount) {
    return Intl.message(
      '$amount is back in your Terracotta balance.',
      name: 'delivery_pickup_credited',
      desc: '',
      args: [amount],
    );
  }

  /// `You will collect it from the studio.`
  String get delivery_pickup_done {
    return Intl.message(
      'You will collect it from the studio.',
      name: 'delivery_pickup_done',
      desc: '',
      args: [],
    );
  }

  /// `Yes, I will collect it`
  String get delivery_pickup_confirm_yes {
    return Intl.message(
      'Yes, I will collect it',
      name: 'delivery_pickup_confirm_yes',
      desc: '',
      args: [],
    );
  }

  /// `You are collecting this from the studio`
  String get delivery_chose_pickup {
    return Intl.message(
      'You are collecting this from the studio',
      name: 'delivery_chose_pickup',
      desc: '',
      args: [],
    );
  }

  /// `This piece is being delivered to you`
  String get delivery_chose_delivery {
    return Intl.message(
      'This piece is being delivered to you',
      name: 'delivery_chose_delivery',
      desc: '',
      args: [],
    );
  }

  /// `Have it delivered instead`
  String get delivery_switch_to_delivery {
    return Intl.message(
      'Have it delivered instead',
      name: 'delivery_switch_to_delivery',
      desc: '',
      args: [],
    );
  }

  /// `Collect it myself instead`
  String get delivery_switch_to_pickup {
    return Intl.message(
      'Collect it myself instead',
      name: 'delivery_switch_to_pickup',
      desc: '',
      args: [],
    );
  }

  /// `Where should we send it?`
  String get delivery_where_title {
    return Intl.message(
      'Where should we send it?',
      name: 'delivery_where_title',
      desc: '',
      args: [],
    );
  }

  /// `Send it somewhere else`
  String get delivery_change_address {
    return Intl.message(
      'Send it somewhere else',
      name: 'delivery_change_address',
      desc: '',
      args: [],
    );
  }

  /// `Add a new address`
  String get delivery_add_address {
    return Intl.message(
      'Add a new address',
      name: 'delivery_add_address',
      desc: '',
      args: [],
    );
  }

  /// `You have no saved address yet.`
  String get delivery_no_address {
    return Intl.message(
      'You have no saved address yet.',
      name: 'delivery_no_address',
      desc: '',
      args: [],
    );
  }

  /// `Continue to payment`
  String get delivery_continue {
    return Intl.message(
      'Continue to payment',
      name: 'delivery_continue',
      desc: '',
      args: [],
    );
  }

  /// `Contact us`
  String get complaint_title {
    return Intl.message(
      'Contact us',
      name: 'complaint_title',
      desc: '',
      args: [],
    );
  }

  /// `New complaint`
  String get complaint_new {
    return Intl.message(
      'New complaint',
      name: 'complaint_new',
      desc: '',
      args: [],
    );
  }

  /// `My complaints`
  String get complaint_mine {
    return Intl.message(
      'My complaints',
      name: 'complaint_mine',
      desc: '',
      args: [],
    );
  }

  /// `You have not sent anything yet.`
  String get complaint_empty {
    return Intl.message(
      'You have not sent anything yet.',
      name: 'complaint_empty',
      desc: '',
      args: [],
    );
  }

  /// `If something went wrong with an order or a booking, tell us and we will come back to you.`
  String get complaint_empty_body {
    return Intl.message(
      'If something went wrong with an order or a booking, tell us and we will come back to you.',
      name: 'complaint_empty_body',
      desc: '',
      args: [],
    );
  }

  /// `Subject`
  String get complaint_type {
    return Intl.message('Subject', name: 'complaint_type', desc: '', args: []);
  }

  /// `Order or booking number (optional)`
  String get complaint_reference {
    return Intl.message(
      'Order or booking number (optional)',
      name: 'complaint_reference',
      desc: '',
      args: [],
    );
  }

  /// `38079300`
  String get complaint_reference_hint {
    return Intl.message(
      '38079300',
      name: 'complaint_reference_hint',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get complaint_message {
    return Intl.message(
      'Details',
      name: 'complaint_message',
      desc: '',
      args: [],
    );
  }

  /// `Tell us what happened…`
  String get complaint_message_hint {
    return Intl.message(
      'Tell us what happened…',
      name: 'complaint_message_hint',
      desc: '',
      args: [],
    );
  }

  /// `Your name`
  String get complaint_name {
    return Intl.message(
      'Your name',
      name: 'complaint_name',
      desc: '',
      args: [],
    );
  }

  /// `Phone or email to reach you`
  String get complaint_contact {
    return Intl.message(
      'Phone or email to reach you',
      name: 'complaint_contact',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get complaint_send {
    return Intl.message('Send', name: 'complaint_send', desc: '', args: []);
  }

  /// `We have your message, and we will come back to you.`
  String get complaint_sent {
    return Intl.message(
      'We have your message, and we will come back to you.',
      name: 'complaint_sent',
      desc: '',
      args: [],
    );
  }

  /// `A shop order`
  String get complaint_type_order {
    return Intl.message(
      'A shop order',
      name: 'complaint_type_order',
      desc: '',
      args: [],
    );
  }

  /// `A workshop`
  String get complaint_type_workshop {
    return Intl.message(
      'A workshop',
      name: 'complaint_type_workshop',
      desc: '',
      args: [],
    );
  }

  /// `Delivery`
  String get complaint_type_delivery {
    return Intl.message(
      'Delivery',
      name: 'complaint_type_delivery',
      desc: '',
      args: [],
    );
  }

  /// `Payment`
  String get complaint_type_payment {
    return Intl.message(
      'Payment',
      name: 'complaint_type_payment',
      desc: '',
      args: [],
    );
  }

  /// `Something else`
  String get complaint_type_other {
    return Intl.message(
      'Something else',
      name: 'complaint_type_other',
      desc: '',
      args: [],
    );
  }

  /// `New`
  String get complaint_status_new {
    return Intl.message(
      'New',
      name: 'complaint_status_new',
      desc: '',
      args: [],
    );
  }

  /// `In progress`
  String get complaint_status_in_progress {
    return Intl.message(
      'In progress',
      name: 'complaint_status_in_progress',
      desc: '',
      args: [],
    );
  }

  /// `Resolved`
  String get complaint_status_resolved {
    return Intl.message(
      'Resolved',
      name: 'complaint_status_resolved',
      desc: '',
      args: [],
    );
  }

  /// `Closed`
  String get complaint_status_closed {
    return Intl.message(
      'Closed',
      name: 'complaint_status_closed',
      desc: '',
      args: [],
    );
  }

  /// `This session starts too soon to be cancelled or rescheduled.`
  String get booking_confirmed_body_final {
    return Intl.message(
      'This session starts too soon to be cancelled or rescheduled.',
      name: 'booking_confirmed_body_final',
      desc: '',
      args: [],
    );
  }

  /// `Name this piece`
  String get booking_piece_label {
    return Intl.message(
      'Name this piece',
      name: 'booking_piece_label',
      desc: '',
      args: [],
    );
  }

  /// `My cup`
  String get booking_piece_label_hint {
    return Intl.message(
      'My cup',
      name: 'booking_piece_label_hint',
      desc: '',
      args: [],
    );
  }

  /// `Give every person a name.`
  String get booking_piece_label_required {
    return Intl.message(
      'Give every person a name.',
      name: 'booking_piece_label_required',
      desc: '',
      args: [],
    );
  }

  /// `Somebody else already has this name.`
  String get booking_name_taken {
    return Intl.message(
      'Somebody else already has this name.',
      name: 'booking_name_taken',
      desc: '',
      args: [],
    );
  }

  /// `Another piece already has this name.`
  String get booking_piece_name_taken {
    return Intl.message(
      'Another piece already has this name.',
      name: 'booking_piece_name_taken',
      desc: '',
      args: [],
    );
  }

  /// `{count} photo(s) left`
  String booking_photos_left(String count) {
    return Intl.message(
      '$count photo(s) left',
      name: 'booking_photos_left',
      desc: '',
      args: [count],
    );
  }

  /// `That's every photo for this booking.`
  String get booking_photos_full {
    return Intl.message(
      'That\'s every photo for this booking.',
      name: 'booking_photos_full',
      desc: '',
      args: [],
    );
  }

  /// `Piece {index}`
  String booking_piece_number(Object index) {
    return Intl.message(
      'Piece $index',
      name: 'booking_piece_number',
      desc: '',
      args: [index],
    );
  }

  /// `Add at least one photo of this piece.`
  String get booking_piece_needs_photo {
    return Intl.message(
      'Add at least one photo of this piece.',
      name: 'booking_piece_needs_photo',
      desc: '',
      args: [],
    );
  }

  /// `Piece {index}`
  String booking_piece_hint(Object index) {
    return Intl.message(
      'Piece $index',
      name: 'booking_piece_hint',
      desc: '',
      args: [index],
    );
  }

  /// `Their name`
  String get booking_person_name_hint {
    return Intl.message(
      'Their name',
      name: 'booking_person_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Everyone on this booking already has a piece. Add more photos to one of them below.`
  String get booking_all_named {
    return Intl.message(
      'Everyone on this booking already has a piece. Add more photos to one of them below.',
      name: 'booking_all_named',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get booking_piece_name {
    return Intl.message('Name', name: 'booking_piece_name', desc: '', args: []);
  }

  /// `Name changed`
  String get booking_piece_renamed {
    return Intl.message(
      'Name changed',
      name: 'booking_piece_renamed',
      desc: '',
      args: [],
    );
  }

  /// `Add photos for {name}`
  String booking_add_photos_for(String name) {
    return Intl.message(
      'Add photos for $name',
      name: 'booking_add_photos_for',
      desc: '',
      args: [name],
    );
  }

  /// `Edit the person’s name`
  String get booking_edit_person_name {
    return Intl.message(
      'Edit the person’s name',
      name: 'booking_edit_person_name',
      desc: '',
      args: [],
    );
  }

  /// `Edit the piece’s name`
  String get booking_edit_piece_name {
    return Intl.message(
      'Edit the piece’s name',
      name: 'booking_edit_piece_name',
      desc: '',
      args: [],
    );
  }

  /// `Earlier`
  String get booking_photos_old {
    return Intl.message(
      'Earlier',
      name: 'booking_photos_old',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get booking_save {
    return Intl.message('Save', name: 'booking_save', desc: '', args: []);
  }

  /// `Done`
  String get booking_done {
    return Intl.message('Done', name: 'booking_done', desc: '', args: []);
  }

  /// `Person {index}`
  String booking_person_hint(Object index) {
    return Intl.message(
      'Person $index',
      name: 'booking_person_hint',
      desc: '',
      args: [index],
    );
  }

  /// `Next`
  String get booking_next {
    return Intl.message('Next', name: 'booking_next', desc: '', args: []);
  }

  /// `Back`
  String get booking_back {
    return Intl.message('Back', name: 'booking_back', desc: '', args: []);
  }

  /// `Add photos`
  String get booking_upload_photos {
    return Intl.message(
      'Add photos',
      name: 'booking_upload_photos',
      desc: '',
      args: [],
    );
  }

  /// `Upload`
  String get booking_upload_send {
    return Intl.message(
      'Upload',
      name: 'booking_upload_send',
      desc: '',
      args: [],
    );
  }

  /// `Photos uploaded.`
  String get booking_photos_uploaded {
    return Intl.message(
      'Photos uploaded.',
      name: 'booking_photos_uploaded',
      desc: '',
      args: [],
    );
  }

  /// `Show this code when you arrive — starting shortly.`
  String get booking_scan_on_arrival_soon {
    return Intl.message(
      'Show this code when you arrive — starting shortly.',
      name: 'booking_scan_on_arrival_soon',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get booking_filter_all {
    return Intl.message('All', name: 'booking_filter_all', desc: '', args: []);
  }

  /// `Add more`
  String get booking_add_more_photos {
    return Intl.message(
      'Add more',
      name: 'booking_add_more_photos',
      desc: '',
      args: [],
    );
  }

  /// `Photo removed.`
  String get booking_photo_removed {
    return Intl.message(
      'Photo removed.',
      name: 'booking_photo_removed',
      desc: '',
      args: [],
    );
  }

  /// `Piece removed.`
  String get booking_piece_removed {
    return Intl.message(
      'Piece removed.',
      name: 'booking_piece_removed',
      desc: '',
      args: [],
    );
  }

  /// `Remove this photo?`
  String get booking_remove_photo_title {
    return Intl.message(
      'Remove this photo?',
      name: 'booking_remove_photo_title',
      desc: '',
      args: [],
    );
  }

  /// `It is the only way to replace it — there is no swap.`
  String get booking_remove_photo_body {
    return Intl.message(
      'It is the only way to replace it — there is no swap.',
      name: 'booking_remove_photo_body',
      desc: '',
      args: [],
    );
  }

  /// `Remove {label}?`
  String booking_remove_piece_title(String label) {
    return Intl.message(
      'Remove $label?',
      name: 'booking_remove_piece_title',
      desc: '',
      args: [label],
    );
  }

  /// `Every photo of it goes too.`
  String get booking_remove_piece_body {
    return Intl.message(
      'Every photo of it goes too.',
      name: 'booking_remove_piece_body',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{1 photo} other{{count} photos}}`
  String booking_piece_photo_count(num count) {
    return Intl.plural(
      count,
      one: '1 photo',
      other: '$count photos',
      name: 'booking_piece_photo_count',
      desc: '',
      args: [count],
    );
  }

  /// `Front desk`
  String get scan_desk_title {
    return Intl.message(
      'Front desk',
      name: 'scan_desk_title',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get scan_today {
    return Intl.message('Today', name: 'scan_today', desc: '', args: []);
  }

  /// `No sessions booked today`
  String get scan_no_sessions {
    return Intl.message(
      'No sessions booked today',
      name: 'scan_no_sessions',
      desc: '',
      args: [],
    );
  }

  /// `Nobody has booked a workshop for this day yet.`
  String get scan_no_sessions_body {
    return Intl.message(
      'Nobody has booked a workshop for this day yet.',
      name: 'scan_no_sessions_body',
      desc: '',
      args: [],
    );
  }

  /// `Scan a code`
  String get scan_scan_code {
    return Intl.message(
      'Scan a code',
      name: 'scan_scan_code',
      desc: '',
      args: [],
    );
  }

  /// `Enter code`
  String get scan_enter_code {
    return Intl.message(
      'Enter code',
      name: 'scan_enter_code',
      desc: '',
      args: [],
    );
  }

  /// `8 digits`
  String get scan_code_hint {
    return Intl.message('8 digits', name: 'scan_code_hint', desc: '', args: []);
  }

  /// `Start session`
  String get scan_start_session {
    return Intl.message(
      'Start session',
      name: 'scan_start_session',
      desc: '',
      args: [],
    );
  }

  /// `Finish session`
  String get scan_finish_session {
    return Intl.message(
      'Finish session',
      name: 'scan_finish_session',
      desc: '',
      args: [],
    );
  }

  /// `Start the session?`
  String get scan_start_warning_title {
    return Intl.message(
      'Start the session?',
      name: 'scan_start_warning_title',
      desc: '',
      args: [],
    );
  }

  /// `Everyone who has not been scanned in is marked absent. This cannot be undone, and a no-show is not refunded.`
  String get scan_start_warning_body {
    return Intl.message(
      'Everyone who has not been scanned in is marked absent. This cannot be undone, and a no-show is not refunded.',
      name: 'scan_start_warning_body',
      desc: '',
      args: [],
    );
  }

  /// `Finish the session?`
  String get scan_finish_warning_title {
    return Intl.message(
      'Finish the session?',
      name: 'scan_finish_warning_title',
      desc: '',
      args: [],
    );
  }

  /// `Everyone attending moves on to the next stage.`
  String get scan_finish_warning_body {
    return Intl.message(
      'Everyone attending moves on to the next stage.',
      name: 'scan_finish_warning_body',
      desc: '',
      args: [],
    );
  }

  /// `Check-in closed`
  String get scan_session_closed {
    return Intl.message(
      'Check-in closed',
      name: 'scan_session_closed',
      desc: '',
      args: [],
    );
  }

  /// `Finished at {time}`
  String scan_session_closed_at(Object time) {
    return Intl.message(
      'Finished at $time',
      name: 'scan_session_closed_at',
      desc: '',
      args: [time],
    );
  }

  /// `This session has been finished, so nobody else can be checked in to it.`
  String get scan_check_in_closed_body {
    return Intl.message(
      'This session has been finished, so nobody else can be checked in to it.',
      name: 'scan_check_in_closed_body',
      desc: '',
      args: [],
    );
  }

  /// `{done} of {expected} pieces`
  String scan_pieces_progress(Object done, Object expected) {
    return Intl.message(
      '$done of $expected pieces',
      name: 'scan_pieces_progress',
      desc: '',
      args: [done, expected],
    );
  }

  /// `Some pieces have not been photographed`
  String get scan_finish_missing_title {
    return Intl.message(
      'Some pieces have not been photographed',
      name: 'scan_finish_missing_title',
      desc: '',
      args: [],
    );
  }

  /// `Once you finish, no photo can be added to these bookings. Find these customers first.`
  String get scan_finish_missing_body {
    return Intl.message(
      'Once you finish, no photo can be added to these bookings. Find these customers first.',
      name: 'scan_finish_missing_body',
      desc: '',
      args: [],
    );
  }

  /// `Everyone has photographed their pieces.`
  String get scan_finish_all_done {
    return Intl.message(
      'Everyone has photographed their pieces.',
      name: 'scan_finish_all_done',
      desc: '',
      args: [],
    );
  }

  /// `{name} — {done} of {expected}`
  String scan_missing_row(Object name, Object done, Object expected) {
    return Intl.message(
      '$name — $done of $expected',
      name: 'scan_missing_row',
      desc: '',
      args: [name, done, expected],
    );
  }

  /// `Finish anyway`
  String get scan_finish_anyway {
    return Intl.message(
      'Finish anyway',
      name: 'scan_finish_anyway',
      desc: '',
      args: [],
    );
  }

  /// `Session started.`
  String get scan_session_started {
    return Intl.message(
      'Session started.',
      name: 'scan_session_started',
      desc: '',
      args: [],
    );
  }

  /// `Session finished.`
  String get scan_session_finished {
    return Intl.message(
      'Session finished.',
      name: 'scan_session_finished',
      desc: '',
      args: [],
    );
  }

  /// `{arrived} of {total} arrived`
  String scan_arrived(String arrived, String total) {
    return Intl.message(
      '$arrived of $total arrived',
      name: 'scan_arrived',
      desc: '',
      args: [arrived, total],
    );
  }

  /// `How many arrived?`
  String get scan_how_many_title {
    return Intl.message(
      'How many arrived?',
      name: 'scan_how_many_title',
      desc: '',
      args: [],
    );
  }

  /// `{name} booked for {count}. Nothing is saved until you say.`
  String scan_how_many_body(String name, String count) {
    return Intl.message(
      '$name booked for $count. Nothing is saved until you say.',
      name: 'scan_how_many_body',
      desc: '',
      args: [name, count],
    );
  }

  /// `Check in`
  String get scan_confirm_count {
    return Intl.message(
      'Check in',
      name: 'scan_confirm_count',
      desc: '',
      args: [],
    );
  }

  /// `{name} checked in`
  String scan_checked_in(String name) {
    return Intl.message(
      '$name checked in',
      name: 'scan_checked_in',
      desc: '',
      args: [name],
    );
  }

  /// `{name} is already checked in`
  String scan_already_in(String name) {
    return Intl.message(
      '$name is already checked in',
      name: 'scan_already_in',
      desc: '',
      args: [name],
    );
  }

  /// `Point the camera at the customer’s code`
  String get scan_point_camera {
    return Intl.message(
      'Point the camera at the customer’s code',
      name: 'scan_point_camera',
      desc: '',
      args: [],
    );
  }

  /// `The camera is not available. Type the code instead.`
  String get scan_camera_denied {
    return Intl.message(
      'The camera is not available. Type the code instead.',
      name: 'scan_camera_denied',
      desc: '',
      args: [],
    );
  }

  /// `Sign out`
  String get scan_sign_out {
    return Intl.message('Sign out', name: 'scan_sign_out', desc: '', args: []);
  }

  /// `{booked} of {capacity}`
  String scan_seats(String booked, String capacity) {
    return Intl.message(
      '$booked of $capacity',
      name: 'scan_seats',
      desc: '',
      args: [booked, capacity],
    );
  }

  /// `Previous day`
  String get scan_previous_day {
    return Intl.message(
      'Previous day',
      name: 'scan_previous_day',
      desc: '',
      args: [],
    );
  }

  /// `Next day`
  String get scan_next_day {
    return Intl.message('Next day', name: 'scan_next_day', desc: '', args: []);
  }

  /// `Back to today`
  String get scan_back_to_today {
    return Intl.message(
      'Back to today',
      name: 'scan_back_to_today',
      desc: '',
      args: [],
    );
  }

  /// `Sessions can only be started or finished on the day they run.`
  String get scan_not_today {
    return Intl.message(
      'Sessions can only be started or finished on the day they run.',
      name: 'scan_not_today',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, one{1 day} other{{count} days}}`
  String booking_unit_days(num count) {
    return Intl.plural(
      count,
      one: '1 day',
      other: '$count days',
      name: 'booking_unit_days',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, one{1 hour} other{{count} hours}}`
  String booking_unit_hours(num count) {
    return Intl.plural(
      count,
      one: '1 hour',
      other: '$count hours',
      name: 'booking_unit_hours',
      desc: '',
      args: [count],
    );
  }

  /// `{days} and {hours}`
  String booking_unit_days_hours(String days, String hours) {
    return Intl.message(
      '$days and $hours',
      name: 'booking_unit_days_hours',
      desc: '',
      args: [days, hours],
    );
  }

  /// `All`
  String get profile_notif_filter_all {
    return Intl.message(
      'All',
      name: 'profile_notif_filter_all',
      desc: '',
      args: [],
    );
  }

  /// `Unread`
  String get profile_notif_filter_unread {
    return Intl.message(
      'Unread',
      name: 'profile_notif_filter_unread',
      desc: '',
      args: [],
    );
  }

  /// `Bookings`
  String get profile_notif_filter_bookings {
    return Intl.message(
      'Bookings',
      name: 'profile_notif_filter_bookings',
      desc: '',
      args: [],
    );
  }

  /// `Reminders`
  String get profile_notif_filter_reminders {
    return Intl.message(
      'Reminders',
      name: 'profile_notif_filter_reminders',
      desc: '',
      args: [],
    );
  }

  /// `Pieces`
  String get profile_notif_filter_pieces {
    return Intl.message(
      'Pieces',
      name: 'profile_notif_filter_pieces',
      desc: '',
      args: [],
    );
  }

  /// `Orders`
  String get profile_notif_filter_orders {
    return Intl.message(
      'Orders',
      name: 'profile_notif_filter_orders',
      desc: '',
      args: [],
    );
  }

  /// `Gifts`
  String get profile_notif_filter_gifts {
    return Intl.message(
      'Gifts',
      name: 'profile_notif_filter_gifts',
      desc: '',
      args: [],
    );
  }

  /// `Wallet`
  String get profile_notif_filter_wallet {
    return Intl.message(
      'Wallet',
      name: 'profile_notif_filter_wallet',
      desc: '',
      args: [],
    );
  }

  /// `Nothing here right now`
  String get profile_notif_none_in_filter {
    return Intl.message(
      'Nothing here right now',
      name: 'profile_notif_none_in_filter',
      desc: '',
      args: [],
    );
  }

  /// `A gift for you`
  String get gift_claim_title {
    return Intl.message(
      'A gift for you',
      name: 'gift_claim_title',
      desc: '',
      args: [],
    );
  }

  /// `From {name}`
  String gift_claim_from(String name) {
    return Intl.message(
      'From $name',
      name: 'gift_claim_from',
      desc: '',
      args: [name],
    );
  }

  /// `To {name}`
  String gift_claim_to(String name) {
    return Intl.message(
      'To $name',
      name: 'gift_claim_to',
      desc: '',
      args: [name],
    );
  }

  /// `Add to my wallet`
  String get gift_claim_cta {
    return Intl.message(
      'Add to my wallet',
      name: 'gift_claim_cta',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to add it to your wallet.`
  String get gift_claim_signed_out {
    return Intl.message(
      'Sign in to add it to your wallet.',
      name: 'gift_claim_signed_out',
      desc: '',
      args: [],
    );
  }

  /// `This gift has already been claimed.`
  String get gift_claim_already {
    return Intl.message(
      'This gift has already been claimed.',
      name: 'gift_claim_already',
      desc: '',
      args: [],
    );
  }

  /// `This gift cannot be claimed.`
  String get gift_claim_unavailable {
    return Intl.message(
      'This gift cannot be claimed.',
      name: 'gift_claim_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `It is in your wallet`
  String get gift_claim_done_title {
    return Intl.message(
      'It is in your wallet',
      name: 'gift_claim_done_title',
      desc: '',
      args: [],
    );
  }

  /// `{amount} was added. Your balance is now {balance}.`
  String gift_claim_done_body(String amount, String balance) {
    return Intl.message(
      '$amount was added. Your balance is now $balance.',
      name: 'gift_claim_done_body',
      desc: '',
      args: [amount, balance],
    );
  }

  /// `Open my wallet`
  String get gift_claim_open_wallet {
    return Intl.message(
      'Open my wallet',
      name: 'gift_claim_open_wallet',
      desc: '',
      args: [],
    );
  }

  /// `We could not find this gift. The link may be wrong, or the person sending it may not have finished paying for it yet.`
  String get gift_claim_not_found {
    return Intl.message(
      'We could not find this gift. The link may be wrong, or the person sending it may not have finished paying for it yet.',
      name: 'gift_claim_not_found',
      desc: '',
      args: [],
    );
  }

  /// `Browse the studio`
  String get gift_claim_browse {
    return Intl.message(
      'Browse the studio',
      name: 'gift_claim_browse',
      desc: '',
      args: [],
    );
  }

  /// `Move this booking?`
  String get booking_reschedule_confirm_title {
    return Intl.message(
      'Move this booking?',
      name: 'booking_reschedule_confirm_title',
      desc: '',
      args: [],
    );
  }

  /// `Your seats move to the new time. The old one is released.`
  String get booking_reschedule_confirm_body {
    return Intl.message(
      'Your seats move to the new time. The old one is released.',
      name: 'booking_reschedule_confirm_body',
      desc: '',
      args: [],
    );
  }

  /// `Move it`
  String get booking_reschedule_confirm_yes {
    return Intl.message(
      'Move it',
      name: 'booking_reschedule_confirm_yes',
      desc: '',
      args: [],
    );
  }

  /// `Priced per piece`
  String get workshop_price_per_piece {
    return Intl.message(
      'Priced per piece',
      name: 'workshop_price_per_piece',
      desc: '',
      args: [],
    );
  }

  /// `You will have {days} to collect your piece once it is ready.`
  String workshop_piece_hold(String days) {
    return Intl.message(
      'You will have $days to collect your piece once it is ready.',
      name: 'workshop_piece_hold',
      desc: '',
      args: [days],
    );
  }

  /// `Women only`
  String get workshop_audience_women {
    return Intl.message(
      'Women only',
      name: 'workshop_audience_women',
      desc: '',
      args: [],
    );
  }

  /// `Men only`
  String get workshop_audience_men {
    return Intl.message(
      'Men only',
      name: 'workshop_audience_men',
      desc: '',
      args: [],
    );
  }

  /// `Couples`
  String get workshop_audience_couples {
    return Intl.message(
      'Couples',
      name: 'workshop_audience_couples',
      desc: '',
      args: [],
    );
  }

  /// `Kids`
  String get workshop_audience_kids {
    return Intl.message(
      'Kids',
      name: 'workshop_audience_kids',
      desc: '',
      args: [],
    );
  }

  /// `Families`
  String get workshop_audience_families {
    return Intl.message(
      'Families',
      name: 'workshop_audience_families',
      desc: '',
      args: [],
    );
  }

  /// `Everyone welcome`
  String get workshop_audience_mixed {
    return Intl.message(
      'Everyone welcome',
      name: 'workshop_audience_mixed',
      desc: '',
      args: [],
    );
  }

  /// `{count} of this already in your cart.`
  String shop_in_cart_already(String count) {
    return Intl.message(
      '$count of this already in your cart.',
      name: 'shop_in_cart_already',
      desc: '',
      args: [count],
    );
  }

  /// `That is all we can add — you already have {count} of this in your cart.`
  String shop_cart_full_for_item(String count) {
    return Intl.message(
      'That is all we can add — you already have $count of this in your cart.',
      name: 'shop_cart_full_for_item',
      desc: '',
      args: [count],
    );
  }

  /// `Pick a city — it sets the delivery fee.`
  String get address_city_required {
    return Intl.message(
      'Pick a city — it sets the delivery fee.',
      name: 'address_city_required',
      desc: '',
      args: [],
    );
  }

  /// `We could not load the cities. Pull to try again.`
  String get address_zones_empty {
    return Intl.message(
      'We could not load the cities. Pull to try again.',
      name: 'address_zones_empty',
      desc: '',
      args: [],
    );
  }

  /// `Choose where this is going.`
  String get checkout_address_required {
    return Intl.message(
      'Choose where this is going.',
      name: 'checkout_address_required',
      desc: '',
      args: [],
    );
  }

  /// `Order`
  String get shop_sort_label {
    return Intl.message('Order', name: 'shop_sort_label', desc: '', args: []);
  }

  /// `The studio’s order`
  String get shop_sort_default {
    return Intl.message(
      'The studio’s order',
      name: 'shop_sort_default',
      desc: '',
      args: [],
    );
  }

  /// `Newest first`
  String get shop_sort_newest {
    return Intl.message(
      'Newest first',
      name: 'shop_sort_newest',
      desc: '',
      args: [],
    );
  }

  /// `Price: low to high`
  String get shop_sort_price_asc {
    return Intl.message(
      'Price: low to high',
      name: 'shop_sort_price_asc',
      desc: '',
      args: [],
    );
  }

  /// `Price: high to low`
  String get shop_sort_price_desc {
    return Intl.message(
      'Price: high to low',
      name: 'shop_sort_price_desc',
      desc: '',
      args: [],
    );
  }

  /// `Your current time`
  String get booking_slot_current {
    return Intl.message(
      'Your current time',
      name: 'booking_slot_current',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get shop_price_range {
    return Intl.message('Price', name: 'shop_price_range', desc: '', args: []);
  }

  /// `From`
  String get shop_price_min {
    return Intl.message('From', name: 'shop_price_min', desc: '', args: []);
  }

  /// `To`
  String get shop_price_max {
    return Intl.message('To', name: 'shop_price_max', desc: '', args: []);
  }

  /// `“To” cannot be below “From”.`
  String get shop_price_range_invalid {
    return Intl.message(
      '“To” cannot be below “From”.',
      name: 'shop_price_range_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Contact us`
  String get profile_contact_us {
    return Intl.message(
      'Contact us',
      name: 'profile_contact_us',
      desc: '',
      args: [],
    );
  }

  /// `Reach the studio directly, or follow along.`
  String get profile_contact_body {
    return Intl.message(
      'Reach the studio directly, or follow along.',
      name: 'profile_contact_body',
      desc: '',
      args: [],
    );
  }

  /// `Follow the studio`
  String get profile_contact_social {
    return Intl.message(
      'Follow the studio',
      name: 'profile_contact_social',
      desc: '',
      args: [],
    );
  }

  /// `The studio has not published a way to reach it yet.`
  String get profile_contact_empty {
    return Intl.message(
      'The studio has not published a way to reach it yet.',
      name: 'profile_contact_empty',
      desc: '',
      args: [],
    );
  }

  /// `Send a complaint`
  String get complaint_send_title {
    return Intl.message(
      'Send a complaint',
      name: 'complaint_send_title',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get settings_language {
    return Intl.message(
      'Language',
      name: 'settings_language',
      desc: '',
      args: [],
    );
  }

  /// `Text size`
  String get settings_text_size {
    return Intl.message(
      'Text size',
      name: 'settings_text_size',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get settings_notifications {
    return Intl.message(
      'Notifications',
      name: 'settings_notifications',
      desc: '',
      args: [],
    );
  }

  /// `On — you will hear about your bookings and orders.`
  String get settings_notifications_on {
    return Intl.message(
      'On — you will hear about your bookings and orders.',
      name: 'settings_notifications_on',
      desc: '',
      args: [],
    );
  }

  /// `Off. Turn them on to hear about your bookings and orders.`
  String get settings_notifications_off {
    return Intl.message(
      'Off. Turn them on to hear about your bookings and orders.',
      name: 'settings_notifications_off',
      desc: '',
      args: [],
    );
  }

  /// `Open notification settings`
  String get settings_notifications_open {
    return Intl.message(
      'Open notification settings',
      name: 'settings_notifications_open',
      desc: '',
      args: [],
    );
  }

  /// `Version {version}`
  String settings_version(String version) {
    return Intl.message(
      'Version $version',
      name: 'settings_version',
      desc: '',
      args: [version],
    );
  }

  /// `This studio signs in with a credential this app cannot ask for yet. Please get in touch.`
  String get auth_identifier_unsupported {
    return Intl.message(
      'This studio signs in with a credential this app cannot ask for yet. Please get in touch.',
      name: 'auth_identifier_unsupported',
      desc: '',
      args: [],
    );
  }

  /// `Appearance`
  String get settings_theme {
    return Intl.message(
      'Appearance',
      name: 'settings_theme',
      desc: '',
      args: [],
    );
  }

  /// `The studio’s design is drawn light. Dark is built to match it.`
  String get settings_theme_note {
    return Intl.message(
      'The studio’s design is drawn light. Dark is built to match it.',
      name: 'settings_theme_note',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to see your notifications`
  String get profile_notif_signed_out {
    return Intl.message(
      'Sign in to see your notifications',
      name: 'profile_notif_signed_out',
      desc: '',
      args: [],
    );
  }

  /// `Booking confirmations, order updates and studio news all land here.`
  String get profile_notif_signed_out_body {
    return Intl.message(
      'Booking confirmations, order updates and studio news all land here.',
      name: 'profile_notif_signed_out_body',
      desc: '',
      args: [],
    );
  }

  /// `No sessions booked that day`
  String get scan_no_sessions_day {
    return Intl.message(
      'No sessions booked that day',
      name: 'scan_no_sessions_day',
      desc: '',
      args: [],
    );
  }

  /// `Nobody has booked a workshop for that day yet.`
  String get scan_no_sessions_body_day {
    return Intl.message(
      'Nobody has booked a workshop for that day yet.',
      name: 'scan_no_sessions_body_day',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
      Locale.fromSubtags(languageCode: 'ar'),
    ];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
