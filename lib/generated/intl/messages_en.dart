// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(n) => "Bldg ${n}";

  static String m1(count) => "${count} digits";

  static String m2(label) => "Enter ${label}";

  static String m3(label) => "${label} is required";

  static String m4(label) => "Enter a valid ${label}";

  static String m5(label) => "Select ${label}";

  static String m6(n) => "P.O. ${n}";

  static String m7(field) => "${field} is needed";

  static String m8(n) => "Unit ${n}";

  static String m9(percent) => "${percent}% played";

  static String m10(rate) => "${rate}x";

  static String m11(count) => "Back ${count} seconds";

  static String m12(count) => "Forward ${count} seconds";

  static String m13(minutes) => "Stop in ${minutes} minutes";

  static String m14(minutes) => "${minutes}m";

  static String m15(digits) =>
      "Enter the ${digits}-digit code sent to your phone";

  static String m16(timer) => "Resend code ${timer}";

  static String m17(digits) => "We sent a ${digits}-digit code to your phone.";

  static String m18(digits, phone) =>
      "We sent a ${digits}-digit code to ${phone}";

  static String m19(name) => "Welcome back, ${name}";

  static String m20(count) => "${count} more";

  static String m21(count) => "${count} notifications";

  static String m22(name) => "Add photos for ${name}";

  static String m23(when) =>
      "Cancel before ${when} and the full amount goes back to your Terracotta balance.";

  static String m24(when) =>
      "You can cancel or reschedule up to ${when}, and the full amount returns to your Terracotta balance.";

  static String m25(count) => "Booking for ${count}";

  static String m26(people, date, time) => "${people} · ${date} · ${time}";

  static String m27(date) => "Made ${date}";

  static String m28(count) =>
      "${Intl.plural(count, one: '1 person', other: '${count} people')}";

  static String m29(count) => "${count} people";

  static String m30(count) =>
      "${Intl.plural(count, one: 'person', other: 'people')}";

  static String m31(index) => "Person ${index}";

  static String m32(count) => "${count} photo(s) left";

  static String m33(index) => "Piece ${index}";

  static String m34(index) => "Piece ${index}";

  static String m35(workshop) => "Painted at ${workshop}";

  static String m36(workshop, date) =>
      "Booked in to paint · ${workshop}, ${date}";

  static String m37(count) =>
      "${Intl.plural(count, one: '1 photo', other: '${count} photos')}";

  static String m38(count) => "Choose ${count} pieces";

  static String m39(min) => "Choose at least ${min} pieces";

  static String m40(min, max) => "Choose between ${min} and ${max} pieces";

  static String m41(span) =>
      "Your piece is being finished with care — ready in ${span}.";

  static String m42(label) => "Remove ${label}?";

  static String m43(days) => "Show this code when you arrive — ${days} to go.";

  static String m44(left, total) => "${left} / ${total} seats";

  static String m45(count) => "Selected pieces ${count}";

  static String m46(start, end) => "Session ${start} to ${end}";

  static String m47(start, end) => "Workshop from ${start} to ${end}";

  static String m48(left, total) => "${left} of ${total}";

  static String m49(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m50(days, hours) => "${days} and ${hours}";

  static String m51(count) =>
      "${Intl.plural(count, one: '1 hour', other: '${count} hours')}";

  static String m52(count) =>
      "${Intl.plural(count, zero: 'Your cart is empty', one: '${count} item', other: '${count} items')}";

  static String m53(left) => "Only ${left} left";

  static String m54(title) => "${title}: sold out";

  static String m55(title, wanted, left) =>
      "${title}: you have ${wanted}, only ${left} left";

  static String m56(price) => "Add for ${price}";

  static String m57(age) => "I confirm I am ${age} or older";

  static String m58(amount) => "on orders over ${amount}";

  static String m59(amount) => "${amount} off";

  static String m60(value) => "${value}% off";

  static String m61(rate) => "VAT included (${rate})";

  static String m62(amount) => "Covers ${amount} of it";

  static String m63(title, people) => "${title} for ${people}";

  static String m64(hint) => "Use ${hint}";

  static String m65(feature) => "${feature} is on the way";

  static String m66(email) => "We\'ll email ${email} when it ships.";

  static String m67(count) => "Qty ${count}";

  static String m68(count) => "You\'re offline — ${count} queued";

  static String m69(network) => "Invalid ${network} address";

  static String m70(days) =>
      "${Intl.plural(days, one: '1 day old', other: '${days} days old')}";

  static String m71(months) =>
      "${Intl.plural(months, one: '1 month old', other: '${months} months old')}";

  static String m72(years) => "${years} years old";

  static String m73(months) =>
      "Must be valid for at least ${months} more months";

  static String m74(date) => "${date} AH";

  static String m75(format) => "Incomplete date — use ${format}";

  static String m76(date) => "Date must be on or before ${date}";

  static String m77(days) => "Pick a date within the next ${days} days";

  static String m78(date) => "Date must be on or after ${date}";

  static String m79(days) => "Pick a date at least ${days} days from now";

  static String m80(date) => "Must be after ${date}";

  static String m81(date) => "Must be before ${date}";

  static String m82(count) => "${count} events";

  static String m83(days) => "Select a range of at most ${days} days";

  static String m84(days) => "Select a range of at least ${days} days";

  static String m85(nights) => "${nights} nights";

  static String m86(amount) =>
      "We will hold your piece at the studio. ${amount} goes back to your Terracotta balance — not to your card — and you can switch back any time before you collect it.";

  static String m87(amount) => "${amount} is back in your Terracotta balance.";

  static String m88(left) =>
      "${left} left to collect your piece or ask for delivery. After that the studio cannot hold it.";

  static String m89(seconds) => "Closing in ${seconds}s";

  static String m90(query) => "No items match \"${query}\"";

  static String m91(query) => "Create \"${query}\"";

  static String m92(labels, count) => "${labels} (+${count} more)";

  static String m93(count) => "Selected ${count}";

  static String m94(count, max) => "${count}/${max} selected";

  static String m95(n) => "${n} d";

  static String m96(duration) => "Must be at most ${duration}";

  static String m97(duration) => "Must be at least ${duration}";

  static String m98(minutes) => "${minutes}m";

  static String m99(seconds) => "${seconds}s";

  static String m100(step) => "Minutes must be in ${step}-minute steps";

  static String m101(n) => "${n} h";

  static String m102(n) => "${n} min";

  static String m103(query) => "No results for “${query}”";

  static String m104(error) => "Failed to open email: ${error}";

  static String m105(photos, videos) => "${photos} photos · ${videos} videos";

  static String m106(photos) => "${photos} photos";

  static String m107(videos) => "${videos} videos";

  static String m108(amount) => "Gift ${amount}";

  static String m109(amount, balance) =>
      "${amount} was added. Your balance is now ${balance}.";

  static String m110(name) => "From ${name}";

  static String m111(name) => "To ${name}";

  static String m112(name) => "For ${name}";

  static String m113(name) => "From ${name}";

  static String m114(name) => "Good evening, ${name}";

  static String m115(count) =>
      "${Intl.plural(count, one: '1 piece', other: '${count} pieces')}";

  static String m116(when) => "Arriving ${when}";

  static String m117(time) => "Until ${time}";

  static String m118(date, time) => "${date} · ${time}";

  static String m119(count) => "See all (${count})";

  static String m120(index) => "Go to page ${index}";

  static String m121(index, total) => "Page ${index} of ${total}";

  static String m122(index, total) => "Story ${index} of ${total}";

  static String m123(title) => "Couldn\'t load ${title}";

  static String m124(title) => "${title} is unavailable";

  static String m125(version) => "Version ${version}";

  static String m126(version, build) => "Version ${version} · Build ${build}";

  static String m127(page) => "Page ${page}";

  static String m128(page, total) => "Page ${page} of ${total}";

  static String m129(count) => "${count} selected";

  static String m130(eta) => "Back ${eta}";

  static String m131(hours, minutes) => "in ~${hours}h ${minutes}m";

  static String m132(minutes) => "in ~${minutes} min";

  static String m133(seconds) => "in ~${seconds}s";

  static String m134(seconds) => "Retry in ${seconds}s";

  static String m135(extensions) => "Only ${extensions} allowed.";

  static String m136(size, max) => "File is ${size} MB; max ${max} MB.";

  static String m137(side) =>
      "Image must be at most ${side}px on the longest side.";

  static String m138(side) =>
      "Image must be at least ${side}px on the shortest side.";

  static String m139(index, total) => "Item ${index} of ${total}";

  static String m140(count, max) => "${count} not added — the limit is ${max}";

  static String m141(index) => "Moved to position ${index}";

  static String m142(message) => "Open failed: ${message}";

  static String m143(count, max) => "${count} of ${max} selected";

  static String m144(ratio, expected) =>
      "Aspect ratio ${ratio} — expected ${expected}.";

  static String m145(date) => "Born ${date}";

  static String m146(length) => "Must be ${length} digits";

  static String m147(count) =>
      "${Intl.plural(count, one: '1 more step', other: '${count} more steps')}";

  static String m148(index, total) => "Tab ${index} of ${total}";

  static String m149(count) =>
      "${Intl.plural(count, zero: 'No new notifications', one: '${count} new notification', other: '${count} new notifications')}";

  static String m150(amount) => "${amount} is back in your Terracotta balance.";

  static String m151(date) => "Cancelled ${date}";

  static String m152(count) =>
      "${Intl.plural(count, zero: 'No items', one: '1 item', other: '${count} items')}";

  static String m153(number) => "Order #${number}";

  static String m154(time) => "Pay before ${time}";

  static String m155(date) => "Placed ${date}";

  static String m156(count, price) => "${count} × ${price}";

  static String m157(length) => "Code must be ${length} characters";

  static String m158(seconds) => "Resend in ${seconds}s";

  static String m159(destination) => "Code sent to ${destination}";

  static String m160(count) =>
      "${Intl.plural(count, one: '${count} bookmark', other: '${count} bookmarks')}";

  static String m161(percent) => "Downloading… ${percent}%";

  static String m162(index, total) => "Match ${index} of ${total}";

  static String m163(name) => "Open ${name}";

  static String m164(count) =>
      "${Intl.plural(count, one: '${count} page', other: '${count} pages')}";

  static String m165(count) => "${count} pp";

  static String m166(page) => "Page ${page}";

  static String m167(page, total) => "Page ${page} of ${total}";

  static String m168(page) => "Resumed at page ${page}";

  static String m169(max) => "Must be at most ${max}";

  static String m170(min) => "Must be at least ${min}";

  static String m171(min, max) => "Must be between ${min} and ${max}";

  static String m172(count) => "Phone number must be ${count} digits";

  static String m173(min, max) => "Phone number must be ${min}–${max} digits";

  static String m174(count) => "Mobile number must be ${count} digits";

  static String m175(min, max) => "Mobile number must be ${min}–${max} digits";

  static String m176(prefixes) => "Mobile numbers start with ${prefixes}";

  static String m177(date) => "Made ${date}";

  static String m178(amount) => "Paint one for ${amount}";

  static String m179(value, count) => "${value} out of ${count}";

  static String m180(name) => "${name} is already checked in";

  static String m181(arrived, total) => "${arrived} of ${total} arrived";

  static String m182(name) => "${name} checked in";

  static String m183(name, count) =>
      "${name} booked for ${count}. Nothing is saved until you say.";

  static String m184(name, done, expected) =>
      "${name} — ${done} of ${expected}";

  static String m185(done, expected) => "${done} of ${expected} pieces";

  static String m186(booked, capacity) => "${booked} of ${capacity}";

  static String m187(time) => "Finished at ${time}";

  static String m188(count) => "${count} new";

  static String m189(version) => "Version ${version}";

  static String m190(category) => "Browse ${category}";

  static String m191(category) => "Browse ${category}";

  static String m192(count) =>
      "That is all we can add — you already have ${count} of this in your cart.";

  static String m193(percent) => "-${percent}%";

  static String m194(count) => "${count} of this already in your cart.";

  static String m195(title, count) => "${title} x ${count}";

  static String m196(count) =>
      "${Intl.plural(count, one: 'Only 1 available', other: 'Only ${count} available')}";

  static String m197(count) => "Qty ${count}";

  static String m198(title) =>
      "${title} will be taken out of your cart. You can always add it again.";

  static String m199(count) =>
      "${Intl.plural(count, zero: 'No results', one: '${count} result', other: '${count} results')}";

  static String m200(count) =>
      "${Intl.plural(count, one: '1 left', other: '${count} left')}";

  static String m201(provider) => "Continue with ${provider}";

  static String m202(index, total) => "Card ${index} of ${total}";

  static String m203(index, total) => "Item ${index} of ${total}";

  static String m204(index, total) => "Step ${index} of ${total}";

  static String m205(max) => "Maximum ${max} tags reached";

  static String m206(count) => "Add at least ${count} tags";

  static String m207(max) => "Max ${max} characters";

  static String m208(domains) => "Only ${domains} addresses are accepted";

  static String m209(count, total) => "${count} of ${total} name parts";

  static String m210(count) =>
      "This password appeared in ${count} data breaches — pick another";

  static String m211(length) => "At least ${length} characters";

  static String m212(format) => "Incomplete time — use ${format}";

  static String m213(minutes) => "Time must be on ${minutes}-minute steps";

  static String m214(time) => "Time must be at or before ${time}";

  static String m215(time) => "Time must be at or after ${time}";

  static String m216(time) => "Must be after ${time}";

  static String m217(start, end) => "Time must be between ${start} and ${end}";

  static String m218(hours, minutes) => "${hours}h ${minutes}m";

  static String m219(count) => "${count} more options";

  static String m220(count) =>
      "${Intl.plural(count, one: '1 saved address', other: '${count} saved addresses')}";

  static String m221(count) =>
      "${Intl.plural(count, one: '1 piece in your basket', other: '${count} pieces in your basket')}";

  static String m222(count) =>
      "${Intl.plural(count, one: '1 piece moved over', other: '${count} pieces moved over')}";

  static String m223(count) =>
      "${Intl.plural(count, one: '1 piece could not be moved — the studio has run out', other: '${count} pieces could not be moved — the studio has run out')}";

  static String m224(count) =>
      "${Intl.plural(count, one: '1 saved piece', other: '${count} saved pieces')}";

  static String m225(host) => "Links to ${host} aren’t allowed";

  static String m226(domains) => "Link must be on ${domains}";

  static String m227(scheme) => "Link type \"${scheme}\" isn’t allowed";

  static String m228(years) => "Must be at least ${years} years old";

  static String m229(years) => "Must be ${years} years old or younger";

  static String m230(length) => "CVV must be ${length} digits";

  static String m231(count) => "Full name must have at least ${count} parts";

  static String m232(country, length) =>
      "A ${country} IBAN must be ${length} characters";

  static String m233(n) => "Please select at least ${n} items";

  static String m234(n) => "Please select at most ${n} items";

  static String m235(n) => "Must be at least ${n}";

  static String m236(n) => "Must be at least ${n} characters";

  static String m237(n) => "Must be at most ${n}";

  static String m238(n) => "Must be at most ${n} characters";

  static String m239(length) => "OTP must be ${length} digits";

  static String m240(seconds) => "Skip back ${seconds} seconds";

  static String m241(seconds) => "Skip forward ${seconds} seconds";

  static String m242(count) => "${count} min";

  static String m243(year) => "Model year ${year}";

  static String m244(amount) => "Balance after: ${amount}";

  static String m245(minutes) => "${minutes} min";

  static String m246(days) =>
      "You will have ${days} to collect your piece once it is ready.";

  static String m247(price) => "${price} per person";

  static String m248(count) => "${count} per session";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "address_add": MessageLookupByLibrary.simpleMessage("Add an address"),
    "address_additional": MessageLookupByLibrary.simpleMessage(
      "Additional number",
    ),
    "address_building": MessageLookupByLibrary.simpleMessage("Building number"),
    "address_building_short": m0,
    "address_city": MessageLookupByLibrary.simpleMessage("City"),
    "address_city_required": MessageLookupByLibrary.simpleMessage(
      "Pick a city — it sets the delivery fee.",
    ),
    "address_default": MessageLookupByLibrary.simpleMessage("Default"),
    "address_delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "address_delete_body": MessageLookupByLibrary.simpleMessage(
      "You can add it again any time. Nothing else changes.",
    ),
    "address_delete_title": MessageLookupByLibrary.simpleMessage(
      "Delete this address?",
    ),
    "address_deleted": MessageLookupByLibrary.simpleMessage("Address deleted"),
    "address_digits_exactly": m1,
    "address_district": MessageLookupByLibrary.simpleMessage("District"),
    "address_edit": MessageLookupByLibrary.simpleMessage("Edit address"),
    "address_field_area": MessageLookupByLibrary.simpleMessage(
      "Area / District",
    ),
    "address_field_area_hint": MessageLookupByLibrary.simpleMessage(
      "Neighborhood or district",
    ),
    "address_field_city": MessageLookupByLibrary.simpleMessage("City"),
    "address_field_city_hint": MessageLookupByLibrary.simpleMessage(
      "Enter city",
    ),
    "address_field_country": MessageLookupByLibrary.simpleMessage("Country"),
    "address_field_county": MessageLookupByLibrary.simpleMessage("County"),
    "address_field_emirate": MessageLookupByLibrary.simpleMessage("Emirate"),
    "address_field_enter": m2,
    "address_field_field_required": m3,
    "address_field_governorate": MessageLookupByLibrary.simpleMessage(
      "Governorate",
    ),
    "address_field_line2": MessageLookupByLibrary.simpleMessage(
      "Apartment, suite, building (optional)",
    ),
    "address_field_line2_hint": MessageLookupByLibrary.simpleMessage(
      "Apartment, floor, landmark",
    ),
    "address_field_notes": MessageLookupByLibrary.simpleMessage(
      "Delivery notes (optional)",
    ),
    "address_field_notes_hint": MessageLookupByLibrary.simpleMessage(
      "Leave at the door, ring twice…",
    ),
    "address_field_phone": MessageLookupByLibrary.simpleMessage(
      "Contact phone",
    ),
    "address_field_postal_code": MessageLookupByLibrary.simpleMessage(
      "Postal code",
    ),
    "address_field_postal_invalid": m4,
    "address_field_postcode": MessageLookupByLibrary.simpleMessage("Postcode"),
    "address_field_recipient": MessageLookupByLibrary.simpleMessage(
      "Recipient name",
    ),
    "address_field_recipient_hint": MessageLookupByLibrary.simpleMessage(
      "Who receives this",
    ),
    "address_field_region": MessageLookupByLibrary.simpleMessage("Region"),
    "address_field_select_state": m5,
    "address_field_state": MessageLookupByLibrary.simpleMessage("State"),
    "address_field_street": MessageLookupByLibrary.simpleMessage(
      "Street address",
    ),
    "address_field_street_hint": MessageLookupByLibrary.simpleMessage(
      "Street name and number",
    ),
    "address_field_type_home": MessageLookupByLibrary.simpleMessage("Home"),
    "address_field_type_other": MessageLookupByLibrary.simpleMessage("Other"),
    "address_field_type_work": MessageLookupByLibrary.simpleMessage("Work"),
    "address_field_zip_code": MessageLookupByLibrary.simpleMessage("ZIP code"),
    "address_hint_additional": MessageLookupByLibrary.simpleMessage("2817"),
    "address_hint_building": MessageLookupByLibrary.simpleMessage("4359"),
    "address_hint_district": MessageLookupByLibrary.simpleMessage(
      "e.g. Al Dhobbat",
    ),
    "address_hint_notes": MessageLookupByLibrary.simpleMessage(
      "Blue door, second floor",
    ),
    "address_hint_phone": MessageLookupByLibrary.simpleMessage("05XXXXXXXX"),
    "address_hint_postal": MessageLookupByLibrary.simpleMessage("12627"),
    "address_hint_street": MessageLookupByLibrary.simpleMessage(
      "e.g. Abi Al Karam Street",
    ),
    "address_hint_unit": MessageLookupByLibrary.simpleMessage("12"),
    "address_label_field": MessageLookupByLibrary.simpleMessage(
      "Name this address",
    ),
    "address_label_hint": MessageLookupByLibrary.simpleMessage("Home, work…"),
    "address_make_default": MessageLookupByLibrary.simpleMessage(
      "Make default",
    ),
    "address_notes": MessageLookupByLibrary.simpleMessage(
      "Notes for the courier",
    ),
    "address_or_manual": MessageLookupByLibrary.simpleMessage(
      "or enter it yourself",
    ),
    "address_phone": MessageLookupByLibrary.simpleMessage(
      "Phone for the courier",
    ),
    "address_pin": MessageLookupByLibrary.simpleMessage("Pin on the map"),
    "address_pin_fallback": MessageLookupByLibrary.simpleMessage(
      "Map is unavailable — we set your city centre for now.",
    ),
    "address_pin_missing": MessageLookupByLibrary.simpleMessage(
      "Drop a pin so the courier can find you.",
    ),
    "address_pin_set": MessageLookupByLibrary.simpleMessage("Location set"),
    "address_postal": MessageLookupByLibrary.simpleMessage("Postal code"),
    "address_postal_short": m6,
    "address_required": m7,
    "address_save": MessageLookupByLibrary.simpleMessage("Save address"),
    "address_saved": MessageLookupByLibrary.simpleMessage("Address saved"),
    "address_short_find": MessageLookupByLibrary.simpleMessage("Find"),
    "address_short_found": MessageLookupByLibrary.simpleMessage(
      "Found it — check the details below.",
    ),
    "address_short_help": MessageLookupByLibrary.simpleMessage(
      "Eight characters — four letters then four digits. We will fill the rest in for you.",
    ),
    "address_short_hint": MessageLookupByLibrary.simpleMessage("ABCD1234"),
    "address_short_invalid": MessageLookupByLibrary.simpleMessage(
      "Four letters then four digits, like ABCD1234.",
    ),
    "address_short_label": MessageLookupByLibrary.simpleMessage(
      "Short national address",
    ),
    "address_short_not_found": MessageLookupByLibrary.simpleMessage(
      "We could not find that code. You can type the address below instead.",
    ),
    "address_short_too_fast": MessageLookupByLibrary.simpleMessage(
      "Give it a moment before trying again.",
    ),
    "address_short_unavailable": MessageLookupByLibrary.simpleMessage(
      "Lookup is not available right now. You can type the address below instead.",
    ),
    "address_street": MessageLookupByLibrary.simpleMessage("Street"),
    "address_unit": MessageLookupByLibrary.simpleMessage("Unit number"),
    "address_unit_short": m8,
    "address_unnamed": MessageLookupByLibrary.simpleMessage("Saved address"),
    "address_zones_empty": MessageLookupByLibrary.simpleMessage(
      "We could not load the cities. Pull to try again.",
    ),
    "amount_field_all_currencies": MessageLookupByLibrary.simpleMessage(
      "All currencies",
    ),
    "amount_field_preferred_currencies": MessageLookupByLibrary.simpleMessage(
      "Preferred",
    ),
    "animation_access_denied": MessageLookupByLibrary.simpleMessage(
      "Access denied",
    ),
    "animation_invalid_file": MessageLookupByLibrary.simpleMessage(
      "Invalid animation file",
    ),
    "animation_load_failed": MessageLookupByLibrary.simpleMessage(
      "Failed to load animation",
    ),
    "animation_network_error": MessageLookupByLibrary.simpleMessage(
      "Network error",
    ),
    "animation_not_found": MessageLookupByLibrary.simpleMessage(
      "Animation not found",
    ),
    "animation_pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "animation_paused_reduced_motion": MessageLookupByLibrary.simpleMessage(
      "Paused — reduce motion is on",
    ),
    "animation_percent_played": m9,
    "animation_play": MessageLookupByLibrary.simpleMessage("Play"),
    "animation_playback_speed": MessageLookupByLibrary.simpleMessage(
      "Playback speed",
    ),
    "animation_replay": MessageLookupByLibrary.simpleMessage(
      "Replay from the start",
    ),
    "animation_seek": MessageLookupByLibrary.simpleMessage("Playback position"),
    "animation_speed_multiplier": m10,
    "api_status_accepted": MessageLookupByLibrary.simpleMessage("Accepted"),
    "api_status_already_reported": MessageLookupByLibrary.simpleMessage(
      "Already Reported",
    ),
    "api_status_bad_gateway": MessageLookupByLibrary.simpleMessage(
      "Bad Gateway",
    ),
    "api_status_bad_request": MessageLookupByLibrary.simpleMessage(
      "Bad Request",
    ),
    "api_status_cancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "api_status_conflict": MessageLookupByLibrary.simpleMessage("Conflict"),
    "api_status_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "api_status_created": MessageLookupByLibrary.simpleMessage("Created"),
    "api_status_early_hints": MessageLookupByLibrary.simpleMessage(
      "Early Hints",
    ),
    "api_status_expectation_failed": MessageLookupByLibrary.simpleMessage(
      "Expectation Failed",
    ),
    "api_status_failed_dependency": MessageLookupByLibrary.simpleMessage(
      "Failed Dependency",
    ),
    "api_status_forbidden": MessageLookupByLibrary.simpleMessage("Forbidden"),
    "api_status_found": MessageLookupByLibrary.simpleMessage("Found"),
    "api_status_gateway_timeout": MessageLookupByLibrary.simpleMessage(
      "Gateway Timeout",
    ),
    "api_status_gone": MessageLookupByLibrary.simpleMessage("Gone"),
    "api_status_http_version_not_supported":
        MessageLookupByLibrary.simpleMessage("HTTP Version Not Supported"),
    "api_status_im_used": MessageLookupByLibrary.simpleMessage("IM Used"),
    "api_status_insufficient_storage": MessageLookupByLibrary.simpleMessage(
      "Insufficient Storage",
    ),
    "api_status_internal_server_error": MessageLookupByLibrary.simpleMessage(
      "Internal Server Error",
    ),
    "api_status_length_required": MessageLookupByLibrary.simpleMessage(
      "Length Required",
    ),
    "api_status_locked": MessageLookupByLibrary.simpleMessage("Locked"),
    "api_status_loop_detected": MessageLookupByLibrary.simpleMessage(
      "Loop Detected",
    ),
    "api_status_method_not_allowed": MessageLookupByLibrary.simpleMessage(
      "Method Not Allowed",
    ),
    "api_status_misdirected_request": MessageLookupByLibrary.simpleMessage(
      "Misdirected Request",
    ),
    "api_status_moved_permanently": MessageLookupByLibrary.simpleMessage(
      "Moved Permanently",
    ),
    "api_status_multi_status": MessageLookupByLibrary.simpleMessage(
      "Multi-Status",
    ),
    "api_status_multiple_choices": MessageLookupByLibrary.simpleMessage(
      "Multiple Choices",
    ),
    "api_status_network_authentication_required":
        MessageLookupByLibrary.simpleMessage("Network Authentication Required"),
    "api_status_network_error": MessageLookupByLibrary.simpleMessage(
      "Network Error",
    ),
    "api_status_no_content": MessageLookupByLibrary.simpleMessage("No Content"),
    "api_status_non_authoritative_information":
        MessageLookupByLibrary.simpleMessage("Non-Authoritative Information"),
    "api_status_not_acceptable": MessageLookupByLibrary.simpleMessage(
      "Not Acceptable",
    ),
    "api_status_not_extended": MessageLookupByLibrary.simpleMessage(
      "Not Extended",
    ),
    "api_status_not_found": MessageLookupByLibrary.simpleMessage("Not Found"),
    "api_status_not_implemented": MessageLookupByLibrary.simpleMessage(
      "Not Implemented",
    ),
    "api_status_not_modified": MessageLookupByLibrary.simpleMessage(
      "Not Modified",
    ),
    "api_status_ok": MessageLookupByLibrary.simpleMessage("OK"),
    "api_status_partial_content": MessageLookupByLibrary.simpleMessage(
      "Partial Content",
    ),
    "api_status_payload_too_large": MessageLookupByLibrary.simpleMessage(
      "Payload Too Large",
    ),
    "api_status_payment_required": MessageLookupByLibrary.simpleMessage(
      "Payment Required",
    ),
    "api_status_permanent_redirect": MessageLookupByLibrary.simpleMessage(
      "Permanent Redirect",
    ),
    "api_status_precondition_failed": MessageLookupByLibrary.simpleMessage(
      "Precondition Failed",
    ),
    "api_status_precondition_required": MessageLookupByLibrary.simpleMessage(
      "Precondition Required",
    ),
    "api_status_processing": MessageLookupByLibrary.simpleMessage("Processing"),
    "api_status_proxy_authentication_required":
        MessageLookupByLibrary.simpleMessage("Proxy Authentication Required"),
    "api_status_range_not_satisfiable": MessageLookupByLibrary.simpleMessage(
      "Range Not Satisfiable",
    ),
    "api_status_request_header_fields_too_large":
        MessageLookupByLibrary.simpleMessage("Request Header Fields Too Large"),
    "api_status_request_timeout": MessageLookupByLibrary.simpleMessage(
      "Request Timeout",
    ),
    "api_status_reset_content": MessageLookupByLibrary.simpleMessage(
      "Reset Content",
    ),
    "api_status_see_other": MessageLookupByLibrary.simpleMessage("See Other"),
    "api_status_service_unavailable": MessageLookupByLibrary.simpleMessage(
      "Service Unavailable",
    ),
    "api_status_switching_protocols": MessageLookupByLibrary.simpleMessage(
      "Switching Protocols",
    ),
    "api_status_temporary_redirect": MessageLookupByLibrary.simpleMessage(
      "Temporary Redirect",
    ),
    "api_status_timeout": MessageLookupByLibrary.simpleMessage("Timeout"),
    "api_status_too_early": MessageLookupByLibrary.simpleMessage("Too Early"),
    "api_status_too_many_requests": MessageLookupByLibrary.simpleMessage(
      "Too Many Requests",
    ),
    "api_status_unauthorized": MessageLookupByLibrary.simpleMessage(
      "Unauthorized",
    ),
    "api_status_unavailable_for_legal_reasons":
        MessageLookupByLibrary.simpleMessage("Unavailable For Legal Reasons"),
    "api_status_unknown_error": MessageLookupByLibrary.simpleMessage(
      "Unknown Error",
    ),
    "api_status_unsupported_media_type": MessageLookupByLibrary.simpleMessage(
      "Unsupported Media Type",
    ),
    "api_status_upgrade_required": MessageLookupByLibrary.simpleMessage(
      "Upgrade Required",
    ),
    "api_status_uri_too_long": MessageLookupByLibrary.simpleMessage(
      "URI Too Long",
    ),
    "api_status_use_proxy": MessageLookupByLibrary.simpleMessage("Use Proxy"),
    "api_status_validation_error": MessageLookupByLibrary.simpleMessage(
      "Validation Error",
    ),
    "api_status_variant_also_negotiates": MessageLookupByLibrary.simpleMessage(
      "Variant Also Negotiates",
    ),
    "audio_error": MessageLookupByLibrary.simpleMessage(
      "Could not play this audio",
    ),
    "audio_loading": MessageLookupByLibrary.simpleMessage("Loading"),
    "audio_loop": MessageLookupByLibrary.simpleMessage("Repeat"),
    "audio_next": MessageLookupByLibrary.simpleMessage("Next track"),
    "audio_pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "audio_play": MessageLookupByLibrary.simpleMessage("Play"),
    "audio_previous": MessageLookupByLibrary.simpleMessage("Previous track"),
    "audio_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "audio_skip_back": m11,
    "audio_skip_forward": m12,
    "audio_sleep": MessageLookupByLibrary.simpleMessage("Sleep timer"),
    "audio_sleep_end": MessageLookupByLibrary.simpleMessage(
      "Stop at end of track",
    ),
    "audio_sleep_minutes": m13,
    "audio_sleep_off": MessageLookupByLibrary.simpleMessage("Sleep timer off"),
    "audio_sleep_short_end": MessageLookupByLibrary.simpleMessage("End"),
    "audio_sleep_short_minutes": m14,
    "audio_speed": MessageLookupByLibrary.simpleMessage("Playback speed"),
    "audio_timeline": MessageLookupByLibrary.simpleMessage("Position"),
    "audio_waveform": MessageLookupByLibrary.simpleMessage("Scrub the audio"),
    "auth_change": MessageLookupByLibrary.simpleMessage("Change"),
    "auth_confirm_password": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "auth_confirm_password_field_title": MessageLookupByLibrary.simpleMessage(
      "Confirm Password",
    ),
    "auth_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "auth_continue_as_guest": MessageLookupByLibrary.simpleMessage(
      "Browse as a guest",
    ),
    "auth_create_account": MessageLookupByLibrary.simpleMessage("Create one"),
    "auth_dev_otp_title": MessageLookupByLibrary.simpleMessage(
      "Your verification code",
    ),
    "auth_enter_confirm_password_hint": MessageLookupByLibrary.simpleMessage(
      "Confirm your password",
    ),
    "auth_enter_father_name_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your father\'s name",
    ),
    "auth_enter_first_name_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your first name",
    ),
    "auth_enter_full_name_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your full name",
    ),
    "auth_enter_last_name_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your last name",
    ),
    "auth_enter_middle_name_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your middle name",
    ),
    "auth_enter_otp": m15,
    "auth_enter_password_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your password",
    ),
    "auth_enter_phone_number_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your phone number",
    ),
    "auth_error_generic": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "auth_first_name_field_title": MessageLookupByLibrary.simpleMessage(
      "First Name",
    ),
    "auth_forgot_password": MessageLookupByLibrary.simpleMessage(
      "Forgot Password?",
    ),
    "auth_forgot_subtitle": MessageLookupByLibrary.simpleMessage(
      "We\'ll send you a code to reset your password.",
    ),
    "auth_forgot_title": MessageLookupByLibrary.simpleMessage(
      "Enter your phone number",
    ),
    "auth_full_name": MessageLookupByLibrary.simpleMessage("Full name"),
    "auth_have_account_prompt": MessageLookupByLibrary.simpleMessage(
      "Already have an account?",
    ),
    "auth_identifier_unsupported": MessageLookupByLibrary.simpleMessage(
      "This studio signs in with a credential this app cannot ask for yet. Please get in touch.",
    ),
    "auth_last_name_field_title": MessageLookupByLibrary.simpleMessage(
      "Last Name",
    ),
    "auth_login_subtitle": MessageLookupByLibrary.simpleMessage(
      "See every available workshop and book the slot that suits you.",
    ),
    "auth_login_title": MessageLookupByLibrary.simpleMessage("Welcome back"),
    "auth_needed_booking": MessageLookupByLibrary.simpleMessage(
      "Sign in to confirm this booking. Your date, your seats and everything you picked are kept exactly as they are.",
    ),
    "auth_needed_cart": MessageLookupByLibrary.simpleMessage(
      "Sign in to pay. Your basket, your addresses and your saved pieces come with you.",
    ),
    "auth_needed_confirm": MessageLookupByLibrary.simpleMessage("Sign in"),
    "auth_needed_later": MessageLookupByLibrary.simpleMessage("Not now"),
    "auth_needed_title": MessageLookupByLibrary.simpleMessage("One step left"),
    "auth_new_password": MessageLookupByLibrary.simpleMessage("New password"),
    "auth_no_account_prompt": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account?",
    ),
    "auth_or": MessageLookupByLibrary.simpleMessage("or"),
    "auth_otp_incomplete": MessageLookupByLibrary.simpleMessage(
      "Enter the full verification code",
    ),
    "auth_otp_resend": MessageLookupByLibrary.simpleMessage("Resend code"),
    "auth_otp_resend_timer": m16,
    "auth_otp_subtitle": m17,
    "auth_otp_subtitle_phone": m18,
    "auth_otp_title": MessageLookupByLibrary.simpleMessage("Enter the code"),
    "auth_password_field_title": MessageLookupByLibrary.simpleMessage(
      "Password",
    ),
    "auth_phone_number_field_title": MessageLookupByLibrary.simpleMessage(
      "Phone Number",
    ),
    "auth_policy_agree": MessageLookupByLibrary.simpleMessage(
      "I agree to the Terms and Privacy Policy",
    ),
    "auth_policy_required": MessageLookupByLibrary.simpleMessage(
      "You must accept the terms to continue",
    ),
    "auth_register": MessageLookupByLibrary.simpleMessage("Register"),
    "auth_register_success_body": MessageLookupByLibrary.simpleMessage(
      "Every workshop sets its own deadline for cancelling or rescheduling. You will see yours on the booking itself.",
    ),
    "auth_register_success_title": MessageLookupByLibrary.simpleMessage(
      "Your account is ready",
    ),
    "auth_register_title": MessageLookupByLibrary.simpleMessage(
      "Welcome to Terracotta",
    ),
    "auth_remember_me": MessageLookupByLibrary.simpleMessage(
      "Keep me signed in",
    ),
    "auth_reset_subtitle": MessageLookupByLibrary.simpleMessage(
      "You can now set a new password for your account.",
    ),
    "auth_reset_title": MessageLookupByLibrary.simpleMessage(
      "Change your password",
    ),
    "auth_send_code": MessageLookupByLibrary.simpleMessage("Send code"),
    "auth_session_expired_message": MessageLookupByLibrary.simpleMessage(
      "You were signed out. Sign in again to reach your cart, bookings and balance.",
    ),
    "auth_session_expired_title": MessageLookupByLibrary.simpleMessage(
      "Your session has ended",
    ),
    "auth_sign_in": MessageLookupByLibrary.simpleMessage("Sign In"),
    "auth_sign_in_required_message": MessageLookupByLibrary.simpleMessage(
      "This one needs an account. Sign in to reach your cart, bookings and balance.",
    ),
    "auth_sign_in_required_title": MessageLookupByLibrary.simpleMessage(
      "Sign in to continue",
    ),
    "auth_sign_out": MessageLookupByLibrary.simpleMessage("Sign Out"),
    "auth_verify": MessageLookupByLibrary.simpleMessage("Verify"),
    "auth_verify_card_body": MessageLookupByLibrary.simpleMessage(
      "Enter the code we sent you to book a workshop or place an order.",
    ),
    "auth_verify_card_cta": MessageLookupByLibrary.simpleMessage("Verify now"),
    "auth_verify_card_title": MessageLookupByLibrary.simpleMessage(
      "Verify your number",
    ),
    "auth_verify_needed_book": MessageLookupByLibrary.simpleMessage(
      "Booking a workshop needs a verified number. It takes a moment.",
    ),
    "auth_verify_needed_buy": MessageLookupByLibrary.simpleMessage(
      "Placing an order needs a verified number. It takes a moment.",
    ),
    "auth_verify_needed_confirm": MessageLookupByLibrary.simpleMessage(
      "Verify now",
    ),
    "auth_verify_needed_title": MessageLookupByLibrary.simpleMessage(
      "Verify your number first",
    ),
    "auth_verify_sent": MessageLookupByLibrary.simpleMessage(
      "We sent you a new code",
    ),
    "auth_welcome_back": m19,
    "avatar_more_count": m20,
    "badge_count_notifications": m21,
    "badge_new_notification": MessageLookupByLibrary.simpleMessage(
      "New notification",
    ),
    "bank_field_holder_hint": MessageLookupByLibrary.simpleMessage(
      "Full name on the account",
    ),
    "bank_field_holder_label": MessageLookupByLibrary.simpleMessage(
      "Account holder",
    ),
    "bank_field_iban_label": MessageLookupByLibrary.simpleMessage("IBAN"),
    "bank_field_swift_bic_label": MessageLookupByLibrary.simpleMessage(
      "SWIFT / BIC",
    ),
    "banner_offline_message": MessageLookupByLibrary.simpleMessage(
      "Changes you make will sync once you\'re back online.",
    ),
    "banner_update_action": MessageLookupByLibrary.simpleMessage("Update"),
    "banner_update_message": MessageLookupByLibrary.simpleMessage(
      "A newer version of the app is ready to install.",
    ),
    "banner_update_title": MessageLookupByLibrary.simpleMessage(
      "Update available",
    ),
    "booking_absent_body": MessageLookupByLibrary.simpleMessage(
      "You did not attend, and the amount will be returned to your in-app balance to use later.",
    ),
    "booking_absent_title": MessageLookupByLibrary.simpleMessage(
      "You did not attend",
    ),
    "booking_add_celebration": MessageLookupByLibrary.simpleMessage(
      "Add a celebration",
    ),
    "booking_add_more_photos": MessageLookupByLibrary.simpleMessage("Add more"),
    "booking_add_photos_for": m22,
    "booking_all_named": MessageLookupByLibrary.simpleMessage(
      "Everyone on this booking already has a piece. Add more photos to one of them below.",
    ),
    "booking_attending_body": MessageLookupByLibrary.simpleMessage(
      "Your attendance is recorded — you are in the workshop now.",
    ),
    "booking_attending_title": MessageLookupByLibrary.simpleMessage(
      "Attending",
    ),
    "booking_back": MessageLookupByLibrary.simpleMessage("Back"),
    "booking_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "booking_cancel_confirm": MessageLookupByLibrary.simpleMessage(
      "Are you sure you want to cancel this booking?",
    ),
    "booking_cancel_policy": m23,
    "booking_cancel_policy_none": MessageLookupByLibrary.simpleMessage(
      "This session starts too soon to be cancelled or rescheduled.",
    ),
    "booking_cancel_title": MessageLookupByLibrary.simpleMessage(
      "Cancel booking",
    ),
    "booking_cancelled_body": MessageLookupByLibrary.simpleMessage(
      "The workshop has been cancelled. We will let you know about any updates or another date.",
    ),
    "booking_cancelled_title": MessageLookupByLibrary.simpleMessage(
      "Cancelled",
    ),
    "booking_change": MessageLookupByLibrary.simpleMessage("Change"),
    "booking_close": MessageLookupByLibrary.simpleMessage("Close"),
    "booking_confirmed_body": m24,
    "booking_confirmed_body_final": MessageLookupByLibrary.simpleMessage(
      "This session starts too soon to be cancelled or rescheduled.",
    ),
    "booking_confirmed_title": MessageLookupByLibrary.simpleMessage(
      "Your workshop is booked!",
    ),
    "booking_detail_confirmed": MessageLookupByLibrary.simpleMessage(
      "Booking confirmed",
    ),
    "booking_done": MessageLookupByLibrary.simpleMessage("Done"),
    "booking_edit_person_name": MessageLookupByLibrary.simpleMessage(
      "Edit the person’s name",
    ),
    "booking_edit_piece_name": MessageLookupByLibrary.simpleMessage(
      "Edit the piece’s name",
    ),
    "booking_empty": MessageLookupByLibrary.simpleMessage(
      "You have no bookings yet",
    ),
    "booking_filter_all": MessageLookupByLibrary.simpleMessage("All"),
    "booking_for_people": m25,
    "booking_full_up": MessageLookupByLibrary.simpleMessage("Fully booked"),
    "booking_handed_over_body": MessageLookupByLibrary.simpleMessage(
      "The workshop is finished and the piece is yours.",
    ),
    "booking_handed_over_title": MessageLookupByLibrary.simpleMessage(
      "Delivered",
    ),
    "booking_meta": m26,
    "booking_mine_empty": MessageLookupByLibrary.simpleMessage(
      "You have not booked a workshop yet.",
    ),
    "booking_my_bookings": MessageLookupByLibrary.simpleMessage("My bookings"),
    "booking_name_taken": MessageLookupByLibrary.simpleMessage(
      "Somebody else already has this name.",
    ),
    "booking_next": MessageLookupByLibrary.simpleMessage("Next"),
    "booking_no": MessageLookupByLibrary.simpleMessage("No"),
    "booking_no_cancel_body": MessageLookupByLibrary.simpleMessage(
      "It starts too soon to fall inside the cancellation window. Book it and the seat is yours to keep — you will not be able to cancel or reschedule it afterwards.",
    ),
    "booking_no_cancel_confirm": MessageLookupByLibrary.simpleMessage(
      "Book it anyway",
    ),
    "booking_no_cancel_title": MessageLookupByLibrary.simpleMessage(
      "This session cannot be cancelled",
    ),
    "booking_no_slots": MessageLookupByLibrary.simpleMessage(
      "No sessions on this day.",
    ),
    "booking_on_the_way_body": MessageLookupByLibrary.simpleMessage(
      "Your piece is on its way to you and will arrive soon.",
    ),
    "booking_on_the_way_title": MessageLookupByLibrary.simpleMessage(
      "Out for delivery",
    ),
    "booking_own_piece_made_on": m27,
    "booking_own_pieces": MessageLookupByLibrary.simpleMessage("My pieces"),
    "booking_own_pieces_hint": MessageLookupByLibrary.simpleMessage(
      "Pieces you made yourself, ready to be painted.",
    ),
    "booking_packing_body": MessageLookupByLibrary.simpleMessage(
      "Your piece is being wrapped and made ready for delivery.",
    ),
    "booking_packing_title": MessageLookupByLibrary.simpleMessage(
      "Being wrapped",
    ),
    "booking_party": m28,
    "booking_people_count": m29,
    "booking_people_unit": m30,
    "booking_person_hint": m31,
    "booking_person_name_hint": MessageLookupByLibrary.simpleMessage(
      "Their name",
    ),
    "booking_photo_removed": MessageLookupByLibrary.simpleMessage(
      "Photo removed.",
    ),
    "booking_photos_full": MessageLookupByLibrary.simpleMessage(
      "That\'s every photo for this booking.",
    ),
    "booking_photos_left": m32,
    "booking_photos_old": MessageLookupByLibrary.simpleMessage("Earlier"),
    "booking_photos_uploaded": MessageLookupByLibrary.simpleMessage(
      "Photos uploaded.",
    ),
    "booking_pick_people": MessageLookupByLibrary.simpleMessage(
      "How many are coming?",
    ),
    "booking_pick_pieces": MessageLookupByLibrary.simpleMessage(
      "Pick your pieces",
    ),
    "booking_pick_slot": MessageLookupByLibrary.simpleMessage("Pick a time"),
    "booking_piece_hint": m33,
    "booking_piece_label": MessageLookupByLibrary.simpleMessage(
      "Name this piece",
    ),
    "booking_piece_label_hint": MessageLookupByLibrary.simpleMessage("My cup"),
    "booking_piece_label_required": MessageLookupByLibrary.simpleMessage(
      "Give every person a name.",
    ),
    "booking_piece_name": MessageLookupByLibrary.simpleMessage("Name"),
    "booking_piece_name_taken": MessageLookupByLibrary.simpleMessage(
      "Another piece already has this name.",
    ),
    "booking_piece_needs_photo": MessageLookupByLibrary.simpleMessage(
      "Add at least one photo of this piece.",
    ),
    "booking_piece_number": m34,
    "booking_piece_painted_at": m35,
    "booking_piece_painting_on": m36,
    "booking_piece_photo_count": m37,
    "booking_piece_removed": MessageLookupByLibrary.simpleMessage(
      "Piece removed.",
    ),
    "booking_piece_renamed": MessageLookupByLibrary.simpleMessage(
      "Name changed",
    ),
    "booking_piece_untitled": MessageLookupByLibrary.simpleMessage("Piece"),
    "booking_pieces_empty": MessageLookupByLibrary.simpleMessage(
      "This workshop has no pieces yet.",
    ),
    "booking_pieces_exact": m38,
    "booking_pieces_min_only": m39,
    "booking_pieces_range": m40,
    "booking_pieces_total": MessageLookupByLibrary.simpleMessage("Total"),
    "booking_preparing_body": MessageLookupByLibrary.simpleMessage(
      "Your piece is being finished with care.",
    ),
    "booking_preparing_body_in": m41,
    "booking_preparing_body_painted": MessageLookupByLibrary.simpleMessage(
      "Your piece is being prepared; the details will be confirmed shortly.",
    ),
    "booking_preparing_title": MessageLookupByLibrary.simpleMessage(
      "Being prepared",
    ),
    "booking_qr_instructions": MessageLookupByLibrary.simpleMessage(
      "Show this QR when you arrive to check in.",
    ),
    "booking_remove_celebration": MessageLookupByLibrary.simpleMessage(
      "Remove the celebration",
    ),
    "booking_remove_photo_body": MessageLookupByLibrary.simpleMessage(
      "It is the only way to replace it — there is no swap.",
    ),
    "booking_remove_photo_title": MessageLookupByLibrary.simpleMessage(
      "Remove this photo?",
    ),
    "booking_remove_piece_body": MessageLookupByLibrary.simpleMessage(
      "Every photo of it goes too.",
    ),
    "booking_remove_piece_title": m42,
    "booking_reschedule": MessageLookupByLibrary.simpleMessage("Edit"),
    "booking_reschedule_confirm_body": MessageLookupByLibrary.simpleMessage(
      "Your seats move to the new time. The old one is released.",
    ),
    "booking_reschedule_confirm_title": MessageLookupByLibrary.simpleMessage(
      "Move this booking?",
    ),
    "booking_reschedule_confirm_yes": MessageLookupByLibrary.simpleMessage(
      "Move it",
    ),
    "booking_reschedule_title": MessageLookupByLibrary.simpleMessage(
      "Change your time",
    ),
    "booking_save": MessageLookupByLibrary.simpleMessage("Save"),
    "booking_scan_code": MessageLookupByLibrary.simpleMessage("Scan code"),
    "booking_scan_on_arrival": m43,
    "booking_scan_on_arrival_soon": MessageLookupByLibrary.simpleMessage(
      "Show this code when you arrive — starting shortly.",
    ),
    "booking_seats_left": m44,
    "booking_selected_pieces": m45,
    "booking_session_time": m46,
    "booking_slot_conflict": MessageLookupByLibrary.simpleMessage(
      "You already have a booking then",
    ),
    "booking_slot_current": MessageLookupByLibrary.simpleMessage(
      "Your current time",
    ),
    "booking_slot_full": MessageLookupByLibrary.simpleMessage("Full"),
    "booking_slot_label": m47,
    "booking_slot_seats": m48,
    "booking_status_absent": MessageLookupByLibrary.simpleMessage(
      "Did not attend",
    ),
    "booking_status_attending": MessageLookupByLibrary.simpleMessage(
      "Attending",
    ),
    "booking_status_cancelled": MessageLookupByLibrary.simpleMessage(
      "Cancelled",
    ),
    "booking_status_completed": MessageLookupByLibrary.simpleMessage("Done"),
    "booking_status_confirmed": MessageLookupByLibrary.simpleMessage(
      "Confirmed",
    ),
    "booking_status_expired": MessageLookupByLibrary.simpleMessage("Expired"),
    "booking_status_pending_payment": MessageLookupByLibrary.simpleMessage(
      "Awaiting payment",
    ),
    "booking_status_preparing": MessageLookupByLibrary.simpleMessage(
      "Being prepared",
    ),
    "booking_time_to": MessageLookupByLibrary.simpleMessage("to"),
    "booking_track": MessageLookupByLibrary.simpleMessage("Track booking"),
    "booking_unit_days": m49,
    "booking_unit_days_hours": m50,
    "booking_unit_hours": m51,
    "booking_upload_photos": MessageLookupByLibrary.simpleMessage("Add photos"),
    "booking_upload_piece": MessageLookupByLibrary.simpleMessage(
      "Upload a photo of your piece",
    ),
    "booking_upload_remaining": MessageLookupByLibrary.simpleMessage(
      "Upload the remaining photos",
    ),
    "booking_upload_send": MessageLookupByLibrary.simpleMessage("Upload"),
    "booking_with_celebration": MessageLookupByLibrary.simpleMessage(
      "With a celebration",
    ),
    "booking_yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "button_icon_semantic_label": MessageLookupByLibrary.simpleMessage(
      "Icon button",
    ),
    "button_read_more": MessageLookupByLibrary.simpleMessage("Read more"),
    "button_result_failed": MessageLookupByLibrary.simpleMessage("Failed"),
    "button_result_success": MessageLookupByLibrary.simpleMessage("Success"),
    "button_show_less": MessageLookupByLibrary.simpleMessage("Show less"),
    "button_tooltip_add": MessageLookupByLibrary.simpleMessage("Add"),
    "button_tooltip_add_favorite": MessageLookupByLibrary.simpleMessage(
      "Add to favorites",
    ),
    "button_tooltip_copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "button_tooltip_delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "button_tooltip_edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "button_tooltip_filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "button_tooltip_more": MessageLookupByLibrary.simpleMessage("More"),
    "button_tooltip_refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "button_tooltip_remove_favorite": MessageLookupByLibrary.simpleMessage(
      "Remove from favorites",
    ),
    "button_tooltip_search": MessageLookupByLibrary.simpleMessage("Search"),
    "button_tooltip_send": MessageLookupByLibrary.simpleMessage("Send"),
    "button_tooltip_start_voice_input": MessageLookupByLibrary.simpleMessage(
      "Start voice input",
    ),
    "button_tooltip_stop_listening": MessageLookupByLibrary.simpleMessage(
      "Stop listening",
    ),
    "card_field_cvv_label": MessageLookupByLibrary.simpleMessage("CVV"),
    "card_field_expiry_label": MessageLookupByLibrary.simpleMessage("Expiry"),
    "card_field_number_label": MessageLookupByLibrary.simpleMessage(
      "Card number",
    ),
    "cart_items": m52,
    "cart_line_over": m53,
    "cart_stock_body": MessageLookupByLibrary.simpleMessage(
      "The studio sold some of these while you were browsing. Here is what changed:",
    ),
    "cart_stock_fix": MessageLookupByLibrary.simpleMessage(
      "Fix my basket for me",
    ),
    "cart_stock_fix_note": MessageLookupByLibrary.simpleMessage(
      "We will lower what we can and take out what is gone.",
    ),
    "cart_stock_fixed": MessageLookupByLibrary.simpleMessage(
      "Your basket is ready",
    ),
    "cart_stock_keep": MessageLookupByLibrary.simpleMessage(
      "Leave it as it is",
    ),
    "cart_stock_keep_note": MessageLookupByLibrary.simpleMessage(
      "You can change it yourself. Checkout stays closed until you do.",
    ),
    "cart_stock_line_gone": m54,
    "cart_stock_line_left": m55,
    "cart_stock_title": MessageLookupByLibrary.simpleMessage(
      "Some pieces ran out",
    ),
    "celebration_add_price": m56,
    "celebration_body": MessageLookupByLibrary.simpleMessage(
      "Balloons, a little cake and the room set for it — we take care of the whole thing while you make your piece.",
    ),
    "celebration_title": MessageLookupByLibrary.simpleMessage(
      "Celebrate with Terracotta",
    ),
    "change_password_confirm_label": MessageLookupByLibrary.simpleMessage(
      "Confirm new password",
    ),
    "change_password_current_hint": MessageLookupByLibrary.simpleMessage(
      "Enter current password",
    ),
    "change_password_current_label": MessageLookupByLibrary.simpleMessage(
      "Current password",
    ),
    "change_password_new_label": MessageLookupByLibrary.simpleMessage(
      "New password",
    ),
    "change_password_same_as_current": MessageLookupByLibrary.simpleMessage(
      "New password must be different from your current password",
    ),
    "checkbox_acknowledge_required": MessageLookupByLibrary.simpleMessage(
      "You must acknowledge this to continue",
    ),
    "checkbox_age_confirm": m57,
    "checkbox_age_required": MessageLookupByLibrary.simpleMessage(
      "You must confirm your age to continue",
    ),
    "checkbox_default_address": MessageLookupByLibrary.simpleMessage(
      "Set as default address",
    ),
    "checkbox_dont_show_again": MessageLookupByLibrary.simpleMessage(
      "Don\'t show this again",
    ),
    "checkbox_marketing_opt_in": MessageLookupByLibrary.simpleMessage(
      "Send me offers and product updates",
    ),
    "checkbox_same_as_billing": MessageLookupByLibrary.simpleMessage(
      "Shipping address same as billing",
    ),
    "checkbox_save_card": MessageLookupByLibrary.simpleMessage(
      "Save this card for future payments",
    ),
    "checkbox_select_all": MessageLookupByLibrary.simpleMessage("Select All"),
    "checkbox_semantic_label": MessageLookupByLibrary.simpleMessage("Checkbox"),
    "checkout_address_required": MessageLookupByLibrary.simpleMessage(
      "Choose where this is going.",
    ),
    "checkout_already_settled": MessageLookupByLibrary.simpleMessage(
      "Already covered by your balance",
    ),
    "checkout_amount_due": MessageLookupByLibrary.simpleMessage("Amount due"),
    "checkout_apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "checkout_code_min_order": m58,
    "checkout_code_off_fixed": m59,
    "checkout_code_off_percent": m60,
    "checkout_confirm_and_pay": MessageLookupByLibrary.simpleMessage(
      "Confirm and pay",
    ),
    "checkout_delivery_fee": MessageLookupByLibrary.simpleMessage("Delivery"),
    "checkout_discount": MessageLookupByLibrary.simpleMessage("Discount"),
    "checkout_discount_code": MessageLookupByLibrary.simpleMessage(
      "Discount code",
    ),
    "checkout_discount_code_hint": MessageLookupByLibrary.simpleMessage(
      "SAVE10",
    ),
    "checkout_free": MessageLookupByLibrary.simpleMessage("Free"),
    "checkout_hold_expired": MessageLookupByLibrary.simpleMessage(
      "The hold on this order has run out. Please start again.",
    ),
    "checkout_left_to_pay": MessageLookupByLibrary.simpleMessage("Left to pay"),
    "checkout_open_order": MessageLookupByLibrary.simpleMessage(
      "You already have an order awaiting payment. Finish or cancel it first.",
    ),
    "checkout_open_order_action": MessageLookupByLibrary.simpleMessage(
      "View my orders",
    ),
    "checkout_pay_method": MessageLookupByLibrary.simpleMessage(
      "Payment method",
    ),
    "checkout_subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
    "checkout_title": MessageLookupByLibrary.simpleMessage("Payment"),
    "checkout_total": MessageLookupByLibrary.simpleMessage("Total"),
    "checkout_use_wallet": MessageLookupByLibrary.simpleMessage(
      "Use my Terracotta balance",
    ),
    "checkout_vat": m61,
    "checkout_wallet_applied": MessageLookupByLibrary.simpleMessage(
      "Terracotta balance",
    ),
    "checkout_wallet_covers": m62,
    "checkout_workshop_line": m63,
    "color_field_invalid_format": m64,
    "color_field_picker_title": MessageLookupByLibrary.simpleMessage(
      "Pick a color",
    ),
    "color_field_required": MessageLookupByLibrary.simpleMessage(
      "Enter a color",
    ),
    "color_name_beige": MessageLookupByLibrary.simpleMessage("Beige"),
    "color_name_black": MessageLookupByLibrary.simpleMessage("Black"),
    "color_name_blue": MessageLookupByLibrary.simpleMessage("Blue"),
    "color_name_brown": MessageLookupByLibrary.simpleMessage("Brown"),
    "color_name_green": MessageLookupByLibrary.simpleMessage("Green"),
    "color_name_grey": MessageLookupByLibrary.simpleMessage("Grey"),
    "color_name_navy": MessageLookupByLibrary.simpleMessage("Navy"),
    "color_name_olive": MessageLookupByLibrary.simpleMessage("Olive"),
    "color_name_orange": MessageLookupByLibrary.simpleMessage("Orange"),
    "color_name_pink": MessageLookupByLibrary.simpleMessage("Pink"),
    "color_name_purple": MessageLookupByLibrary.simpleMessage("Purple"),
    "color_name_red": MessageLookupByLibrary.simpleMessage("Red"),
    "color_name_teal": MessageLookupByLibrary.simpleMessage("Teal"),
    "color_name_terracotta": MessageLookupByLibrary.simpleMessage("Terracotta"),
    "color_name_white": MessageLookupByLibrary.simpleMessage("White"),
    "color_name_yellow": MessageLookupByLibrary.simpleMessage("Yellow"),
    "coming_soon_body": MessageLookupByLibrary.simpleMessage(
      "We\'re working on it. Want a heads-up the moment it lands?",
    ),
    "coming_soon_body_plain": MessageLookupByLibrary.simpleMessage(
      "We\'re working on it. Check back soon.",
    ),
    "coming_soon_change_email": MessageLookupByLibrary.simpleMessage(
      "Use a different email",
    ),
    "coming_soon_email_invalid": MessageLookupByLibrary.simpleMessage(
      "That email doesn\'t look right",
    ),
    "coming_soon_enter_email": MessageLookupByLibrary.simpleMessage(
      "Enter your email",
    ),
    "coming_soon_eta_label": MessageLookupByLibrary.simpleMessage("Expected"),
    "coming_soon_feature_on_the_way": m65,
    "coming_soon_notify_me": MessageLookupByLibrary.simpleMessage("Notify me"),
    "coming_soon_save_failed": MessageLookupByLibrary.simpleMessage(
      "Could not save your email. Please try again.",
    ),
    "coming_soon_success_body": m66,
    "coming_soon_success_title": MessageLookupByLibrary.simpleMessage(
      "You\'re on the list",
    ),
    "coming_soon_this_feature": MessageLookupByLibrary.simpleMessage(
      "This feature",
    ),
    "coming_soon_title": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "common_add": MessageLookupByLibrary.simpleMessage("Add"),
    "common_back": MessageLookupByLibrary.simpleMessage("Back"),
    "common_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "common_clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "common_clear_all": MessageLookupByLibrary.simpleMessage("Clear all"),
    "common_close": MessageLookupByLibrary.simpleMessage("Close"),
    "common_collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
    "common_contact_support": MessageLookupByLibrary.simpleMessage(
      "Contact support",
    ),
    "common_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "common_copied_to_clipboard": MessageLookupByLibrary.simpleMessage(
      "Copied to clipboard",
    ),
    "common_copy": MessageLookupByLibrary.simpleMessage("Copy"),
    "common_count": m67,
    "common_delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "common_dismiss": MessageLookupByLibrary.simpleMessage("Dismiss"),
    "common_dismissed": MessageLookupByLibrary.simpleMessage("Dismissed"),
    "common_done": MessageLookupByLibrary.simpleMessage("Done"),
    "common_edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "common_error": MessageLookupByLibrary.simpleMessage("Error"),
    "common_expand": MessageLookupByLibrary.simpleMessage("Expand"),
    "common_help": MessageLookupByLibrary.simpleMessage("Help"),
    "common_later": MessageLookupByLibrary.simpleMessage("Later"),
    "common_loading": MessageLookupByLibrary.simpleMessage("Loading..."),
    "common_next": MessageLookupByLibrary.simpleMessage("Next"),
    "common_no_results": MessageLookupByLibrary.simpleMessage("No results"),
    "common_ok": MessageLookupByLibrary.simpleMessage("OK"),
    "common_open": MessageLookupByLibrary.simpleMessage("Open"),
    "common_open_settings": MessageLookupByLibrary.simpleMessage(
      "Open settings",
    ),
    "common_paste": MessageLookupByLibrary.simpleMessage("Paste"),
    "common_pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "common_previous": MessageLookupByLibrary.simpleMessage("Previous"),
    "common_refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "common_remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "common_reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "common_resume": MessageLookupByLibrary.simpleMessage("Resume"),
    "common_retry": MessageLookupByLibrary.simpleMessage("Retry"),
    "common_save": MessageLookupByLibrary.simpleMessage("Save"),
    "common_saving": MessageLookupByLibrary.simpleMessage("Saving…"),
    "common_search": MessageLookupByLibrary.simpleMessage("Search"),
    "common_select_time": MessageLookupByLibrary.simpleMessage("Select Time"),
    "common_settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "common_share": MessageLookupByLibrary.simpleMessage("Share"),
    "common_skip": MessageLookupByLibrary.simpleMessage("Skip"),
    "common_something_went_wrong": MessageLookupByLibrary.simpleMessage(
      "Something went wrong",
    ),
    "common_stop": MessageLookupByLibrary.simpleMessage("Stop"),
    "common_submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "common_success": MessageLookupByLibrary.simpleMessage("Success"),
    "common_tap_to_retry": MessageLookupByLibrary.simpleMessage("Tap to retry"),
    "common_try_again": MessageLookupByLibrary.simpleMessage("Try again"),
    "common_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "common_update": MessageLookupByLibrary.simpleMessage("Update"),
    "complaint_contact": MessageLookupByLibrary.simpleMessage(
      "Phone or email to reach you",
    ),
    "complaint_empty": MessageLookupByLibrary.simpleMessage(
      "You have not sent anything yet.",
    ),
    "complaint_empty_body": MessageLookupByLibrary.simpleMessage(
      "If something went wrong with an order or a booking, tell us and we will come back to you.",
    ),
    "complaint_message": MessageLookupByLibrary.simpleMessage("Details"),
    "complaint_message_hint": MessageLookupByLibrary.simpleMessage(
      "Tell us what happened…",
    ),
    "complaint_mine": MessageLookupByLibrary.simpleMessage("My complaints"),
    "complaint_name": MessageLookupByLibrary.simpleMessage("Your name"),
    "complaint_new": MessageLookupByLibrary.simpleMessage("New complaint"),
    "complaint_reference": MessageLookupByLibrary.simpleMessage(
      "Order or booking number (optional)",
    ),
    "complaint_reference_hint": MessageLookupByLibrary.simpleMessage(
      "38079300",
    ),
    "complaint_send": MessageLookupByLibrary.simpleMessage("Send"),
    "complaint_send_title": MessageLookupByLibrary.simpleMessage(
      "Send a complaint",
    ),
    "complaint_sent": MessageLookupByLibrary.simpleMessage(
      "We have your message, and we will come back to you.",
    ),
    "complaint_status_closed": MessageLookupByLibrary.simpleMessage("Closed"),
    "complaint_status_in_progress": MessageLookupByLibrary.simpleMessage(
      "In progress",
    ),
    "complaint_status_new": MessageLookupByLibrary.simpleMessage("New"),
    "complaint_status_resolved": MessageLookupByLibrary.simpleMessage(
      "Resolved",
    ),
    "complaint_title": MessageLookupByLibrary.simpleMessage("Contact us"),
    "complaint_type": MessageLookupByLibrary.simpleMessage("Subject"),
    "complaint_type_delivery": MessageLookupByLibrary.simpleMessage("Delivery"),
    "complaint_type_order": MessageLookupByLibrary.simpleMessage(
      "A shop order",
    ),
    "complaint_type_other": MessageLookupByLibrary.simpleMessage(
      "Something else",
    ),
    "complaint_type_payment": MessageLookupByLibrary.simpleMessage("Payment"),
    "complaint_type_workshop": MessageLookupByLibrary.simpleMessage(
      "A workshop",
    ),
    "connectivity_back_online": MessageLookupByLibrary.simpleMessage(
      "Back online",
    ),
    "connectivity_offline": MessageLookupByLibrary.simpleMessage(
      "You\'re offline",
    ),
    "connectivity_offline_queued": m68,
    "connectivity_quality_excellent": MessageLookupByLibrary.simpleMessage(
      "Excellent",
    ),
    "connectivity_quality_fair": MessageLookupByLibrary.simpleMessage("Fair"),
    "connectivity_quality_good": MessageLookupByLibrary.simpleMessage("Good"),
    "connectivity_quality_offline": MessageLookupByLibrary.simpleMessage(
      "Offline",
    ),
    "connectivity_quality_poor": MessageLookupByLibrary.simpleMessage("Poor"),
    "connectivity_quality_unknown": MessageLookupByLibrary.simpleMessage(
      "Unknown",
    ),
    "connectivity_type_ethernet": MessageLookupByLibrary.simpleMessage(
      "Ethernet",
    ),
    "connectivity_type_mobile": MessageLookupByLibrary.simpleMessage(
      "Mobile data",
    ),
    "connectivity_type_offline": MessageLookupByLibrary.simpleMessage(
      "Offline",
    ),
    "connectivity_type_other": MessageLookupByLibrary.simpleMessage("Other"),
    "connectivity_type_vpn": MessageLookupByLibrary.simpleMessage("VPN"),
    "connectivity_type_wifi": MessageLookupByLibrary.simpleMessage("Wi-Fi"),
    "connectivity_vpn_blocked": MessageLookupByLibrary.simpleMessage(
      "VPN must be disabled to continue",
    ),
    "connectivity_vpn_warning": MessageLookupByLibrary.simpleMessage(
      "VPN detected — may impact some features",
    ),
    "consent_and": MessageLookupByLibrary.simpleMessage(" and "),
    "consent_prefix": MessageLookupByLibrary.simpleMessage("I agree to the "),
    "consent_privacy": MessageLookupByLibrary.simpleMessage("Privacy Policy"),
    "consent_required": MessageLookupByLibrary.simpleMessage(
      "You must accept the terms to continue",
    ),
    "consent_terms": MessageLookupByLibrary.simpleMessage("Terms of Service"),
    "contact_form_message_hint": MessageLookupByLibrary.simpleMessage(
      "Write your message",
    ),
    "contact_form_message_label": MessageLookupByLibrary.simpleMessage(
      "Message",
    ),
    "contact_form_message_required": MessageLookupByLibrary.simpleMessage(
      "Message is required",
    ),
    "country_afghanistan": MessageLookupByLibrary.simpleMessage("Afghanistan"),
    "country_albania": MessageLookupByLibrary.simpleMessage("Albania"),
    "country_algeria": MessageLookupByLibrary.simpleMessage("Algeria"),
    "country_andorra": MessageLookupByLibrary.simpleMessage("Andorra"),
    "country_angola": MessageLookupByLibrary.simpleMessage("Angola"),
    "country_argentina": MessageLookupByLibrary.simpleMessage("Argentina"),
    "country_armenia": MessageLookupByLibrary.simpleMessage("Armenia"),
    "country_australia": MessageLookupByLibrary.simpleMessage("Australia"),
    "country_austria": MessageLookupByLibrary.simpleMessage("Austria"),
    "country_azerbaijan": MessageLookupByLibrary.simpleMessage("Azerbaijan"),
    "country_bahrain": MessageLookupByLibrary.simpleMessage("Bahrain"),
    "country_bangladesh": MessageLookupByLibrary.simpleMessage("Bangladesh"),
    "country_belarus": MessageLookupByLibrary.simpleMessage("Belarus"),
    "country_belgium": MessageLookupByLibrary.simpleMessage("Belgium"),
    "country_benin": MessageLookupByLibrary.simpleMessage("Benin"),
    "country_bolivia": MessageLookupByLibrary.simpleMessage("Bolivia"),
    "country_bosnia_and_herzegovina": MessageLookupByLibrary.simpleMessage(
      "Bosnia and Herzegovina",
    ),
    "country_botswana": MessageLookupByLibrary.simpleMessage("Botswana"),
    "country_brazil": MessageLookupByLibrary.simpleMessage("Brazil"),
    "country_bulgaria": MessageLookupByLibrary.simpleMessage("Bulgaria"),
    "country_burkina_faso": MessageLookupByLibrary.simpleMessage(
      "Burkina Faso",
    ),
    "country_cambodia": MessageLookupByLibrary.simpleMessage("Cambodia"),
    "country_cameroon": MessageLookupByLibrary.simpleMessage("Cameroon"),
    "country_canada": MessageLookupByLibrary.simpleMessage("Canada"),
    "country_cape_verde": MessageLookupByLibrary.simpleMessage("Cape Verde"),
    "country_central_african_republic": MessageLookupByLibrary.simpleMessage(
      "Central African Republic",
    ),
    "country_chad": MessageLookupByLibrary.simpleMessage("Chad"),
    "country_chile": MessageLookupByLibrary.simpleMessage("Chile"),
    "country_china": MessageLookupByLibrary.simpleMessage("China"),
    "country_colombia": MessageLookupByLibrary.simpleMessage("Colombia"),
    "country_comoros": MessageLookupByLibrary.simpleMessage("Comoros"),
    "country_congo": MessageLookupByLibrary.simpleMessage("Congo"),
    "country_cote_d_ivoire": MessageLookupByLibrary.simpleMessage(
      "Côte d\'Ivoire",
    ),
    "country_croatia": MessageLookupByLibrary.simpleMessage("Croatia"),
    "country_cyprus": MessageLookupByLibrary.simpleMessage("Cyprus"),
    "country_czech_republic": MessageLookupByLibrary.simpleMessage(
      "Czech Republic",
    ),
    "country_democratic_republic_of_the_congo":
        MessageLookupByLibrary.simpleMessage(
          "Democratic Republic of the Congo",
        ),
    "country_denmark": MessageLookupByLibrary.simpleMessage("Denmark"),
    "country_djibouti": MessageLookupByLibrary.simpleMessage("Djibouti"),
    "country_ecuador": MessageLookupByLibrary.simpleMessage("Ecuador"),
    "country_egypt": MessageLookupByLibrary.simpleMessage("Egypt"),
    "country_equatorial_guinea": MessageLookupByLibrary.simpleMessage(
      "Equatorial Guinea",
    ),
    "country_eritrea": MessageLookupByLibrary.simpleMessage("Eritrea"),
    "country_estonia": MessageLookupByLibrary.simpleMessage("Estonia"),
    "country_eswatini": MessageLookupByLibrary.simpleMessage("Eswatini"),
    "country_ethiopia": MessageLookupByLibrary.simpleMessage("Ethiopia"),
    "country_fiji": MessageLookupByLibrary.simpleMessage("Fiji"),
    "country_finland": MessageLookupByLibrary.simpleMessage("Finland"),
    "country_france": MessageLookupByLibrary.simpleMessage("France"),
    "country_french_guiana": MessageLookupByLibrary.simpleMessage(
      "French Guiana",
    ),
    "country_french_polynesia": MessageLookupByLibrary.simpleMessage(
      "French Polynesia",
    ),
    "country_gabon": MessageLookupByLibrary.simpleMessage("Gabon"),
    "country_gambia": MessageLookupByLibrary.simpleMessage("Gambia"),
    "country_georgia": MessageLookupByLibrary.simpleMessage("Georgia"),
    "country_germany": MessageLookupByLibrary.simpleMessage("Germany"),
    "country_ghana": MessageLookupByLibrary.simpleMessage("Ghana"),
    "country_greece": MessageLookupByLibrary.simpleMessage("Greece"),
    "country_guinea": MessageLookupByLibrary.simpleMessage("Guinea"),
    "country_guinea_bissau": MessageLookupByLibrary.simpleMessage(
      "Guinea-Bissau",
    ),
    "country_guyana": MessageLookupByLibrary.simpleMessage("Guyana"),
    "country_hong_kong": MessageLookupByLibrary.simpleMessage("Hong Kong"),
    "country_hungary": MessageLookupByLibrary.simpleMessage("Hungary"),
    "country_iceland": MessageLookupByLibrary.simpleMessage("Iceland"),
    "country_india": MessageLookupByLibrary.simpleMessage("India"),
    "country_indonesia": MessageLookupByLibrary.simpleMessage("Indonesia"),
    "country_iran": MessageLookupByLibrary.simpleMessage("Iran"),
    "country_iraq": MessageLookupByLibrary.simpleMessage("Iraq"),
    "country_ireland": MessageLookupByLibrary.simpleMessage("Ireland"),
    "country_italy": MessageLookupByLibrary.simpleMessage("Italy"),
    "country_japan": MessageLookupByLibrary.simpleMessage("Japan"),
    "country_jordan": MessageLookupByLibrary.simpleMessage("Jordan"),
    "country_kazakhstan": MessageLookupByLibrary.simpleMessage("Kazakhstan"),
    "country_kenya": MessageLookupByLibrary.simpleMessage("Kenya"),
    "country_kiribati": MessageLookupByLibrary.simpleMessage("Kiribati"),
    "country_kuwait": MessageLookupByLibrary.simpleMessage("Kuwait"),
    "country_kyrgyzstan": MessageLookupByLibrary.simpleMessage("Kyrgyzstan"),
    "country_laos": MessageLookupByLibrary.simpleMessage("Laos"),
    "country_latvia": MessageLookupByLibrary.simpleMessage("Latvia"),
    "country_lebanon": MessageLookupByLibrary.simpleMessage("Lebanon"),
    "country_lesotho": MessageLookupByLibrary.simpleMessage("Lesotho"),
    "country_liberia": MessageLookupByLibrary.simpleMessage("Liberia"),
    "country_libya": MessageLookupByLibrary.simpleMessage("Libya"),
    "country_liechtenstein": MessageLookupByLibrary.simpleMessage(
      "Liechtenstein",
    ),
    "country_lithuania": MessageLookupByLibrary.simpleMessage("Lithuania"),
    "country_luxembourg": MessageLookupByLibrary.simpleMessage("Luxembourg"),
    "country_macau": MessageLookupByLibrary.simpleMessage("Macau"),
    "country_madagascar": MessageLookupByLibrary.simpleMessage("Madagascar"),
    "country_malawi": MessageLookupByLibrary.simpleMessage("Malawi"),
    "country_malaysia": MessageLookupByLibrary.simpleMessage("Malaysia"),
    "country_mali": MessageLookupByLibrary.simpleMessage("Mali"),
    "country_malta": MessageLookupByLibrary.simpleMessage("Malta"),
    "country_marshall_islands": MessageLookupByLibrary.simpleMessage(
      "Marshall Islands",
    ),
    "country_mauritania": MessageLookupByLibrary.simpleMessage("Mauritania"),
    "country_mauritius": MessageLookupByLibrary.simpleMessage("Mauritius"),
    "country_mexico": MessageLookupByLibrary.simpleMessage("Mexico"),
    "country_micronesia": MessageLookupByLibrary.simpleMessage("Micronesia"),
    "country_moldova": MessageLookupByLibrary.simpleMessage("Moldova"),
    "country_monaco": MessageLookupByLibrary.simpleMessage("Monaco"),
    "country_mongolia": MessageLookupByLibrary.simpleMessage("Mongolia"),
    "country_montenegro": MessageLookupByLibrary.simpleMessage("Montenegro"),
    "country_morocco": MessageLookupByLibrary.simpleMessage("Morocco"),
    "country_mozambique": MessageLookupByLibrary.simpleMessage("Mozambique"),
    "country_myanmar": MessageLookupByLibrary.simpleMessage("Myanmar"),
    "country_namibia": MessageLookupByLibrary.simpleMessage("Namibia"),
    "country_nauru": MessageLookupByLibrary.simpleMessage("Nauru"),
    "country_nepal": MessageLookupByLibrary.simpleMessage("Nepal"),
    "country_netherlands": MessageLookupByLibrary.simpleMessage("Netherlands"),
    "country_new_caledonia": MessageLookupByLibrary.simpleMessage(
      "New Caledonia",
    ),
    "country_new_zealand": MessageLookupByLibrary.simpleMessage("New Zealand"),
    "country_niger": MessageLookupByLibrary.simpleMessage("Niger"),
    "country_nigeria": MessageLookupByLibrary.simpleMessage("Nigeria"),
    "country_north_korea": MessageLookupByLibrary.simpleMessage("North Korea"),
    "country_north_macedonia": MessageLookupByLibrary.simpleMessage(
      "North Macedonia",
    ),
    "country_norway": MessageLookupByLibrary.simpleMessage("Norway"),
    "country_oman": MessageLookupByLibrary.simpleMessage("Oman"),
    "country_pakistan": MessageLookupByLibrary.simpleMessage("Pakistan"),
    "country_palau": MessageLookupByLibrary.simpleMessage("Palau"),
    "country_palestine": MessageLookupByLibrary.simpleMessage("Palestine"),
    "country_papua_new_guinea": MessageLookupByLibrary.simpleMessage(
      "Papua New Guinea",
    ),
    "country_paraguay": MessageLookupByLibrary.simpleMessage("Paraguay"),
    "country_peru": MessageLookupByLibrary.simpleMessage("Peru"),
    "country_philippines": MessageLookupByLibrary.simpleMessage("Philippines"),
    "country_poland": MessageLookupByLibrary.simpleMessage("Poland"),
    "country_portugal": MessageLookupByLibrary.simpleMessage("Portugal"),
    "country_qatar": MessageLookupByLibrary.simpleMessage("Qatar"),
    "country_romania": MessageLookupByLibrary.simpleMessage("Romania"),
    "country_russia": MessageLookupByLibrary.simpleMessage("Russia"),
    "country_samoa": MessageLookupByLibrary.simpleMessage("Samoa"),
    "country_san_marino": MessageLookupByLibrary.simpleMessage("San Marino"),
    "country_sao_tome_and_principe": MessageLookupByLibrary.simpleMessage(
      "São Tomé and Príncipe",
    ),
    "country_saudi_arabia": MessageLookupByLibrary.simpleMessage(
      "Saudi Arabia",
    ),
    "country_senegal": MessageLookupByLibrary.simpleMessage("Senegal"),
    "country_serbia": MessageLookupByLibrary.simpleMessage("Serbia"),
    "country_seychelles": MessageLookupByLibrary.simpleMessage("Seychelles"),
    "country_sierra_leone": MessageLookupByLibrary.simpleMessage(
      "Sierra Leone",
    ),
    "country_singapore": MessageLookupByLibrary.simpleMessage("Singapore"),
    "country_slovakia": MessageLookupByLibrary.simpleMessage("Slovakia"),
    "country_slovenia": MessageLookupByLibrary.simpleMessage("Slovenia"),
    "country_solomon_islands": MessageLookupByLibrary.simpleMessage(
      "Solomon Islands",
    ),
    "country_somalia": MessageLookupByLibrary.simpleMessage("Somalia"),
    "country_south_africa": MessageLookupByLibrary.simpleMessage(
      "South Africa",
    ),
    "country_south_korea": MessageLookupByLibrary.simpleMessage("South Korea"),
    "country_spain": MessageLookupByLibrary.simpleMessage("Spain"),
    "country_sri_lanka": MessageLookupByLibrary.simpleMessage("Sri Lanka"),
    "country_sudan": MessageLookupByLibrary.simpleMessage("Sudan"),
    "country_suriname": MessageLookupByLibrary.simpleMessage("Suriname"),
    "country_sweden": MessageLookupByLibrary.simpleMessage("Sweden"),
    "country_switzerland": MessageLookupByLibrary.simpleMessage("Switzerland"),
    "country_syria": MessageLookupByLibrary.simpleMessage("Syria"),
    "country_taiwan": MessageLookupByLibrary.simpleMessage("Taiwan"),
    "country_tajikistan": MessageLookupByLibrary.simpleMessage("Tajikistan"),
    "country_tanzania": MessageLookupByLibrary.simpleMessage("Tanzania"),
    "country_thailand": MessageLookupByLibrary.simpleMessage("Thailand"),
    "country_togo": MessageLookupByLibrary.simpleMessage("Togo"),
    "country_tonga": MessageLookupByLibrary.simpleMessage("Tonga"),
    "country_tunisia": MessageLookupByLibrary.simpleMessage("Tunisia"),
    "country_turkey": MessageLookupByLibrary.simpleMessage("Turkey"),
    "country_turkmenistan": MessageLookupByLibrary.simpleMessage(
      "Turkmenistan",
    ),
    "country_tuvalu": MessageLookupByLibrary.simpleMessage("Tuvalu"),
    "country_uganda": MessageLookupByLibrary.simpleMessage("Uganda"),
    "country_ukraine": MessageLookupByLibrary.simpleMessage("Ukraine"),
    "country_united_arab_emirates": MessageLookupByLibrary.simpleMessage(
      "United Arab Emirates",
    ),
    "country_united_kingdom": MessageLookupByLibrary.simpleMessage(
      "United Kingdom",
    ),
    "country_united_states": MessageLookupByLibrary.simpleMessage(
      "United States",
    ),
    "country_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "country_uruguay": MessageLookupByLibrary.simpleMessage("Uruguay"),
    "country_uzbekistan": MessageLookupByLibrary.simpleMessage("Uzbekistan"),
    "country_vanuatu": MessageLookupByLibrary.simpleMessage("Vanuatu"),
    "country_vatican_city": MessageLookupByLibrary.simpleMessage(
      "Vatican City",
    ),
    "country_venezuela": MessageLookupByLibrary.simpleMessage("Venezuela"),
    "country_vietnam": MessageLookupByLibrary.simpleMessage("Vietnam"),
    "country_western_sahara": MessageLookupByLibrary.simpleMessage(
      "Western Sahara",
    ),
    "country_yemen": MessageLookupByLibrary.simpleMessage("Yemen"),
    "country_zambia": MessageLookupByLibrary.simpleMessage("Zambia"),
    "country_zimbabwe": MessageLookupByLibrary.simpleMessage("Zimbabwe"),
    "crypto_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter wallet address",
    ),
    "crypto_field_invalid": m69,
    "crypto_field_required": MessageLookupByLibrary.simpleMessage(
      "Wallet address is required",
    ),
    "date_field_age_days": m70,
    "date_field_age_months": m71,
    "date_field_age_years": m72,
    "date_field_date_unavailable": MessageLookupByLibrary.simpleMessage(
      "That date isn\'t available",
    ),
    "date_field_day_word": MessageLookupByLibrary.simpleMessage("DD"),
    "date_field_expiry_min_months": m73,
    "date_field_hijri": m74,
    "date_field_impossible": MessageLookupByLibrary.simpleMessage(
      "That date doesn\'t exist",
    ),
    "date_field_incomplete": m75,
    "date_field_max_date": m76,
    "date_field_max_days_ahead": m77,
    "date_field_min_date": m78,
    "date_field_min_days_ahead": m79,
    "date_field_month_word": MessageLookupByLibrary.simpleMessage("MM"),
    "date_field_must_be_after": m80,
    "date_field_must_be_before": m81,
    "date_field_pick_date": MessageLookupByLibrary.simpleMessage("Pick a date"),
    "date_field_select_date": MessageLookupByLibrary.simpleMessage(
      "Select date",
    ),
    "date_field_weekday_not_allowed": MessageLookupByLibrary.simpleMessage(
      "That day of the week isn\'t available",
    ),
    "date_field_year2_word": MessageLookupByLibrary.simpleMessage("YY"),
    "date_field_year_word": MessageLookupByLibrary.simpleMessage("YYYY"),
    "date_picker_choose_month": MessageLookupByLibrary.simpleMessage(
      "Choose month",
    ),
    "date_picker_choose_year": MessageLookupByLibrary.simpleMessage(
      "Choose year",
    ),
    "date_picker_close": MessageLookupByLibrary.simpleMessage("Close picker"),
    "date_picker_day": MessageLookupByLibrary.simpleMessage("Day"),
    "date_picker_events": m82,
    "date_picker_hour": MessageLookupByLibrary.simpleMessage("Hour"),
    "date_picker_in_range": MessageLookupByLibrary.simpleMessage("In range"),
    "date_picker_max_range_days": m83,
    "date_picker_min_range_days": m84,
    "date_picker_minute": MessageLookupByLibrary.simpleMessage("Minute"),
    "date_picker_month": MessageLookupByLibrary.simpleMessage("Month"),
    "date_picker_next_month": MessageLookupByLibrary.simpleMessage(
      "Next month",
    ),
    "date_picker_next_year": MessageLookupByLibrary.simpleMessage("Next year"),
    "date_picker_next_years": MessageLookupByLibrary.simpleMessage(
      "Later years",
    ),
    "date_picker_period": MessageLookupByLibrary.simpleMessage("AM or PM"),
    "date_picker_pick_from_calendar": MessageLookupByLibrary.simpleMessage(
      "Pick from the calendar",
    ),
    "date_picker_previous_month": MessageLookupByLibrary.simpleMessage(
      "Previous month",
    ),
    "date_picker_previous_year": MessageLookupByLibrary.simpleMessage(
      "Previous year",
    ),
    "date_picker_previous_years": MessageLookupByLibrary.simpleMessage(
      "Earlier years",
    ),
    "date_picker_range_end": MessageLookupByLibrary.simpleMessage("Range end"),
    "date_picker_range_start": MessageLookupByLibrary.simpleMessage(
      "Range start",
    ),
    "date_picker_second": MessageLookupByLibrary.simpleMessage("Second"),
    "date_picker_select_date_time": MessageLookupByLibrary.simpleMessage(
      "Select date and time",
    ),
    "date_picker_select_month_year": MessageLookupByLibrary.simpleMessage(
      "Select month and year",
    ),
    "date_picker_select_time": MessageLookupByLibrary.simpleMessage(
      "Select time",
    ),
    "date_picker_select_time_range": MessageLookupByLibrary.simpleMessage(
      "Select a time range",
    ),
    "date_picker_select_year": MessageLookupByLibrary.simpleMessage(
      "Select year",
    ),
    "date_picker_selected": MessageLookupByLibrary.simpleMessage("Selected"),
    "date_picker_today": MessageLookupByLibrary.simpleMessage("Today"),
    "date_picker_type_a_date": MessageLookupByLibrary.simpleMessage(
      "Type a date",
    ),
    "date_picker_unavailable": MessageLookupByLibrary.simpleMessage(
      "Unavailable",
    ),
    "date_picker_year": MessageLookupByLibrary.simpleMessage("Year"),
    "date_range_end": MessageLookupByLibrary.simpleMessage("End date"),
    "date_range_nights": m85,
    "date_range_preset_last_30_days": MessageLookupByLibrary.simpleMessage(
      "Last 30 days",
    ),
    "date_range_preset_last_7_days": MessageLookupByLibrary.simpleMessage(
      "Last 7 days",
    ),
    "date_range_preset_last_month": MessageLookupByLibrary.simpleMessage(
      "Last month",
    ),
    "date_range_preset_this_month": MessageLookupByLibrary.simpleMessage(
      "This month",
    ),
    "date_range_preset_today": MessageLookupByLibrary.simpleMessage("Today"),
    "date_range_select_date_range": MessageLookupByLibrary.simpleMessage(
      "Select Date Range",
    ),
    "date_range_select_range": MessageLookupByLibrary.simpleMessage(
      "Select range",
    ),
    "date_range_start": MessageLookupByLibrary.simpleMessage("Start date"),
    "datetime_field_date": MessageLookupByLibrary.simpleMessage("Date"),
    "datetime_field_time": MessageLookupByLibrary.simpleMessage("Time"),
    "delivery_add_address": MessageLookupByLibrary.simpleMessage(
      "Add a new address",
    ),
    "delivery_change_address": MessageLookupByLibrary.simpleMessage(
      "Send it somewhere else",
    ),
    "delivery_chose_delivery": MessageLookupByLibrary.simpleMessage(
      "This piece is being delivered to you",
    ),
    "delivery_chose_pickup": MessageLookupByLibrary.simpleMessage(
      "You are collecting this from the studio",
    ),
    "delivery_close": MessageLookupByLibrary.simpleMessage("Close"),
    "delivery_confirm_and_pay": MessageLookupByLibrary.simpleMessage(
      "Confirm delivery and pay",
    ),
    "delivery_continue": MessageLookupByLibrary.simpleMessage(
      "Continue to payment",
    ),
    "delivery_deliver": MessageLookupByLibrary.simpleMessage("Deliver"),
    "delivery_fee_line": MessageLookupByLibrary.simpleMessage("Piece delivery"),
    "delivery_no_address": MessageLookupByLibrary.simpleMessage(
      "You have no saved address yet.",
    ),
    "delivery_paint_it": MessageLookupByLibrary.simpleMessage("Paint my cup"),
    "delivery_paint_pick_title": MessageLookupByLibrary.simpleMessage(
      "Where would you like to paint it?",
    ),
    "delivery_phone": MessageLookupByLibrary.simpleMessage(
      "Delivery phone number",
    ),
    "delivery_pickup": MessageLookupByLibrary.simpleMessage("Pick up"),
    "delivery_pickup_confirm_body": MessageLookupByLibrary.simpleMessage(
      "We will hold your piece at the studio, and you can switch back to delivery any time before you collect it.",
    ),
    "delivery_pickup_confirm_body_refund": m86,
    "delivery_pickup_confirm_title": MessageLookupByLibrary.simpleMessage(
      "Collect it yourself?",
    ),
    "delivery_pickup_confirm_yes": MessageLookupByLibrary.simpleMessage(
      "Yes, I will collect it",
    ),
    "delivery_pickup_credited": m87,
    "delivery_pickup_done": MessageLookupByLibrary.simpleMessage(
      "You will collect it from the studio.",
    ),
    "delivery_piece_ready": MessageLookupByLibrary.simpleMessage(
      "Your piece is ready",
    ),
    "delivery_piece_ready_body": MessageLookupByLibrary.simpleMessage(
      "Your piece is ready for pickup or delivery.",
    ),
    "delivery_status_awaiting_pickup": MessageLookupByLibrary.simpleMessage(
      "Ready to collect",
    ),
    "delivery_status_completed": MessageLookupByLibrary.simpleMessage(
      "Delivered",
    ),
    "delivery_status_getting_ready": MessageLookupByLibrary.simpleMessage(
      "Being wrapped",
    ),
    "delivery_status_on_the_way": MessageLookupByLibrary.simpleMessage(
      "Out for delivery",
    ),
    "delivery_switch_to_delivery": MessageLookupByLibrary.simpleMessage(
      "Have it delivered instead",
    ),
    "delivery_switch_to_pickup": MessageLookupByLibrary.simpleMessage(
      "Collect it myself instead",
    ),
    "delivery_warning_body": m88,
    "delivery_warning_title": MessageLookupByLibrary.simpleMessage("Heads up"),
    "delivery_where_title": MessageLookupByLibrary.simpleMessage(
      "Where should we send it?",
    ),
    "dialog_closing_in": m89,
    "dialog_confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "dialog_enter_text_hint": MessageLookupByLibrary.simpleMessage(
      "Enter text...",
    ),
    "drawer_expand": MessageLookupByLibrary.simpleMessage("Expand"),
    "drawer_no_items_match": m90,
    "drawer_no_results": MessageLookupByLibrary.simpleMessage(
      "No results found",
    ),
    "drop_down_blood_type_hint": MessageLookupByLibrary.simpleMessage(
      "Select blood type",
    ),
    "drop_down_blood_type_label": MessageLookupByLibrary.simpleMessage(
      "Blood type",
    ),
    "drop_down_city_hint": MessageLookupByLibrary.simpleMessage(
      "Select a city / area",
    ),
    "drop_down_clear_all": MessageLookupByLibrary.simpleMessage("Clear All"),
    "drop_down_clear_selection": MessageLookupByLibrary.simpleMessage(
      "Clear selection",
    ),
    "drop_down_color_format_hint": MessageLookupByLibrary.simpleMessage(
      "Select format",
    ),
    "drop_down_color_format_label": MessageLookupByLibrary.simpleMessage(
      "Format",
    ),
    "drop_down_country_hint": MessageLookupByLibrary.simpleMessage("Country"),
    "drop_down_create_new": m91,
    "drop_down_currency_hint": MessageLookupByLibrary.simpleMessage(
      "Select currency",
    ),
    "drop_down_day_hint": MessageLookupByLibrary.simpleMessage("Select day"),
    "drop_down_day_label": MessageLookupByLibrary.simpleMessage("Day"),
    "drop_down_duration_hint": MessageLookupByLibrary.simpleMessage(
      "Select duration",
    ),
    "drop_down_duration_label": MessageLookupByLibrary.simpleMessage(
      "Duration",
    ),
    "drop_down_education_hint": MessageLookupByLibrary.simpleMessage(
      "Select level",
    ),
    "drop_down_education_label": MessageLookupByLibrary.simpleMessage(
      "Education",
    ),
    "drop_down_gender_hint": MessageLookupByLibrary.simpleMessage(
      "Select gender",
    ),
    "drop_down_gender_label": MessageLookupByLibrary.simpleMessage("Gender"),
    "drop_down_hour_hint": MessageLookupByLibrary.simpleMessage("Select hour"),
    "drop_down_hour_label": MessageLookupByLibrary.simpleMessage("Hour"),
    "drop_down_language_hint": MessageLookupByLibrary.simpleMessage(
      "Select language",
    ),
    "drop_down_language_label": MessageLookupByLibrary.simpleMessage(
      "Language",
    ),
    "drop_down_load_failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load options",
    ),
    "drop_down_marital_status_hint": MessageLookupByLibrary.simpleMessage(
      "Select status",
    ),
    "drop_down_marital_status_label": MessageLookupByLibrary.simpleMessage(
      "Marital status",
    ),
    "drop_down_month_hint": MessageLookupByLibrary.simpleMessage(
      "Select month",
    ),
    "drop_down_month_label": MessageLookupByLibrary.simpleMessage("Month"),
    "drop_down_more_items": m92,
    "drop_down_nationality_hint": MessageLookupByLibrary.simpleMessage(
      "Nationality",
    ),
    "drop_down_no_results": MessageLookupByLibrary.simpleMessage(
      "No results found",
    ),
    "drop_down_recurrence_hint": MessageLookupByLibrary.simpleMessage(
      "Select repeat",
    ),
    "drop_down_recurrence_label": MessageLookupByLibrary.simpleMessage(
      "Repeat",
    ),
    "drop_down_search": MessageLookupByLibrary.simpleMessage("Search"),
    "drop_down_select_all": MessageLookupByLibrary.simpleMessage("Select All"),
    "drop_down_select_option": MessageLookupByLibrary.simpleMessage(
      "Select an option",
    ),
    "drop_down_select_options": MessageLookupByLibrary.simpleMessage(
      "Select options",
    ),
    "drop_down_selected_count": m93,
    "drop_down_selected_of_max": m94,
    "drop_down_sort_by_hint": MessageLookupByLibrary.simpleMessage("Sort by"),
    "drop_down_sort_by_label": MessageLookupByLibrary.simpleMessage("Sort by"),
    "drop_down_state_hint": MessageLookupByLibrary.simpleMessage(
      "Select a governorate / region",
    ),
    "drop_down_tap_to_close": MessageLookupByLibrary.simpleMessage(
      "Double tap to close",
    ),
    "drop_down_tap_to_open": MessageLookupByLibrary.simpleMessage(
      "Double tap to open",
    ),
    "drop_down_theme_hint": MessageLookupByLibrary.simpleMessage(
      "Select theme",
    ),
    "drop_down_theme_label": MessageLookupByLibrary.simpleMessage("Theme"),
    "drop_down_timezone_hint": MessageLookupByLibrary.simpleMessage(
      "Select timezone",
    ),
    "drop_down_unit_hint": MessageLookupByLibrary.simpleMessage("Select unit"),
    "drop_down_weekday_hint": MessageLookupByLibrary.simpleMessage(
      "Select weekday",
    ),
    "drop_down_weekday_label": MessageLookupByLibrary.simpleMessage("Weekday"),
    "drop_down_year_hint": MessageLookupByLibrary.simpleMessage("Select year"),
    "drop_down_year_label": MessageLookupByLibrary.simpleMessage("Year"),
    "duration_days": m95,
    "duration_field_hours_word": MessageLookupByLibrary.simpleMessage("Hours"),
    "duration_field_incomplete": MessageLookupByLibrary.simpleMessage(
      "Enter a complete duration",
    ),
    "duration_field_max": m96,
    "duration_field_min": m97,
    "duration_field_minutes": m98,
    "duration_field_minutes_word": MessageLookupByLibrary.simpleMessage(
      "Minutes",
    ),
    "duration_field_pick": MessageLookupByLibrary.simpleMessage(
      "Pick duration",
    ),
    "duration_field_required": MessageLookupByLibrary.simpleMessage(
      "Duration is required",
    ),
    "duration_field_seconds": m99,
    "duration_field_seconds_word": MessageLookupByLibrary.simpleMessage(
      "Seconds",
    ),
    "duration_field_step": m100,
    "duration_hours": m101,
    "duration_minutes": m102,
    "education_bachelor": MessageLookupByLibrary.simpleMessage("Bachelor\'s"),
    "education_diploma": MessageLookupByLibrary.simpleMessage("Diploma"),
    "education_doctorate": MessageLookupByLibrary.simpleMessage("Doctorate"),
    "education_master": MessageLookupByLibrary.simpleMessage("Master\'s"),
    "education_middle": MessageLookupByLibrary.simpleMessage("Middle school"),
    "education_primary": MessageLookupByLibrary.simpleMessage("Primary"),
    "education_secondary": MessageLookupByLibrary.simpleMessage("High school"),
    "empty_clear_search": MessageLookupByLibrary.simpleMessage("Clear search"),
    "empty_failed_subtitle": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load this. Try again in a moment.",
    ),
    "empty_failed_title": MessageLookupByLibrary.simpleMessage(
      "Something went wrong",
    ),
    "empty_no_results_subtitle": MessageLookupByLibrary.simpleMessage(
      "Try a different spelling, or fewer words.",
    ),
    "empty_no_results_title": m103,
    "empty_offline_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check your connection and try again.",
    ),
    "empty_offline_title": MessageLookupByLibrary.simpleMessage(
      "You\'re offline",
    ),
    "empty_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "error_boundary_fallback_title": MessageLookupByLibrary.simpleMessage(
      "Something went wrong",
    ),
    "error_boundary_release_body": MessageLookupByLibrary.simpleMessage(
      "Try again in a moment.",
    ),
    "error_boundary_release_title": MessageLookupByLibrary.simpleMessage(
      "This part didn\'t load",
    ),
    "error_copy_diagnostics": MessageLookupByLibrary.simpleMessage(
      "Copy diagnostics",
    ),
    "error_default_message": MessageLookupByLibrary.simpleMessage(
      "We hit an unexpected error. You can try again — if it keeps happening, send us the diagnostics so we can fix it.",
    ),
    "error_diagnostics": MessageLookupByLibrary.simpleMessage("Diagnostics"),
    "error_diagnostics_copied": MessageLookupByLibrary.simpleMessage(
      "Diagnostics copied to clipboard",
    ),
    "error_email_support": MessageLookupByLibrary.simpleMessage(
      "Email support",
    ),
    "error_no_email_app": MessageLookupByLibrary.simpleMessage(
      "No email app available",
    ),
    "error_offline_hint": MessageLookupByLibrary.simpleMessage(
      "You\'re offline. The error may go away once you reconnect.",
    ),
    "error_report_failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t send the report. Please try again.",
    ),
    "error_report_sent": MessageLookupByLibrary.simpleMessage(
      "Report sent — thanks",
    ),
    "error_report_this": MessageLookupByLibrary.simpleMessage("Report this"),
    "error_support_email_unconfigured": MessageLookupByLibrary.simpleMessage(
      "Support email isn\'t set up yet.",
    ),
    "faq_all": MessageLookupByLibrary.simpleMessage("All"),
    "faq_feedback_recorded": MessageLookupByLibrary.simpleMessage(
      "Feedback recorded",
    ),
    "faq_help_center": MessageLookupByLibrary.simpleMessage("Help center"),
    "faq_helpful": MessageLookupByLibrary.simpleMessage("Helpful"),
    "faq_load_failed": MessageLookupByLibrary.simpleMessage(
      "Failed to load help center",
    ),
    "faq_marked_helpful": MessageLookupByLibrary.simpleMessage(
      "Marked helpful",
    ),
    "faq_no_articles_yet": MessageLookupByLibrary.simpleMessage(
      "No help articles yet",
    ),
    "faq_no_matching_answers": MessageLookupByLibrary.simpleMessage(
      "No matching answers",
    ),
    "faq_not_helpful": MessageLookupByLibrary.simpleMessage("Not helpful"),
    "faq_recent": MessageLookupByLibrary.simpleMessage("Recent"),
    "faq_search_hint": MessageLookupByLibrary.simpleMessage("Search help…"),
    "faq_still_need_help": MessageLookupByLibrary.simpleMessage(
      "Still need help?",
    ),
    "faq_thanks_feedback_recorded": MessageLookupByLibrary.simpleMessage(
      "Thanks — feedback recorded",
    ),
    "faq_thanks_marked_helpful": MessageLookupByLibrary.simpleMessage(
      "Thanks — you marked this helpful",
    ),
    "faq_was_this_helpful": MessageLookupByLibrary.simpleMessage(
      "Was this helpful?",
    ),
    "feedback_attachment_too_large": MessageLookupByLibrary.simpleMessage(
      "Attachment too large after compression",
    ),
    "feedback_attachments_label": MessageLookupByLibrary.simpleMessage(
      "Attachments",
    ),
    "feedback_cooldown_hint": MessageLookupByLibrary.simpleMessage(
      "Hold on a moment before sending another.",
    ),
    "feedback_cooldown_title": MessageLookupByLibrary.simpleMessage(
      "Slow down",
    ),
    "feedback_description_hint": MessageLookupByLibrary.simpleMessage(
      "What happened? What did you expect?",
    ),
    "feedback_description_label": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "feedback_description_required": MessageLookupByLibrary.simpleMessage(
      "Description is required",
    ),
    "feedback_diagnostics_hint": MessageLookupByLibrary.simpleMessage(
      "Device, app version, and recent activity. Helps us reproduce.",
    ),
    "feedback_diagnostics_label": MessageLookupByLibrary.simpleMessage(
      "Diagnostics",
    ),
    "feedback_disabled": MessageLookupByLibrary.simpleMessage(
      "Feedback is unavailable.",
    ),
    "feedback_email_invalid": MessageLookupByLibrary.simpleMessage(
      "That email doesn\'t look right",
    ),
    "feedback_email_label": MessageLookupByLibrary.simpleMessage(
      "Email (optional)",
    ),
    "feedback_error_email_open_failed": m104,
    "feedback_error_no_email_app": MessageLookupByLibrary.simpleMessage(
      "No email app available",
    ),
    "feedback_error_no_endpoint": MessageLookupByLibrary.simpleMessage(
      "No feedback endpoint configured",
    ),
    "feedback_failure_body": MessageLookupByLibrary.simpleMessage(
      "Something blocked the submission. Try again?",
    ),
    "feedback_failure_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t send",
    ),
    "feedback_offline_queued_body": MessageLookupByLibrary.simpleMessage(
      "Saved for later — will send when you reconnect.",
    ),
    "feedback_offline_queued_title": MessageLookupByLibrary.simpleMessage(
      "You\'re offline",
    ),
    "feedback_pick_camera": MessageLookupByLibrary.simpleMessage("From camera"),
    "feedback_pick_gallery": MessageLookupByLibrary.simpleMessage(
      "From gallery",
    ),
    "feedback_repro_hint": MessageLookupByLibrary.simpleMessage(
      "1. Open …\n2. Tap …\n3. See …",
    ),
    "feedback_repro_label": MessageLookupByLibrary.simpleMessage(
      "Steps to reproduce",
    ),
    "feedback_send_feedback": MessageLookupByLibrary.simpleMessage(
      "Send feedback",
    ),
    "feedback_severity_blocking": MessageLookupByLibrary.simpleMessage(
      "Blocking",
    ),
    "feedback_severity_blocking_subtitle": MessageLookupByLibrary.simpleMessage(
      "Cannot use the app",
    ),
    "feedback_severity_high": MessageLookupByLibrary.simpleMessage("High"),
    "feedback_severity_high_subtitle": MessageLookupByLibrary.simpleMessage(
      "Hard to work around",
    ),
    "feedback_severity_label": MessageLookupByLibrary.simpleMessage("Severity"),
    "feedback_severity_low": MessageLookupByLibrary.simpleMessage("Low"),
    "feedback_severity_low_subtitle": MessageLookupByLibrary.simpleMessage(
      "Minor — easy workaround",
    ),
    "feedback_severity_medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "feedback_severity_medium_subtitle": MessageLookupByLibrary.simpleMessage(
      "Affects normal flow",
    ),
    "feedback_submit": MessageLookupByLibrary.simpleMessage("Send"),
    "feedback_submitting": MessageLookupByLibrary.simpleMessage("Sending…"),
    "feedback_subtitle": MessageLookupByLibrary.simpleMessage(
      "We read everything. Tell us what\'s up.",
    ),
    "feedback_success_body": MessageLookupByLibrary.simpleMessage(
      "We got it. We\'ll follow up at your email if you left one.",
    ),
    "feedback_success_title": MessageLookupByLibrary.simpleMessage(
      "Thanks for the heads-up",
    ),
    "feedback_title": MessageLookupByLibrary.simpleMessage("Send feedback"),
    "feedback_type_bug": MessageLookupByLibrary.simpleMessage("Bug"),
    "feedback_type_bug_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something is broken or wrong",
    ),
    "feedback_type_label": MessageLookupByLibrary.simpleMessage("Type"),
    "feedback_type_other": MessageLookupByLibrary.simpleMessage("Other"),
    "feedback_type_other_subtitle": MessageLookupByLibrary.simpleMessage(
      "Anything else",
    ),
    "feedback_type_question": MessageLookupByLibrary.simpleMessage("Question"),
    "feedback_type_question_subtitle": MessageLookupByLibrary.simpleMessage(
      "Need help figuring something out",
    ),
    "feedback_type_suggestion": MessageLookupByLibrary.simpleMessage(
      "Suggestion",
    ),
    "feedback_type_suggestion_subtitle": MessageLookupByLibrary.simpleMessage(
      "Idea for an improvement",
    ),
    "field_hint_cardholder": MessageLookupByLibrary.simpleMessage(
      "Name on card",
    ),
    "field_hint_email": MessageLookupByLibrary.simpleMessage(
      "Enter your email",
    ),
    "field_hint_name": MessageLookupByLibrary.simpleMessage("Your name"),
    "field_hint_passport": MessageLookupByLibrary.simpleMessage(
      "Enter passport number",
    ),
    "field_hint_phone": MessageLookupByLibrary.simpleMessage(
      "Enter phone number",
    ),
    "field_hint_search": MessageLookupByLibrary.simpleMessage("Search"),
    "field_hint_username": MessageLookupByLibrary.simpleMessage(
      "Choose a username",
    ),
    "field_label_code": MessageLookupByLibrary.simpleMessage("Code"),
    "field_label_confirm_password": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "field_label_email": MessageLookupByLibrary.simpleMessage("Email"),
    "field_label_name": MessageLookupByLibrary.simpleMessage("Name"),
    "field_label_number": MessageLookupByLibrary.simpleMessage("Number"),
    "field_label_password": MessageLookupByLibrary.simpleMessage("Password"),
    "field_label_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "field_label_url": MessageLookupByLibrary.simpleMessage("URL"),
    "field_label_username": MessageLookupByLibrary.simpleMessage("Username"),
    "gallery_album_empty": MessageLookupByLibrary.simpleMessage(
      "No photos in this album yet",
    ),
    "gallery_counts": m105,
    "gallery_counts_photos": m106,
    "gallery_counts_videos": m107,
    "gallery_empty": MessageLookupByLibrary.simpleMessage("No albums yet"),
    "gallery_subtitle": MessageLookupByLibrary.simpleMessage(
      "Pieces made by visitors like you — every picture is clay turning into something real.",
    ),
    "gallery_title": MessageLookupByLibrary.simpleMessage("Terracotta moments"),
    "gender_female": MessageLookupByLibrary.simpleMessage("Female"),
    "gender_male": MessageLookupByLibrary.simpleMessage("Male"),
    "gender_other": MessageLookupByLibrary.simpleMessage("Other"),
    "gender_prefer_not_to_say": MessageLookupByLibrary.simpleMessage(
      "Prefer not to say",
    ),
    "gift_amount": m108,
    "gift_claim_already": MessageLookupByLibrary.simpleMessage(
      "This gift has already been claimed.",
    ),
    "gift_claim_browse": MessageLookupByLibrary.simpleMessage(
      "Browse the studio",
    ),
    "gift_claim_cta": MessageLookupByLibrary.simpleMessage("Add to my wallet"),
    "gift_claim_done_body": m109,
    "gift_claim_done_title": MessageLookupByLibrary.simpleMessage(
      "It is in your wallet",
    ),
    "gift_claim_from": m110,
    "gift_claim_not_found": MessageLookupByLibrary.simpleMessage(
      "We could not find this gift. The link may be wrong, or the person sending it may not have finished paying for it yet.",
    ),
    "gift_claim_open_wallet": MessageLookupByLibrary.simpleMessage(
      "Open my wallet",
    ),
    "gift_claim_signed_out": MessageLookupByLibrary.simpleMessage(
      "Sign in to add it to your wallet.",
    ),
    "gift_claim_title": MessageLookupByLibrary.simpleMessage("A gift for you"),
    "gift_claim_to": m111,
    "gift_claim_unavailable": MessageLookupByLibrary.simpleMessage(
      "This gift cannot be claimed.",
    ),
    "gift_confirm_and_pay": MessageLookupByLibrary.simpleMessage(
      "Confirm gift and pay",
    ),
    "gift_copy_link": MessageLookupByLibrary.simpleMessage("Copy link"),
    "gift_empty": MessageLookupByLibrary.simpleMessage(
      "You have not sent any gifts yet",
    ),
    "gift_filter_all": MessageLookupByLibrary.simpleMessage("All"),
    "gift_filter_received": MessageLookupByLibrary.simpleMessage("Claimed"),
    "gift_filter_sent": MessageLookupByLibrary.simpleMessage("Sent"),
    "gift_for": m112,
    "gift_from": m113,
    "gift_from_someone": MessageLookupByLibrary.simpleMessage(
      "A gift you claimed",
    ),
    "gift_hero_body": MessageLookupByLibrary.simpleMessage(
      "Send a balance to someone you love, for pottery and ceramics workshops",
    ),
    "gift_link_copied": MessageLookupByLibrary.simpleMessage("Link copied"),
    "gift_message": MessageLookupByLibrary.simpleMessage("Message"),
    "gift_message_hint": MessageLookupByLibrary.simpleMessage(
      "Write your message here...",
    ),
    "gift_none_received": MessageLookupByLibrary.simpleMessage(
      "You have not claimed any gifts yet",
    ),
    "gift_none_sent": MessageLookupByLibrary.simpleMessage(
      "You have not sent any gifts yet",
    ),
    "gift_purchased_body": MessageLookupByLibrary.simpleMessage(
      "Copy the link and send it to whoever the gift is for, to enjoy Terracotta workshops",
    ),
    "gift_purchased_title": MessageLookupByLibrary.simpleMessage(
      "Gift purchased!",
    ),
    "gift_recipient_hint": MessageLookupByLibrary.simpleMessage("Sara"),
    "gift_recipient_name": MessageLookupByLibrary.simpleMessage(
      "Recipient name",
    ),
    "gift_recipient_phone": MessageLookupByLibrary.simpleMessage(
      "Recipient phone",
    ),
    "gift_recipient_phone_hint": MessageLookupByLibrary.simpleMessage(
      "05XXXXXXXX",
    ),
    "gift_share_link": MessageLookupByLibrary.simpleMessage("Share the link"),
    "gift_state_cancelled": MessageLookupByLibrary.simpleMessage(
      "Expired unpaid",
    ),
    "gift_state_claimed": MessageLookupByLibrary.simpleMessage("Claimed"),
    "gift_state_unclaimed": MessageLookupByLibrary.simpleMessage(
      "Not claimed yet",
    ),
    "gift_state_unpaid": MessageLookupByLibrary.simpleMessage("Not paid"),
    "gift_tab_mine": MessageLookupByLibrary.simpleMessage("My gifts"),
    "gift_tab_send": MessageLookupByLibrary.simpleMessage("Send a gift"),
    "gift_title": MessageLookupByLibrary.simpleMessage("Gift a balance"),
    "home_badge_featured": MessageLookupByLibrary.simpleMessage("Featured"),
    "home_browse_categories": MessageLookupByLibrary.simpleMessage(
      "Browse categories",
    ),
    "home_continue_workshop": MessageLookupByLibrary.simpleMessage(
      "Continue your workshop",
    ),
    "home_featured": MessageLookupByLibrary.simpleMessage("Featured pieces"),
    "home_greeting": m114,
    "home_live_items": m115,
    "home_live_order": MessageLookupByLibrary.simpleMessage("Your order"),
    "home_live_order_eta": m116,
    "home_live_show_code": MessageLookupByLibrary.simpleMessage("Show my code"),
    "home_live_workshop": MessageLookupByLibrary.simpleMessage("Happening now"),
    "home_live_workshop_until": m117,
    "home_next_booking": MessageLookupByLibrary.simpleMessage(
      "Your next workshop",
    ),
    "home_next_booking_when": m118,
    "home_offers": MessageLookupByLibrary.simpleMessage("Latest offers"),
    "home_see_all": MessageLookupByLibrary.simpleMessage("See all"),
    "home_see_all_count": m119,
    "home_title": MessageLookupByLibrary.simpleMessage("Home"),
    "indicator_go_to_page": m120,
    "indicator_page_of": m121,
    "indicator_story_paused": MessageLookupByLibrary.simpleMessage("paused"),
    "indicator_story_playing": MessageLookupByLibrary.simpleMessage("playing"),
    "indicator_story_segment": m122,
    "ip_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter IP or hostname",
    ),
    "ip_field_invalid_host": MessageLookupByLibrary.simpleMessage(
      "Invalid hostname",
    ),
    "ip_field_invalid_ip": MessageLookupByLibrary.simpleMessage(
      "Invalid IP address",
    ),
    "ip_field_invalid_port": MessageLookupByLibrary.simpleMessage(
      "Invalid port",
    ),
    "ip_field_required": MessageLookupByLibrary.simpleMessage(
      "Address is required",
    ),
    "language_name_ar": MessageLookupByLibrary.simpleMessage("Arabic"),
    "language_name_en": MessageLookupByLibrary.simpleMessage("English"),
    "legal_check_connection_body": MessageLookupByLibrary.simpleMessage(
      "Check your connection and try again.",
    ),
    "legal_page_disabled_body": MessageLookupByLibrary.simpleMessage(
      "This page is currently disabled.",
    ),
    "legal_page_load_failed": m123,
    "legal_page_unavailable": m124,
    "legal_section_label": MessageLookupByLibrary.simpleMessage(
      "Legal & information",
    ),
    "legal_title_about": MessageLookupByLibrary.simpleMessage("About"),
    "legal_title_contact": MessageLookupByLibrary.simpleMessage(
      "Contact & Support",
    ),
    "legal_title_credits": MessageLookupByLibrary.simpleMessage("Credits"),
    "legal_title_eula": MessageLookupByLibrary.simpleMessage(
      "End User License Agreement",
    ),
    "legal_title_licenses": MessageLookupByLibrary.simpleMessage(
      "Open-source Licenses",
    ),
    "legal_title_privacy": MessageLookupByLibrary.simpleMessage(
      "Privacy Policy",
    ),
    "legal_title_refund": MessageLookupByLibrary.simpleMessage(
      "Refund & Cancellation",
    ),
    "legal_title_tos": MessageLookupByLibrary.simpleMessage("Terms of Service"),
    "legal_version": m125,
    "legal_version_build": m126,
    "list_clear_selection": MessageLookupByLibrary.simpleMessage(
      "Clear selection",
    ),
    "list_empty_title": MessageLookupByLibrary.simpleMessage(
      "Nothing here yet",
    ),
    "list_load_more": MessageLookupByLibrary.simpleMessage("Load more"),
    "list_more_pages": MessageLookupByLibrary.simpleMessage("More pages"),
    "list_next_page": MessageLookupByLibrary.simpleMessage("Next page"),
    "list_page": m127,
    "list_page_of": m128,
    "list_previous_page": MessageLookupByLibrary.simpleMessage("Previous page"),
    "list_section_index": MessageLookupByLibrary.simpleMessage("Section index"),
    "list_selected_count": m129,
    "location_field_confirm": MessageLookupByLibrary.simpleMessage(
      "Confirm location",
    ),
    "location_field_label": MessageLookupByLibrary.simpleMessage(
      "Exact location",
    ),
    "location_field_lat_range": MessageLookupByLibrary.simpleMessage(
      "Latitude must be between -90 and 90",
    ),
    "location_field_latitude": MessageLookupByLibrary.simpleMessage("Latitude"),
    "location_field_lng_range": MessageLookupByLibrary.simpleMessage(
      "Longitude must be between -180 and 180",
    ),
    "location_field_longitude": MessageLookupByLibrary.simpleMessage(
      "Longitude",
    ),
    "location_field_pick_map": MessageLookupByLibrary.simpleMessage(
      "Pick on map",
    ),
    "location_field_unavailable": MessageLookupByLibrary.simpleMessage(
      "Location unavailable — check GPS and permissions",
    ),
    "location_field_use_current": MessageLookupByLibrary.simpleMessage(
      "Use current location",
    ),
    "login_field_hint": MessageLookupByLibrary.simpleMessage(
      "Email or phone number",
    ),
    "maintenance_back_eta": m130,
    "maintenance_default_message": MessageLookupByLibrary.simpleMessage(
      "The service is temporarily unavailable. Please check back shortly.",
    ),
    "maintenance_default_title": MessageLookupByLibrary.simpleMessage(
      "We\'ll be right back",
    ),
    "maintenance_eta_any_moment": MessageLookupByLibrary.simpleMessage(
      "any moment now",
    ),
    "maintenance_eta_hours_minutes": m131,
    "maintenance_eta_minutes": m132,
    "maintenance_eta_seconds": m133,
    "maintenance_retry_in_seconds": m134,
    "maintenance_scheduled_message": MessageLookupByLibrary.simpleMessage(
      "We are performing scheduled maintenance. Please try again later.",
    ),
    "marital_divorced": MessageLookupByLibrary.simpleMessage("Divorced"),
    "marital_married": MessageLookupByLibrary.simpleMessage("Married"),
    "marital_single": MessageLookupByLibrary.simpleMessage("Single"),
    "marital_widowed": MessageLookupByLibrary.simpleMessage("Widowed"),
    "measurement_field_all_units": MessageLookupByLibrary.simpleMessage(
      "All units",
    ),
    "measurement_field_preferred_units": MessageLookupByLibrary.simpleMessage(
      "Common",
    ),
    "media_add_attachment": MessageLookupByLibrary.simpleMessage(
      "Add attachment",
    ),
    "media_add_file": MessageLookupByLibrary.simpleMessage("Add a file"),
    "media_add_photo": MessageLookupByLibrary.simpleMessage("Add a photo"),
    "media_add_video": MessageLookupByLibrary.simpleMessage("Add a video"),
    "media_browse": MessageLookupByLibrary.simpleMessage("Browse"),
    "media_browse_subtitle": MessageLookupByLibrary.simpleMessage(
      "Choose from your files",
    ),
    "media_camera": MessageLookupByLibrary.simpleMessage("Camera"),
    "media_camera_subtitle": MessageLookupByLibrary.simpleMessage(
      "Take a new photo",
    ),
    "media_cannot_preview_bytes": MessageLookupByLibrary.simpleMessage(
      "Cannot preview this — it has not been saved yet",
    ),
    "media_choose_file": MessageLookupByLibrary.simpleMessage("Choose file"),
    "media_clipboard": MessageLookupByLibrary.simpleMessage("Clipboard"),
    "media_clipboard_empty": MessageLookupByLibrary.simpleMessage(
      "Clipboard (empty)",
    ),
    "media_clipboard_subtitle": MessageLookupByLibrary.simpleMessage(
      "Paste what you copied",
    ),
    "media_copy_failed": MessageLookupByLibrary.simpleMessage("Copy failed"),
    "media_copy_file_tooltip": MessageLookupByLibrary.simpleMessage(
      "Copy file to clipboard",
    ),
    "media_copy_image_tooltip": MessageLookupByLibrary.simpleMessage(
      "Copy image to clipboard",
    ),
    "media_copy_video_tooltip": MessageLookupByLibrary.simpleMessage(
      "Copy video to clipboard",
    ),
    "media_crop_review_subtitle": MessageLookupByLibrary.simpleMessage(
      "Tap a tile to crop. Red tiles must be cropped to continue.",
    ),
    "media_crop_review_title": MessageLookupByLibrary.simpleMessage("Review"),
    "media_crop_title": MessageLookupByLibrary.simpleMessage("Crop"),
    "media_download_item": MessageLookupByLibrary.simpleMessage("Download"),
    "media_duplicate_skipped": MessageLookupByLibrary.simpleMessage(
      "Already added",
    ),
    "media_existing_badge": MessageLookupByLibrary.simpleMessage("EARLIER"),
    "media_existing_item": MessageLookupByLibrary.simpleMessage(
      "Already uploaded",
    ),
    "media_extension_not_allowed": m135,
    "media_failed_to_compress_image": MessageLookupByLibrary.simpleMessage(
      "Failed to compress image",
    ),
    "media_failed_to_pick_image": MessageLookupByLibrary.simpleMessage(
      "Failed to pick image",
    ),
    "media_failed_to_pick_images": MessageLookupByLibrary.simpleMessage(
      "Failed to pick images",
    ),
    "media_failed_to_pick_video": MessageLookupByLibrary.simpleMessage(
      "Failed to pick video",
    ),
    "media_failed_to_pick_videos": MessageLookupByLibrary.simpleMessage(
      "Failed to pick videos",
    ),
    "media_file": MessageLookupByLibrary.simpleMessage("File"),
    "media_file_copied": MessageLookupByLibrary.simpleMessage(
      "File copied to clipboard",
    ),
    "media_file_too_large": m136,
    "media_gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "media_gallery_subtitle": MessageLookupByLibrary.simpleMessage(
      "Choose from your photos",
    ),
    "media_image_copied": MessageLookupByLibrary.simpleMessage(
      "Image copied to clipboard",
    ),
    "media_image_too_large": m137,
    "media_image_too_large_compression_failed":
        MessageLookupByLibrary.simpleMessage(
          "Image too large, compression failed",
        ),
    "media_image_too_small": m138,
    "media_item_of": m139,
    "media_limit_dropped": m140,
    "media_limit_reached": MessageLookupByLibrary.simpleMessage(
      "Limit reached",
    ),
    "media_more_actions": MessageLookupByLibrary.simpleMessage("More actions"),
    "media_move_left": MessageLookupByLibrary.simpleMessage("Move left"),
    "media_move_right": MessageLookupByLibrary.simpleMessage("Move right"),
    "media_moved_to": m141,
    "media_must_crop": MessageLookupByLibrary.simpleMessage("Must crop"),
    "media_new_badge": MessageLookupByLibrary.simpleMessage("NEW"),
    "media_new_item": MessageLookupByLibrary.simpleMessage("Not uploaded yet"),
    "media_open_failed": m142,
    "media_photo": MessageLookupByLibrary.simpleMessage("Photo"),
    "media_play_pause": MessageLookupByLibrary.simpleMessage("Play / pause"),
    "media_preparing": MessageLookupByLibrary.simpleMessage("Preparing…"),
    "media_realign": MessageLookupByLibrary.simpleMessage("Re-align"),
    "media_recent": MessageLookupByLibrary.simpleMessage("Recent"),
    "media_record": MessageLookupByLibrary.simpleMessage("Record"),
    "media_remove_item": MessageLookupByLibrary.simpleMessage("Remove"),
    "media_reorder_hint": MessageLookupByLibrary.simpleMessage(
      "Drag to reorder",
    ),
    "media_rotate": MessageLookupByLibrary.simpleMessage("Rotate"),
    "media_selected_count": m143,
    "media_share": MessageLookupByLibrary.simpleMessage("Share"),
    "media_trim_video": MessageLookupByLibrary.simpleMessage("Trim video"),
    "media_upload_cancel": MessageLookupByLibrary.simpleMessage(
      "Stop uploading",
    ),
    "media_upload_cancelled": MessageLookupByLibrary.simpleMessage(
      "Upload stopped",
    ),
    "media_upload_retry": MessageLookupByLibrary.simpleMessage("Upload again"),
    "media_uploading": MessageLookupByLibrary.simpleMessage("Uploading"),
    "media_url_copied": MessageLookupByLibrary.simpleMessage(
      "URL copied to clipboard",
    ),
    "media_video": MessageLookupByLibrary.simpleMessage("Video"),
    "media_video_copied": MessageLookupByLibrary.simpleMessage(
      "Video copied to clipboard",
    ),
    "media_wrong_aspect_ratio": m144,
    "money_currency": MessageLookupByLibrary.simpleMessage("SAR"),
    "national_id_birthdate": MessageLookupByLibrary.simpleMessage(
      "The embedded birth date is invalid",
    ),
    "national_id_born": m145,
    "national_id_checksum": MessageLookupByLibrary.simpleMessage(
      "Invalid ID number",
    ),
    "national_id_citizen": MessageLookupByLibrary.simpleMessage("Citizen"),
    "national_id_citizens_only": MessageLookupByLibrary.simpleMessage(
      "Citizens only",
    ),
    "national_id_dob_mismatch": MessageLookupByLibrary.simpleMessage(
      "ID doesn\'t match the birth date",
    ),
    "national_id_female": MessageLookupByLibrary.simpleMessage("Female"),
    "national_id_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter national ID",
    ),
    "national_id_generic": MessageLookupByLibrary.simpleMessage(
      "Enter a valid ID number",
    ),
    "national_id_governorate": MessageLookupByLibrary.simpleMessage(
      "Unknown governorate code",
    ),
    "national_id_length": m146,
    "national_id_male": MessageLookupByLibrary.simpleMessage("Male"),
    "national_id_prefix": MessageLookupByLibrary.simpleMessage(
      "Invalid ID prefix",
    ),
    "national_id_required": MessageLookupByLibrary.simpleMessage(
      "National ID is required",
    ),
    "national_id_resident": MessageLookupByLibrary.simpleMessage("Resident"),
    "national_id_residents_only": MessageLookupByLibrary.simpleMessage(
      "Residents only",
    ),
    "nationality_afghanistan": MessageLookupByLibrary.simpleMessage("Afghan"),
    "nationality_albania": MessageLookupByLibrary.simpleMessage("Albanian"),
    "nationality_algeria": MessageLookupByLibrary.simpleMessage("Algerian"),
    "nationality_andorra": MessageLookupByLibrary.simpleMessage("Andorran"),
    "nationality_angola": MessageLookupByLibrary.simpleMessage("Angolan"),
    "nationality_argentina": MessageLookupByLibrary.simpleMessage("Argentine"),
    "nationality_armenia": MessageLookupByLibrary.simpleMessage("Armenian"),
    "nationality_australia": MessageLookupByLibrary.simpleMessage("Australian"),
    "nationality_austria": MessageLookupByLibrary.simpleMessage("Austrian"),
    "nationality_azerbaijan": MessageLookupByLibrary.simpleMessage(
      "Azerbaijani",
    ),
    "nationality_bahrain": MessageLookupByLibrary.simpleMessage("Bahraini"),
    "nationality_bangladesh": MessageLookupByLibrary.simpleMessage(
      "Bangladeshi",
    ),
    "nationality_belarus": MessageLookupByLibrary.simpleMessage("Belarusian"),
    "nationality_belgium": MessageLookupByLibrary.simpleMessage("Belgian"),
    "nationality_benin": MessageLookupByLibrary.simpleMessage("Beninese"),
    "nationality_bolivia": MessageLookupByLibrary.simpleMessage("Bolivian"),
    "nationality_bosnia_and_herzegovina": MessageLookupByLibrary.simpleMessage(
      "Bosnian",
    ),
    "nationality_botswana": MessageLookupByLibrary.simpleMessage("Botswanan"),
    "nationality_brazil": MessageLookupByLibrary.simpleMessage("Brazilian"),
    "nationality_bulgaria": MessageLookupByLibrary.simpleMessage("Bulgarian"),
    "nationality_burkina_faso": MessageLookupByLibrary.simpleMessage(
      "Burkinabé",
    ),
    "nationality_cambodia": MessageLookupByLibrary.simpleMessage("Cambodian"),
    "nationality_cameroon": MessageLookupByLibrary.simpleMessage("Cameroonian"),
    "nationality_canada": MessageLookupByLibrary.simpleMessage("Canadian"),
    "nationality_cape_verde": MessageLookupByLibrary.simpleMessage(
      "Cape Verdean",
    ),
    "nationality_central_african_republic":
        MessageLookupByLibrary.simpleMessage("Central African"),
    "nationality_chad": MessageLookupByLibrary.simpleMessage("Chadian"),
    "nationality_chile": MessageLookupByLibrary.simpleMessage("Chilean"),
    "nationality_china": MessageLookupByLibrary.simpleMessage("Chinese"),
    "nationality_colombia": MessageLookupByLibrary.simpleMessage("Colombian"),
    "nationality_comoros": MessageLookupByLibrary.simpleMessage("Comorian"),
    "nationality_congo": MessageLookupByLibrary.simpleMessage("Congolese"),
    "nationality_cote_d_ivoire": MessageLookupByLibrary.simpleMessage(
      "Ivorian",
    ),
    "nationality_croatia": MessageLookupByLibrary.simpleMessage("Croatian"),
    "nationality_cyprus": MessageLookupByLibrary.simpleMessage("Cypriot"),
    "nationality_czech_republic": MessageLookupByLibrary.simpleMessage("Czech"),
    "nationality_democratic_republic_of_the_congo":
        MessageLookupByLibrary.simpleMessage("Congolese"),
    "nationality_denmark": MessageLookupByLibrary.simpleMessage("Danish"),
    "nationality_djibouti": MessageLookupByLibrary.simpleMessage("Djiboutian"),
    "nationality_ecuador": MessageLookupByLibrary.simpleMessage("Ecuadorian"),
    "nationality_egypt": MessageLookupByLibrary.simpleMessage("Egyptian"),
    "nationality_equatorial_guinea": MessageLookupByLibrary.simpleMessage(
      "Equatorial Guinean",
    ),
    "nationality_eritrea": MessageLookupByLibrary.simpleMessage("Eritrean"),
    "nationality_estonia": MessageLookupByLibrary.simpleMessage("Estonian"),
    "nationality_eswatini": MessageLookupByLibrary.simpleMessage("Swazi"),
    "nationality_ethiopia": MessageLookupByLibrary.simpleMessage("Ethiopian"),
    "nationality_fiji": MessageLookupByLibrary.simpleMessage("Fijian"),
    "nationality_finland": MessageLookupByLibrary.simpleMessage("Finnish"),
    "nationality_france": MessageLookupByLibrary.simpleMessage("French"),
    "nationality_french_guiana": MessageLookupByLibrary.simpleMessage(
      "French Guianese",
    ),
    "nationality_french_polynesia": MessageLookupByLibrary.simpleMessage(
      "French Polynesian",
    ),
    "nationality_gabon": MessageLookupByLibrary.simpleMessage("Gabonese"),
    "nationality_gambia": MessageLookupByLibrary.simpleMessage("Gambian"),
    "nationality_georgia": MessageLookupByLibrary.simpleMessage("Georgian"),
    "nationality_germany": MessageLookupByLibrary.simpleMessage("German"),
    "nationality_ghana": MessageLookupByLibrary.simpleMessage("Ghanaian"),
    "nationality_greece": MessageLookupByLibrary.simpleMessage("Greek"),
    "nationality_guinea": MessageLookupByLibrary.simpleMessage("Guinean"),
    "nationality_guinea_bissau": MessageLookupByLibrary.simpleMessage(
      "Bissau-Guinean",
    ),
    "nationality_guyana": MessageLookupByLibrary.simpleMessage("Guyanese"),
    "nationality_hong_kong": MessageLookupByLibrary.simpleMessage(
      "Hong Konger",
    ),
    "nationality_hungary": MessageLookupByLibrary.simpleMessage("Hungarian"),
    "nationality_iceland": MessageLookupByLibrary.simpleMessage("Icelandic"),
    "nationality_india": MessageLookupByLibrary.simpleMessage("Indian"),
    "nationality_indonesia": MessageLookupByLibrary.simpleMessage("Indonesian"),
    "nationality_iran": MessageLookupByLibrary.simpleMessage("Iranian"),
    "nationality_iraq": MessageLookupByLibrary.simpleMessage("Iraqi"),
    "nationality_ireland": MessageLookupByLibrary.simpleMessage("Irish"),
    "nationality_italy": MessageLookupByLibrary.simpleMessage("Italian"),
    "nationality_japan": MessageLookupByLibrary.simpleMessage("Japanese"),
    "nationality_jordan": MessageLookupByLibrary.simpleMessage("Jordanian"),
    "nationality_kazakhstan": MessageLookupByLibrary.simpleMessage("Kazakh"),
    "nationality_kenya": MessageLookupByLibrary.simpleMessage("Kenyan"),
    "nationality_kiribati": MessageLookupByLibrary.simpleMessage("I-Kiribati"),
    "nationality_kuwait": MessageLookupByLibrary.simpleMessage("Kuwaiti"),
    "nationality_kyrgyzstan": MessageLookupByLibrary.simpleMessage("Kyrgyz"),
    "nationality_laos": MessageLookupByLibrary.simpleMessage("Lao"),
    "nationality_latvia": MessageLookupByLibrary.simpleMessage("Latvian"),
    "nationality_lebanon": MessageLookupByLibrary.simpleMessage("Lebanese"),
    "nationality_lesotho": MessageLookupByLibrary.simpleMessage("Basotho"),
    "nationality_liberia": MessageLookupByLibrary.simpleMessage("Liberian"),
    "nationality_libya": MessageLookupByLibrary.simpleMessage("Libyan"),
    "nationality_liechtenstein": MessageLookupByLibrary.simpleMessage(
      "Liechtensteiner",
    ),
    "nationality_lithuania": MessageLookupByLibrary.simpleMessage("Lithuanian"),
    "nationality_luxembourg": MessageLookupByLibrary.simpleMessage(
      "Luxembourgish",
    ),
    "nationality_macau": MessageLookupByLibrary.simpleMessage("Macanese"),
    "nationality_madagascar": MessageLookupByLibrary.simpleMessage("Malagasy"),
    "nationality_malawi": MessageLookupByLibrary.simpleMessage("Malawian"),
    "nationality_malaysia": MessageLookupByLibrary.simpleMessage("Malaysian"),
    "nationality_mali": MessageLookupByLibrary.simpleMessage("Malian"),
    "nationality_malta": MessageLookupByLibrary.simpleMessage("Maltese"),
    "nationality_marshall_islands": MessageLookupByLibrary.simpleMessage(
      "Marshallese",
    ),
    "nationality_mauritania": MessageLookupByLibrary.simpleMessage(
      "Mauritanian",
    ),
    "nationality_mauritius": MessageLookupByLibrary.simpleMessage("Mauritian"),
    "nationality_mexico": MessageLookupByLibrary.simpleMessage("Mexican"),
    "nationality_micronesia": MessageLookupByLibrary.simpleMessage(
      "Micronesian",
    ),
    "nationality_moldova": MessageLookupByLibrary.simpleMessage("Moldovan"),
    "nationality_monaco": MessageLookupByLibrary.simpleMessage("Monégasque"),
    "nationality_mongolia": MessageLookupByLibrary.simpleMessage("Mongolian"),
    "nationality_montenegro": MessageLookupByLibrary.simpleMessage(
      "Montenegrin",
    ),
    "nationality_morocco": MessageLookupByLibrary.simpleMessage("Moroccan"),
    "nationality_mozambique": MessageLookupByLibrary.simpleMessage(
      "Mozambican",
    ),
    "nationality_myanmar": MessageLookupByLibrary.simpleMessage("Burmese"),
    "nationality_namibia": MessageLookupByLibrary.simpleMessage("Namibian"),
    "nationality_nauru": MessageLookupByLibrary.simpleMessage("Nauruan"),
    "nationality_nepal": MessageLookupByLibrary.simpleMessage("Nepali"),
    "nationality_netherlands": MessageLookupByLibrary.simpleMessage("Dutch"),
    "nationality_new_caledonia": MessageLookupByLibrary.simpleMessage(
      "New Caledonian",
    ),
    "nationality_new_zealand": MessageLookupByLibrary.simpleMessage(
      "New Zealander",
    ),
    "nationality_niger": MessageLookupByLibrary.simpleMessage("Nigerien"),
    "nationality_nigeria": MessageLookupByLibrary.simpleMessage("Nigerian"),
    "nationality_north_korea": MessageLookupByLibrary.simpleMessage(
      "North Korean",
    ),
    "nationality_north_macedonia": MessageLookupByLibrary.simpleMessage(
      "Macedonian",
    ),
    "nationality_norway": MessageLookupByLibrary.simpleMessage("Norwegian"),
    "nationality_oman": MessageLookupByLibrary.simpleMessage("Omani"),
    "nationality_pakistan": MessageLookupByLibrary.simpleMessage("Pakistani"),
    "nationality_palau": MessageLookupByLibrary.simpleMessage("Palauan"),
    "nationality_palestine": MessageLookupByLibrary.simpleMessage(
      "Palestinian",
    ),
    "nationality_papua_new_guinea": MessageLookupByLibrary.simpleMessage(
      "Papua New Guinean",
    ),
    "nationality_paraguay": MessageLookupByLibrary.simpleMessage("Paraguayan"),
    "nationality_peru": MessageLookupByLibrary.simpleMessage("Peruvian"),
    "nationality_philippines": MessageLookupByLibrary.simpleMessage("Filipino"),
    "nationality_poland": MessageLookupByLibrary.simpleMessage("Polish"),
    "nationality_portugal": MessageLookupByLibrary.simpleMessage("Portuguese"),
    "nationality_qatar": MessageLookupByLibrary.simpleMessage("Qatari"),
    "nationality_romania": MessageLookupByLibrary.simpleMessage("Romanian"),
    "nationality_russia": MessageLookupByLibrary.simpleMessage("Russian"),
    "nationality_samoa": MessageLookupByLibrary.simpleMessage("Samoan"),
    "nationality_san_marino": MessageLookupByLibrary.simpleMessage(
      "Sammarinese",
    ),
    "nationality_sao_tome_and_principe": MessageLookupByLibrary.simpleMessage(
      "São Toméan",
    ),
    "nationality_saudi_arabia": MessageLookupByLibrary.simpleMessage("Saudi"),
    "nationality_senegal": MessageLookupByLibrary.simpleMessage("Senegalese"),
    "nationality_serbia": MessageLookupByLibrary.simpleMessage("Serbian"),
    "nationality_seychelles": MessageLookupByLibrary.simpleMessage(
      "Seychellois",
    ),
    "nationality_sierra_leone": MessageLookupByLibrary.simpleMessage(
      "Sierra Leonean",
    ),
    "nationality_singapore": MessageLookupByLibrary.simpleMessage(
      "Singaporean",
    ),
    "nationality_slovakia": MessageLookupByLibrary.simpleMessage("Slovak"),
    "nationality_slovenia": MessageLookupByLibrary.simpleMessage("Slovenian"),
    "nationality_solomon_islands": MessageLookupByLibrary.simpleMessage(
      "Solomon Islander",
    ),
    "nationality_somalia": MessageLookupByLibrary.simpleMessage("Somali"),
    "nationality_south_africa": MessageLookupByLibrary.simpleMessage(
      "South African",
    ),
    "nationality_south_korea": MessageLookupByLibrary.simpleMessage(
      "South Korean",
    ),
    "nationality_spain": MessageLookupByLibrary.simpleMessage("Spanish"),
    "nationality_sri_lanka": MessageLookupByLibrary.simpleMessage("Sri Lankan"),
    "nationality_sudan": MessageLookupByLibrary.simpleMessage("Sudanese"),
    "nationality_suriname": MessageLookupByLibrary.simpleMessage("Surinamese"),
    "nationality_sweden": MessageLookupByLibrary.simpleMessage("Swedish"),
    "nationality_switzerland": MessageLookupByLibrary.simpleMessage("Swiss"),
    "nationality_syria": MessageLookupByLibrary.simpleMessage("Syrian"),
    "nationality_taiwan": MessageLookupByLibrary.simpleMessage("Taiwanese"),
    "nationality_tajikistan": MessageLookupByLibrary.simpleMessage("Tajik"),
    "nationality_tanzania": MessageLookupByLibrary.simpleMessage("Tanzanian"),
    "nationality_thailand": MessageLookupByLibrary.simpleMessage("Thai"),
    "nationality_togo": MessageLookupByLibrary.simpleMessage("Togolese"),
    "nationality_tonga": MessageLookupByLibrary.simpleMessage("Tongan"),
    "nationality_tunisia": MessageLookupByLibrary.simpleMessage("Tunisian"),
    "nationality_turkey": MessageLookupByLibrary.simpleMessage("Turkish"),
    "nationality_turkmenistan": MessageLookupByLibrary.simpleMessage("Turkmen"),
    "nationality_tuvalu": MessageLookupByLibrary.simpleMessage("Tuvaluan"),
    "nationality_uganda": MessageLookupByLibrary.simpleMessage("Ugandan"),
    "nationality_ukraine": MessageLookupByLibrary.simpleMessage("Ukrainian"),
    "nationality_united_arab_emirates": MessageLookupByLibrary.simpleMessage(
      "Emirati",
    ),
    "nationality_united_kingdom": MessageLookupByLibrary.simpleMessage(
      "British",
    ),
    "nationality_united_states": MessageLookupByLibrary.simpleMessage(
      "American",
    ),
    "nationality_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "nationality_uruguay": MessageLookupByLibrary.simpleMessage("Uruguayan"),
    "nationality_uzbekistan": MessageLookupByLibrary.simpleMessage("Uzbek"),
    "nationality_vanuatu": MessageLookupByLibrary.simpleMessage("Ni-Vanuatu"),
    "nationality_vatican_city": MessageLookupByLibrary.simpleMessage("Vatican"),
    "nationality_venezuela": MessageLookupByLibrary.simpleMessage("Venezuelan"),
    "nationality_vietnam": MessageLookupByLibrary.simpleMessage("Vietnamese"),
    "nationality_western_sahara": MessageLookupByLibrary.simpleMessage(
      "Sahrawi",
    ),
    "nationality_yemen": MessageLookupByLibrary.simpleMessage("Yemeni"),
    "nationality_zambia": MessageLookupByLibrary.simpleMessage("Zambian"),
    "nationality_zimbabwe": MessageLookupByLibrary.simpleMessage("Zimbabwean"),
    "nav_back_to_home": MessageLookupByLibrary.simpleMessage("Back to home"),
    "nav_breadcrumbs": MessageLookupByLibrary.simpleMessage("Breadcrumbs"),
    "nav_breadcrumbs_hidden": m147,
    "nav_copy_url": MessageLookupByLibrary.simpleMessage("Copy URL"),
    "nav_exit_confirm": MessageLookupByLibrary.simpleMessage(
      "Swipe again to exit",
    ),
    "nav_go_back": MessageLookupByLibrary.simpleMessage("Go back"),
    "nav_go_home": MessageLookupByLibrary.simpleMessage("Go Home"),
    "nav_page_not_found": MessageLookupByLibrary.simpleMessage(
      "Page not found",
    ),
    "nav_page_not_found_body": MessageLookupByLibrary.simpleMessage(
      "The page you\'re looking for doesn\'t exist or has moved.",
    ),
    "nav_path_copied": MessageLookupByLibrary.simpleMessage(
      "Path copied — done",
    ),
    "nav_tab_gallery": MessageLookupByLibrary.simpleMessage("Gallery"),
    "nav_tab_position": m148,
    "nav_tab_profile": MessageLookupByLibrary.simpleMessage("Profile"),
    "nav_tab_shop": MessageLookupByLibrary.simpleMessage("Shop"),
    "nav_tab_workshops": MessageLookupByLibrary.simpleMessage("Workshops"),
    "notifications_channel_general_description":
        MessageLookupByLibrary.simpleMessage("Miscellaneous notifications."),
    "notifications_channel_general_name": MessageLookupByLibrary.simpleMessage(
      "General",
    ),
    "notifications_channel_messages_description":
        MessageLookupByLibrary.simpleMessage(
          "Direct messages, mentions, chat notifications.",
        ),
    "notifications_channel_messages_name": MessageLookupByLibrary.simpleMessage(
      "Messages",
    ),
    "notifications_channel_promo_description":
        MessageLookupByLibrary.simpleMessage(
          "Marketing, promotions, and special offers.",
        ),
    "notifications_channel_promo_name": MessageLookupByLibrary.simpleMessage(
      "Promotions",
    ),
    "notifications_channel_system_description":
        MessageLookupByLibrary.simpleMessage(
          "App updates, security alerts, critical messages.",
        ),
    "notifications_channel_system_name": MessageLookupByLibrary.simpleMessage(
      "System & Security",
    ),
    "notifications_channel_transactional_description":
        MessageLookupByLibrary.simpleMessage(
          "Order updates, receipts, delivery notifications.",
        ),
    "notifications_channel_transactional_name":
        MessageLookupByLibrary.simpleMessage("Orders & Transactions"),
    "notifications_count": m149,
    "onboarding_allow": MessageLookupByLibrary.simpleMessage("Allow"),
    "onboarding_back": MessageLookupByLibrary.simpleMessage("Back"),
    "onboarding_get_started": MessageLookupByLibrary.simpleMessage(
      "Let\'s start",
    ),
    "onboarding_make_body": MessageLookupByLibrary.simpleMessage(
      "Pick a workshop, sit with the instructor, and shape or paint a clay piece that is yours.",
    ),
    "onboarding_make_title": MessageLookupByLibrary.simpleMessage(
      "Make your piece by hand",
    ),
    "onboarding_next": MessageLookupByLibrary.simpleMessage("Next"),
    "onboarding_not_now": MessageLookupByLibrary.simpleMessage("Not now"),
    "onboarding_permission_denied_hint": MessageLookupByLibrary.simpleMessage(
      "You can change this later in Settings.",
    ),
    "onboarding_skip": MessageLookupByLibrary.simpleMessage("Skip"),
    "onboarding_track_body": MessageLookupByLibrary.simpleMessage(
      "From the kiln, to ready, to your front door — a notification reaches you at every change.",
    ),
    "onboarding_track_title": MessageLookupByLibrary.simpleMessage(
      "Follow your order, step by step",
    ),
    "onboarding_workshop_body": MessageLookupByLibrary.simpleMessage(
      "Hands-on sessions led by instructors. Shape or paint your piece, step by step, inside the studio.",
    ),
    "onboarding_workshop_title": MessageLookupByLibrary.simpleMessage(
      "The workshop experience",
    ),
    "order_cancel": MessageLookupByLibrary.simpleMessage("Cancel order"),
    "order_cancel_body": MessageLookupByLibrary.simpleMessage(
      "Anything already paid comes back as Terracotta balance, not to your card. This cannot be undone.",
    ),
    "order_cancel_no": MessageLookupByLibrary.simpleMessage("Keep it"),
    "order_cancel_refunded": m150,
    "order_cancel_title": MessageLookupByLibrary.simpleMessage(
      "Cancel this order?",
    ),
    "order_cancel_yes": MessageLookupByLibrary.simpleMessage("Yes, cancel it"),
    "order_cancelled_on": m151,
    "order_confirmed_body": MessageLookupByLibrary.simpleMessage(
      "We are preparing it now. You can follow it from your orders at any time.",
    ),
    "order_confirmed_title": MessageLookupByLibrary.simpleMessage(
      "Your order is placed!",
    ),
    "order_delivery_heading": MessageLookupByLibrary.simpleMessage("Delivery"),
    "order_delivery_notes": MessageLookupByLibrary.simpleMessage(
      "Note for the courier",
    ),
    "order_delivery_to": MessageLookupByLibrary.simpleMessage("Delivering to"),
    "order_items_count": m152,
    "order_items_heading": MessageLookupByLibrary.simpleMessage(
      "What you ordered",
    ),
    "order_not_found": MessageLookupByLibrary.simpleMessage(
      "This order could not be opened",
    ),
    "order_number": m153,
    "order_pay_before": m154,
    "order_pay_now": MessageLookupByLibrary.simpleMessage("Pay now"),
    "order_placed_on": m155,
    "order_quantity": m156,
    "order_settled": MessageLookupByLibrary.simpleMessage("Paid in full"),
    "order_short_address": MessageLookupByLibrary.simpleMessage(
      "Short address",
    ),
    "order_status_awaiting_payment": MessageLookupByLibrary.simpleMessage(
      "Awaiting payment",
    ),
    "order_status_cancelled": MessageLookupByLibrary.simpleMessage("Cancelled"),
    "order_status_completed": MessageLookupByLibrary.simpleMessage("Delivered"),
    "order_status_out_for_delivery": MessageLookupByLibrary.simpleMessage(
      "On the way",
    ),
    "order_status_pending": MessageLookupByLibrary.simpleMessage("Confirmed"),
    "order_status_preparing": MessageLookupByLibrary.simpleMessage(
      "Being packed",
    ),
    "order_status_unknown": MessageLookupByLibrary.simpleMessage(
      "Being processed",
    ),
    "order_track": MessageLookupByLibrary.simpleMessage("Track order"),
    "otp_field_must_be_n_chars": m157,
    "otp_form_no_code": MessageLookupByLibrary.simpleMessage(
      "Didn\'t receive the code?",
    ),
    "otp_form_resend": MessageLookupByLibrary.simpleMessage("Resend"),
    "otp_form_resend_in": m158,
    "otp_form_sent_to": m159,
    "page_about": MessageLookupByLibrary.simpleMessage("About Terracotta"),
    "page_missing": MessageLookupByLibrary.simpleMessage("Nothing here yet"),
    "page_missing_body": MessageLookupByLibrary.simpleMessage(
      "The studio has not written this page.",
    ),
    "page_privacy": MessageLookupByLibrary.simpleMessage("Privacy policy"),
    "page_returns": MessageLookupByLibrary.simpleMessage(
      "Returns and exchanges",
    ),
    "page_section_title": MessageLookupByLibrary.simpleMessage("Terracotta"),
    "page_shipping": MessageLookupByLibrary.simpleMessage(
      "Shipping and delivery",
    ),
    "page_terms": MessageLookupByLibrary.simpleMessage("Terms and conditions"),
    "pdf_bookmark_count": m160,
    "pdf_bookmark_list_hint": MessageLookupByLibrary.simpleMessage(
      "long-press for list",
    ),
    "pdf_bookmark_page": MessageLookupByLibrary.simpleMessage("Bookmark page"),
    "pdf_bookmarks": MessageLookupByLibrary.simpleMessage("Bookmarks"),
    "pdf_downloading_percent": m161,
    "pdf_encrypted_detail": MessageLookupByLibrary.simpleMessage(
      "The document is encrypted. Provide a password to continue.",
    ),
    "pdf_forget": MessageLookupByLibrary.simpleMessage("Forget this document"),
    "pdf_go": MessageLookupByLibrary.simpleMessage("Go"),
    "pdf_jump_to_page": MessageLookupByLibrary.simpleMessage("Jump to page"),
    "pdf_load_failed": MessageLookupByLibrary.simpleMessage(
      "Failed to load PDF",
    ),
    "pdf_load_failed_detail": MessageLookupByLibrary.simpleMessage(
      "Check the source URL or your connection.",
    ),
    "pdf_match_of": m162,
    "pdf_next_match": MessageLookupByLibrary.simpleMessage("Next match"),
    "pdf_next_page": MessageLookupByLibrary.simpleMessage("Next page"),
    "pdf_no_bookmarks": MessageLookupByLibrary.simpleMessage(
      "No bookmarks yet for this document",
    ),
    "pdf_no_matches": MessageLookupByLibrary.simpleMessage("No matches"),
    "pdf_no_outline": MessageLookupByLibrary.simpleMessage(
      "No outline / TOC in this PDF",
    ),
    "pdf_no_recent_documents": MessageLookupByLibrary.simpleMessage(
      "No documents opened yet",
    ),
    "pdf_not_found": MessageLookupByLibrary.simpleMessage("PDF not found"),
    "pdf_not_found_detail": MessageLookupByLibrary.simpleMessage(
      "The file at this URL returned 404.",
    ),
    "pdf_open_document": m163,
    "pdf_outline": MessageLookupByLibrary.simpleMessage("Outline"),
    "pdf_page_count": m164,
    "pdf_page_count_short": m165,
    "pdf_page_number": m166,
    "pdf_page_of": m167,
    "pdf_password_required": MessageLookupByLibrary.simpleMessage(
      "Password required",
    ),
    "pdf_previous_match": MessageLookupByLibrary.simpleMessage(
      "Previous match",
    ),
    "pdf_previous_page": MessageLookupByLibrary.simpleMessage("Previous page"),
    "pdf_print": MessageLookupByLibrary.simpleMessage("Print"),
    "pdf_remove_bookmark": MessageLookupByLibrary.simpleMessage(
      "Remove bookmark",
    ),
    "pdf_reset_zoom": MessageLookupByLibrary.simpleMessage("Reset zoom"),
    "pdf_resumed_at_page": m168,
    "pdf_rotate_90": MessageLookupByLibrary.simpleMessage("Rotate 90°"),
    "pdf_save_as": MessageLookupByLibrary.simpleMessage("Save as…"),
    "pdf_save_dialog_title": MessageLookupByLibrary.simpleMessage("Save PDF"),
    "pdf_searching": MessageLookupByLibrary.simpleMessage("Searching"),
    "pdf_start_over": MessageLookupByLibrary.simpleMessage("Start over"),
    "pdf_unlock": MessageLookupByLibrary.simpleMessage("Unlock"),
    "pdf_zoom_in": MessageLookupByLibrary.simpleMessage("Zoom in"),
    "pdf_zoom_out": MessageLookupByLibrary.simpleMessage("Zoom out"),
    "percent_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter percentage",
    ),
    "percent_field_max": m169,
    "percent_field_min": m170,
    "percent_field_range": m171,
    "percent_field_required": MessageLookupByLibrary.simpleMessage(
      "Percentage is required",
    ),
    "phone_field_all_countries": MessageLookupByLibrary.simpleMessage(
      "All countries",
    ),
    "phone_field_length_exact": m172,
    "phone_field_length_range": m173,
    "phone_field_mobile_length_exact": m174,
    "phone_field_mobile_length_range": m175,
    "phone_field_mobile_prefix": m176,
    "phone_field_preferred_countries": MessageLookupByLibrary.simpleMessage(
      "Preferred",
    ),
    "pieces_available": MessageLookupByLibrary.simpleMessage("Ready to paint"),
    "pieces_empty": MessageLookupByLibrary.simpleMessage("Nothing made yet"),
    "pieces_empty_body": MessageLookupByLibrary.simpleMessage(
      "Pieces you make at the studio are kept here, ready to be painted.",
    ),
    "pieces_made_on": m177,
    "pieces_no_source": MessageLookupByLibrary.simpleMessage(
      "Not available right now",
    ),
    "pieces_no_source_body": MessageLookupByLibrary.simpleMessage(
      "The studio is not taking pieces back at the moment. Yours are safe.",
    ),
    "pieces_paint_price": m178,
    "pieces_painted": MessageLookupByLibrary.simpleMessage("Painted"),
    "pieces_title": MessageLookupByLibrary.simpleMessage("My pieces"),
    "pieces_untitled": MessageLookupByLibrary.simpleMessage("Untitled piece"),
    "plate_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter plate number",
    ),
    "plate_field_invalid": MessageLookupByLibrary.simpleMessage(
      "Invalid plate number",
    ),
    "plate_field_required": MessageLookupByLibrary.simpleMessage(
      "Plate number is required",
    ),
    "popup_closed_semantic": MessageLookupByLibrary.simpleMessage(
      "Popup closed",
    ),
    "popup_opened_semantic": MessageLookupByLibrary.simpleMessage(
      "Popup opened",
    ),
    "preferences_app_role_subtitle": MessageLookupByLibrary.simpleMessage(
      "Which palette the app wears",
    ),
    "preferences_app_role_title": MessageLookupByLibrary.simpleMessage(
      "Color theme",
    ),
    "preferences_color_saturation_subtitle":
        MessageLookupByLibrary.simpleMessage("How vivid the palette renders"),
    "preferences_color_saturation_title": MessageLookupByLibrary.simpleMessage(
      "Color saturation",
    ),
    "preferences_dynamic_color_subtitle": MessageLookupByLibrary.simpleMessage(
      "Use system accent color (Android 12+).",
    ),
    "preferences_dynamic_color_title": MessageLookupByLibrary.simpleMessage(
      "Dynamic color",
    ),
    "preferences_font_preview_sample": MessageLookupByLibrary.simpleMessage(
      "The quick brown fox jumps over the lazy dog.",
    ),
    "preferences_font_scale_default": MessageLookupByLibrary.simpleMessage(
      "Default",
    ),
    "preferences_font_scale_extra_large": MessageLookupByLibrary.simpleMessage(
      "Extra large",
    ),
    "preferences_font_scale_huge": MessageLookupByLibrary.simpleMessage("Huge"),
    "preferences_font_scale_large": MessageLookupByLibrary.simpleMessage(
      "Large",
    ),
    "preferences_font_scale_small": MessageLookupByLibrary.simpleMessage(
      "Small",
    ),
    "preferences_font_size_subtitle": MessageLookupByLibrary.simpleMessage(
      "Composes with system text scaling",
    ),
    "preferences_font_size_title": MessageLookupByLibrary.simpleMessage(
      "Font size",
    ),
    "preferences_language_subtitle": MessageLookupByLibrary.simpleMessage(
      "App display language",
    ),
    "preferences_language_title": MessageLookupByLibrary.simpleMessage(
      "Language",
    ),
    "preferences_reset_action": MessageLookupByLibrary.simpleMessage("Reset"),
    "preferences_reset_confirm_body": MessageLookupByLibrary.simpleMessage(
      "Theme, saturation, font size, dynamic color, and reveal animation revert to defaults. Language and onboarding state are untouched.",
    ),
    "preferences_reset_confirm_title": MessageLookupByLibrary.simpleMessage(
      "Reset display preferences?",
    ),
    "preferences_reset_to_defaults": MessageLookupByLibrary.simpleMessage(
      "Reset to defaults",
    ),
    "preferences_reveal_direction_subtitle":
        MessageLookupByLibrary.simpleMessage("Which way that shape moves"),
    "preferences_reveal_direction_title": MessageLookupByLibrary.simpleMessage(
      "Animation direction",
    ),
    "preferences_reveal_shape_subtitle": MessageLookupByLibrary.simpleMessage(
      "The shape the reveal takes when the theme changes",
    ),
    "preferences_reveal_shape_title": MessageLookupByLibrary.simpleMessage(
      "Switch animation",
    ),
    "preferences_saturation_muted": MessageLookupByLibrary.simpleMessage(
      "Muted",
    ),
    "preferences_saturation_normal": MessageLookupByLibrary.simpleMessage(
      "Normal",
    ),
    "preferences_saturation_vibrant": MessageLookupByLibrary.simpleMessage(
      "Vibrant",
    ),
    "preferences_theme_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "preferences_theme_light": MessageLookupByLibrary.simpleMessage("Light"),
    "preferences_theme_subtitle": MessageLookupByLibrary.simpleMessage(
      "Light · Dark · Match system",
    ),
    "preferences_theme_system": MessageLookupByLibrary.simpleMessage("System"),
    "preferences_theme_title": MessageLookupByLibrary.simpleMessage("Theme"),
    "profile_add_address": MessageLookupByLibrary.simpleMessage(
      "Add an address",
    ),
    "profile_addresses": MessageLookupByLibrary.simpleMessage("My addresses"),
    "profile_cancel_order": MessageLookupByLibrary.simpleMessage(
      "Cancel order",
    ),
    "profile_change_password": MessageLookupByLibrary.simpleMessage(
      "Change password",
    ),
    "profile_change_password_message": MessageLookupByLibrary.simpleMessage(
      "You will stay signed in on this device.",
    ),
    "profile_contact_body": MessageLookupByLibrary.simpleMessage(
      "Reach the studio directly, or follow along.",
    ),
    "profile_contact_empty": MessageLookupByLibrary.simpleMessage(
      "The studio has not published a way to reach it yet.",
    ),
    "profile_contact_social": MessageLookupByLibrary.simpleMessage(
      "Follow the studio",
    ),
    "profile_contact_us": MessageLookupByLibrary.simpleMessage("Contact us"),
    "profile_current_password": MessageLookupByLibrary.simpleMessage(
      "Current password",
    ),
    "profile_current_password_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your current password",
    ),
    "profile_default": MessageLookupByLibrary.simpleMessage("Default"),
    "profile_delete_account": MessageLookupByLibrary.simpleMessage(
      "Delete account",
    ),
    "profile_delete_confirm": MessageLookupByLibrary.simpleMessage(
      "Delete permanently",
    ),
    "profile_delete_message": MessageLookupByLibrary.simpleMessage(
      "Your bookings, orders and Terracotta balance go with it. This happens straight away and cannot be undone.",
    ),
    "profile_delete_warning": MessageLookupByLibrary.simpleMessage(
      "This permanently deletes your account. It cannot be undone.",
    ),
    "profile_devices": MessageLookupByLibrary.simpleMessage("Devices"),
    "profile_edit": MessageLookupByLibrary.simpleMessage("Edit profile"),
    "profile_edit_name": MessageLookupByLibrary.simpleMessage("Edit name"),
    "profile_guest": MessageLookupByLibrary.simpleMessage("Guest"),
    "profile_guest_hint": MessageLookupByLibrary.simpleMessage(
      "Sign in to keep your cart, bookings and balance.",
    ),
    "profile_logout": MessageLookupByLibrary.simpleMessage("Sign out"),
    "profile_mark_all_read": MessageLookupByLibrary.simpleMessage(
      "Mark all read",
    ),
    "profile_name_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your name",
    ),
    "profile_name_label": MessageLookupByLibrary.simpleMessage("Your name"),
    "profile_name_updated": MessageLookupByLibrary.simpleMessage(
      "Your name has been updated.",
    ),
    "profile_no_addresses": MessageLookupByLibrary.simpleMessage(
      "No saved addresses",
    ),
    "profile_no_devices": MessageLookupByLibrary.simpleMessage(
      "No other devices",
    ),
    "profile_no_notifications": MessageLookupByLibrary.simpleMessage(
      "No notifications",
    ),
    "profile_no_transactions": MessageLookupByLibrary.simpleMessage(
      "No transactions yet",
    ),
    "profile_notif_filter_all": MessageLookupByLibrary.simpleMessage("All"),
    "profile_notif_filter_bookings": MessageLookupByLibrary.simpleMessage(
      "Bookings",
    ),
    "profile_notif_filter_gifts": MessageLookupByLibrary.simpleMessage("Gifts"),
    "profile_notif_filter_orders": MessageLookupByLibrary.simpleMessage(
      "Orders",
    ),
    "profile_notif_filter_pieces": MessageLookupByLibrary.simpleMessage(
      "Pieces",
    ),
    "profile_notif_filter_reminders": MessageLookupByLibrary.simpleMessage(
      "Reminders",
    ),
    "profile_notif_filter_unread": MessageLookupByLibrary.simpleMessage(
      "Unread",
    ),
    "profile_notif_filter_wallet": MessageLookupByLibrary.simpleMessage(
      "Wallet",
    ),
    "profile_notif_none_in_filter": MessageLookupByLibrary.simpleMessage(
      "Nothing here right now",
    ),
    "profile_notif_signed_out": MessageLookupByLibrary.simpleMessage(
      "Sign in to see your notifications",
    ),
    "profile_notif_signed_out_body": MessageLookupByLibrary.simpleMessage(
      "Booking confirmations, order updates and studio news all land here.",
    ),
    "profile_notifications": MessageLookupByLibrary.simpleMessage(
      "Notifications",
    ),
    "profile_order_detail": MessageLookupByLibrary.simpleMessage(
      "Order details",
    ),
    "profile_orders": MessageLookupByLibrary.simpleMessage("My orders"),
    "profile_password_changed": MessageLookupByLibrary.simpleMessage(
      "Your password has been changed.",
    ),
    "profile_revoke": MessageLookupByLibrary.simpleMessage(
      "Sign out this device",
    ),
    "profile_set_default": MessageLookupByLibrary.simpleMessage(
      "Set as default",
    ),
    "profile_sign_out_message": MessageLookupByLibrary.simpleMessage(
      "You will need your phone number and password to get back in. Nothing in your cart or bookings is lost.",
    ),
    "profile_sign_out_title": MessageLookupByLibrary.simpleMessage("Sign out?"),
    "profile_this_device": MessageLookupByLibrary.simpleMessage("This device"),
    "profile_title": MessageLookupByLibrary.simpleMessage("My account"),
    "profile_wallet": MessageLookupByLibrary.simpleMessage("My wallet"),
    "promo_field_apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "promo_field_empty": MessageLookupByLibrary.simpleMessage(
      "Enter a code first",
    ),
    "promo_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter promo code",
    ),
    "promo_field_remove": MessageLookupByLibrary.simpleMessage("Remove code"),
    "radio_no": MessageLookupByLibrary.simpleMessage("No"),
    "radio_semantic_label": MessageLookupByLibrary.simpleMessage(
      "Radio option",
    ),
    "radio_yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "rating_semantic_label": MessageLookupByLibrary.simpleMessage("Rating"),
    "rating_value_out_of": m179,
    "recurrence_daily": MessageLookupByLibrary.simpleMessage("Daily"),
    "recurrence_monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "recurrence_none": MessageLookupByLibrary.simpleMessage("Does not repeat"),
    "recurrence_weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "recurrence_yearly": MessageLookupByLibrary.simpleMessage("Yearly"),
    "scan_already_in": m180,
    "scan_arrived": m181,
    "scan_back_to_today": MessageLookupByLibrary.simpleMessage("Back to today"),
    "scan_camera_denied": MessageLookupByLibrary.simpleMessage(
      "The camera is not available. Type the code instead.",
    ),
    "scan_check_in_closed_body": MessageLookupByLibrary.simpleMessage(
      "This session has been finished, so nobody else can be checked in to it.",
    ),
    "scan_checked_in": m182,
    "scan_code_hint": MessageLookupByLibrary.simpleMessage("8 digits"),
    "scan_confirm_count": MessageLookupByLibrary.simpleMessage("Check in"),
    "scan_desk_title": MessageLookupByLibrary.simpleMessage("Front desk"),
    "scan_enter_code": MessageLookupByLibrary.simpleMessage("Enter code"),
    "scan_finish_all_done": MessageLookupByLibrary.simpleMessage(
      "Everyone has photographed their pieces.",
    ),
    "scan_finish_anyway": MessageLookupByLibrary.simpleMessage("Finish anyway"),
    "scan_finish_missing_body": MessageLookupByLibrary.simpleMessage(
      "Once you finish, no photo can be added to these bookings. Find these customers first.",
    ),
    "scan_finish_missing_title": MessageLookupByLibrary.simpleMessage(
      "Some pieces have not been photographed",
    ),
    "scan_finish_session": MessageLookupByLibrary.simpleMessage(
      "Finish session",
    ),
    "scan_finish_warning_body": MessageLookupByLibrary.simpleMessage(
      "Everyone attending moves on to the next stage.",
    ),
    "scan_finish_warning_title": MessageLookupByLibrary.simpleMessage(
      "Finish the session?",
    ),
    "scan_how_many_body": m183,
    "scan_how_many_title": MessageLookupByLibrary.simpleMessage(
      "How many arrived?",
    ),
    "scan_missing_row": m184,
    "scan_next_day": MessageLookupByLibrary.simpleMessage("Next day"),
    "scan_no_sessions": MessageLookupByLibrary.simpleMessage(
      "No sessions booked today",
    ),
    "scan_no_sessions_body": MessageLookupByLibrary.simpleMessage(
      "Nobody has booked a workshop for this day yet.",
    ),
    "scan_no_sessions_body_day": MessageLookupByLibrary.simpleMessage(
      "Nobody has booked a workshop for that day yet.",
    ),
    "scan_no_sessions_day": MessageLookupByLibrary.simpleMessage(
      "No sessions booked that day",
    ),
    "scan_not_today": MessageLookupByLibrary.simpleMessage(
      "Sessions can only be started or finished on the day they run.",
    ),
    "scan_pieces_progress": m185,
    "scan_point_camera": MessageLookupByLibrary.simpleMessage(
      "Point the camera at the customer’s code",
    ),
    "scan_previous_day": MessageLookupByLibrary.simpleMessage("Previous day"),
    "scan_scan_code": MessageLookupByLibrary.simpleMessage("Scan a code"),
    "scan_seats": m186,
    "scan_session_closed": MessageLookupByLibrary.simpleMessage(
      "Check-in closed",
    ),
    "scan_session_closed_at": m187,
    "scan_session_finished": MessageLookupByLibrary.simpleMessage(
      "Session finished.",
    ),
    "scan_session_started": MessageLookupByLibrary.simpleMessage(
      "Session started.",
    ),
    "scan_sign_out": MessageLookupByLibrary.simpleMessage("Sign out"),
    "scan_start_session": MessageLookupByLibrary.simpleMessage("Start session"),
    "scan_start_warning_body": MessageLookupByLibrary.simpleMessage(
      "Everyone who has not been scanned in is marked absent. This cannot be undone, and a no-show is not refunded.",
    ),
    "scan_start_warning_title": MessageLookupByLibrary.simpleMessage(
      "Start the session?",
    ),
    "scan_today": MessageLookupByLibrary.simpleMessage("Today"),
    "scanner_allow_camera_hint": MessageLookupByLibrary.simpleMessage(
      "Allow camera access to scan codes.",
    ),
    "scanner_camera_access_blocked": MessageLookupByLibrary.simpleMessage(
      "Camera access blocked",
    ),
    "scanner_camera_failed": MessageLookupByLibrary.simpleMessage(
      "Camera unavailable",
    ),
    "scanner_camera_failed_hint": MessageLookupByLibrary.simpleMessage(
      "The camera could not be started.",
    ),
    "scanner_camera_permission_required": MessageLookupByLibrary.simpleMessage(
      "Camera permission required",
    ),
    "scanner_empty_value": MessageLookupByLibrary.simpleMessage("(no data)"),
    "scanner_flip_camera": MessageLookupByLibrary.simpleMessage(
      "Switch camera",
    ),
    "scanner_from_image": MessageLookupByLibrary.simpleMessage(
      "Scan from an image",
    ),
    "scanner_grant_access": MessageLookupByLibrary.simpleMessage(
      "Grant access",
    ),
    "scanner_hint": MessageLookupByLibrary.simpleMessage(
      "Point the camera at a code",
    ),
    "scanner_image_no_code": MessageLookupByLibrary.simpleMessage(
      "No code found in that image",
    ),
    "scanner_open_settings": MessageLookupByLibrary.simpleMessage(
      "Open settings",
    ),
    "scanner_open_settings_hint": MessageLookupByLibrary.simpleMessage(
      "Open Settings to allow camera access for this app.",
    ),
    "scanner_pending_code": MessageLookupByLibrary.simpleMessage(
      "Scanned code",
    ),
    "scanner_rejected": MessageLookupByLibrary.simpleMessage(
      "Not a code this screen accepts",
    ),
    "scanner_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "scanner_scan_again": MessageLookupByLibrary.simpleMessage("Scan again"),
    "scanner_title": MessageLookupByLibrary.simpleMessage("Scan code"),
    "scanner_torch_off": MessageLookupByLibrary.simpleMessage(
      "Turn off the light",
    ),
    "scanner_torch_on": MessageLookupByLibrary.simpleMessage(
      "Turn on the light",
    ),
    "scanner_use_this_code": MessageLookupByLibrary.simpleMessage(
      "Use this code",
    ),
    "scanner_zoom": MessageLookupByLibrary.simpleMessage("Zoom"),
    "scroll_new_items": m188,
    "scroll_progress": MessageLookupByLibrary.simpleMessage("Scroll progress"),
    "scroll_to_top": MessageLookupByLibrary.simpleMessage("Scroll to top"),
    "segmented_control_period_day": MessageLookupByLibrary.simpleMessage("Day"),
    "segmented_control_period_month": MessageLookupByLibrary.simpleMessage(
      "Month",
    ),
    "segmented_control_period_week": MessageLookupByLibrary.simpleMessage(
      "Week",
    ),
    "segmented_control_period_year": MessageLookupByLibrary.simpleMessage(
      "Year",
    ),
    "segmented_control_semantic_label": MessageLookupByLibrary.simpleMessage(
      "Segmented control",
    ),
    "segmented_control_status_active": MessageLookupByLibrary.simpleMessage(
      "Active",
    ),
    "segmented_control_status_all": MessageLookupByLibrary.simpleMessage("All"),
    "segmented_control_status_archived": MessageLookupByLibrary.simpleMessage(
      "Archived",
    ),
    "segmented_control_time_12h": MessageLookupByLibrary.simpleMessage("12h"),
    "segmented_control_time_24h": MessageLookupByLibrary.simpleMessage("24h"),
    "segmented_control_view_grid": MessageLookupByLibrary.simpleMessage("Grid"),
    "segmented_control_view_list": MessageLookupByLibrary.simpleMessage("List"),
    "segmented_control_view_map": MessageLookupByLibrary.simpleMessage("Map"),
    "settings_language": MessageLookupByLibrary.simpleMessage("Language"),
    "settings_notifications": MessageLookupByLibrary.simpleMessage(
      "Notifications",
    ),
    "settings_notifications_off": MessageLookupByLibrary.simpleMessage(
      "Off. Turn them on to hear about your bookings and orders.",
    ),
    "settings_notifications_on": MessageLookupByLibrary.simpleMessage(
      "On — you will hear about your bookings and orders.",
    ),
    "settings_notifications_open": MessageLookupByLibrary.simpleMessage(
      "Open notification settings",
    ),
    "settings_text_size": MessageLookupByLibrary.simpleMessage("Text size"),
    "settings_theme": MessageLookupByLibrary.simpleMessage("Appearance"),
    "settings_theme_note": MessageLookupByLibrary.simpleMessage(
      "The studio’s design is drawn light. Dark is built to match it.",
    ),
    "settings_version": m189,
    "sheet_apply": MessageLookupByLibrary.simpleMessage("Apply"),
    "sheet_confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "sheet_confirm_title": MessageLookupByLibrary.simpleMessage(
      "Are you sure?",
    ),
    "sheet_delete_message": MessageLookupByLibrary.simpleMessage(
      "This action cannot be undone.",
    ),
    "sheet_delete_title": MessageLookupByLibrary.simpleMessage(
      "Delete this item?",
    ),
    "sheet_discard_confirm": MessageLookupByLibrary.simpleMessage("Discard"),
    "sheet_discard_message": MessageLookupByLibrary.simpleMessage(
      "Your unsaved changes will be lost.",
    ),
    "sheet_discard_title": MessageLookupByLibrary.simpleMessage(
      "Discard changes?",
    ),
    "sheet_filters": MessageLookupByLibrary.simpleMessage("Filters"),
    "sheet_got_it": MessageLookupByLibrary.simpleMessage("Got it"),
    "sheet_logout_confirm": MessageLookupByLibrary.simpleMessage("Log out"),
    "sheet_logout_message": MessageLookupByLibrary.simpleMessage(
      "You can sign back in at any time.",
    ),
    "sheet_logout_title": MessageLookupByLibrary.simpleMessage("Log out?"),
    "sheet_reset": MessageLookupByLibrary.simpleMessage("Reset"),
    "shop_add_to_cart": MessageLookupByLibrary.simpleMessage("Add"),
    "shop_browse_category": m190,
    "shop_browse_sub_categories": m191,
    "shop_cart_empty": MessageLookupByLibrary.simpleMessage(
      "Your cart is empty",
    ),
    "shop_cart_full_for_item": m192,
    "shop_category": MessageLookupByLibrary.simpleMessage("Category"),
    "shop_checkout": MessageLookupByLibrary.simpleMessage("Confirm payment"),
    "shop_colour": MessageLookupByLibrary.simpleMessage("Colour"),
    "shop_dimension_height": MessageLookupByLibrary.simpleMessage("height"),
    "shop_dimension_length": MessageLookupByLibrary.simpleMessage("length"),
    "shop_dimension_unit": MessageLookupByLibrary.simpleMessage("cm"),
    "shop_dimension_width": MessageLookupByLibrary.simpleMessage("width"),
    "shop_discount_badge": m193,
    "shop_empty": MessageLookupByLibrary.simpleMessage("Nothing here yet"),
    "shop_favorites_empty": MessageLookupByLibrary.simpleMessage(
      "No favourites yet",
    ),
    "shop_filter": MessageLookupByLibrary.simpleMessage("Filter"),
    "shop_filter_apply": MessageLookupByLibrary.simpleMessage("Show results"),
    "shop_filter_clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "shop_filter_featured": MessageLookupByLibrary.simpleMessage(
      "Featured only",
    ),
    "shop_filter_on_sale": MessageLookupByLibrary.simpleMessage("On sale"),
    "shop_filters": MessageLookupByLibrary.simpleMessage("Filters"),
    "shop_in_cart_already": m194,
    "shop_line_item": m195,
    "shop_materials": MessageLookupByLibrary.simpleMessage(
      "Raw materials and tools",
    ),
    "shop_materials_cta": MessageLookupByLibrary.simpleMessage(
      "Shop materials",
    ),
    "shop_materials_one_basket": MessageLookupByLibrary.simpleMessage(
      "Materials go in the same basket as everything else.",
    ),
    "shop_materials_subtitle": MessageLookupByLibrary.simpleMessage(
      "Clay, glazes and the tools the studio works with",
    ),
    "shop_max_per_order": MessageLookupByLibrary.simpleMessage(
      "100 per order is the most we can take",
    ),
    "shop_max_reached": m196,
    "shop_my_cart": MessageLookupByLibrary.simpleMessage("My cart"),
    "shop_my_favorites": MessageLookupByLibrary.simpleMessage("My favourites"),
    "shop_my_orders": MessageLookupByLibrary.simpleMessage("My orders"),
    "shop_no_results": MessageLookupByLibrary.simpleMessage(
      "Nothing matches that",
    ),
    "shop_orders_empty": MessageLookupByLibrary.simpleMessage("No orders yet"),
    "shop_orders_empty_body": MessageLookupByLibrary.simpleMessage(
      "Anything you order from the studio shows up here.",
    ),
    "shop_out_of_stock": MessageLookupByLibrary.simpleMessage("Out of stock"),
    "shop_price_max": MessageLookupByLibrary.simpleMessage("To"),
    "shop_price_min": MessageLookupByLibrary.simpleMessage("From"),
    "shop_price_range": MessageLookupByLibrary.simpleMessage("Price"),
    "shop_price_range_invalid": MessageLookupByLibrary.simpleMessage(
      "“To” cannot be below “From”.",
    ),
    "shop_product_details": MessageLookupByLibrary.simpleMessage(
      "Product details",
    ),
    "shop_quantity": m197,
    "shop_remove_line_message": m198,
    "shop_remove_line_title": MessageLookupByLibrary.simpleMessage(
      "Take it out?",
    ),
    "shop_results_count": m199,
    "shop_search_hint": MessageLookupByLibrary.simpleMessage("Search..."),
    "shop_size": MessageLookupByLibrary.simpleMessage("Size"),
    "shop_sort_default": MessageLookupByLibrary.simpleMessage(
      "The studio’s order",
    ),
    "shop_sort_label": MessageLookupByLibrary.simpleMessage("Order"),
    "shop_sort_newest": MessageLookupByLibrary.simpleMessage("Newest first"),
    "shop_sort_price_asc": MessageLookupByLibrary.simpleMessage(
      "Price: low to high",
    ),
    "shop_sort_price_desc": MessageLookupByLibrary.simpleMessage(
      "Price: high to low",
    ),
    "shop_stock_left": m200,
    "shop_subtitle": MessageLookupByLibrary.simpleMessage(
      "Handmade pieces, ready to take home.",
    ),
    "shop_title": MessageLookupByLibrary.simpleMessage("Terracotta shop"),
    "shop_you_may_like": MessageLookupByLibrary.simpleMessage(
      "You may also like",
    ),
    "slider_age_range": MessageLookupByLibrary.simpleMessage("Age range"),
    "slider_any": MessageLookupByLibrary.simpleMessage("Any"),
    "slider_brightness": MessageLookupByLibrary.simpleMessage("Brightness"),
    "slider_distance": MessageLookupByLibrary.simpleMessage("Distance"),
    "slider_min_rating": MessageLookupByLibrary.simpleMessage("Minimum rating"),
    "slider_muted": MessageLookupByLibrary.simpleMessage("Muted"),
    "slider_playback_speed": MessageLookupByLibrary.simpleMessage(
      "Playback speed",
    ),
    "slider_price_range": MessageLookupByLibrary.simpleMessage("Price range"),
    "slider_quality": MessageLookupByLibrary.simpleMessage("Quality"),
    "slider_quality_high": MessageLookupByLibrary.simpleMessage("High"),
    "slider_quality_low": MessageLookupByLibrary.simpleMessage("Low"),
    "slider_quality_medium": MessageLookupByLibrary.simpleMessage("Medium"),
    "slider_quality_ultra": MessageLookupByLibrary.simpleMessage("Ultra"),
    "slider_text_size": MessageLookupByLibrary.simpleMessage("Text size"),
    "slider_unit_km": MessageLookupByLibrary.simpleMessage("km"),
    "slider_unit_mi": MessageLookupByLibrary.simpleMessage("mi"),
    "slider_volume": MessageLookupByLibrary.simpleMessage("Volume"),
    "slider_years": MessageLookupByLibrary.simpleMessage("yrs"),
    "social_button_continue_with": m201,
    "sort_name_az": MessageLookupByLibrary.simpleMessage("Name: A–Z"),
    "sort_name_za": MessageLookupByLibrary.simpleMessage("Name: Z–A"),
    "sort_newest": MessageLookupByLibrary.simpleMessage("Newest"),
    "sort_oldest": MessageLookupByLibrary.simpleMessage("Oldest"),
    "sort_price_high_low": MessageLookupByLibrary.simpleMessage(
      "Price: high to low",
    ),
    "sort_price_low_high": MessageLookupByLibrary.simpleMessage(
      "Price: low to high",
    ),
    "sort_rating": MessageLookupByLibrary.simpleMessage("Highest rated"),
    "sort_relevance": MessageLookupByLibrary.simpleMessage("Most relevant"),
    "stack_card_of": m202,
    "stack_layer_of": m203,
    "stack_swipe_down": MessageLookupByLibrary.simpleMessage("Swipe down"),
    "stack_swipe_left": MessageLookupByLibrary.simpleMessage("Swipe left"),
    "stack_swipe_right": MessageLookupByLibrary.simpleMessage("Swipe right"),
    "stack_swipe_up": MessageLookupByLibrary.simpleMessage("Swipe up"),
    "stepper_completed": MessageLookupByLibrary.simpleMessage("completed"),
    "stepper_current": MessageLookupByLibrary.simpleMessage("current step"),
    "stepper_decrease": MessageLookupByLibrary.simpleMessage("Decrease"),
    "stepper_disabled": MessageLookupByLibrary.simpleMessage("unavailable"),
    "stepper_error": MessageLookupByLibrary.simpleMessage("needs attention"),
    "stepper_increase": MessageLookupByLibrary.simpleMessage("Increase"),
    "stepper_step_of": m204,
    "stepper_upcoming": MessageLookupByLibrary.simpleMessage("not started"),
    "swift_field_bank": MessageLookupByLibrary.simpleMessage(
      "Bank code is 4 letters",
    ),
    "swift_field_branch": MessageLookupByLibrary.simpleMessage(
      "Invalid branch code",
    ),
    "swift_field_country": MessageLookupByLibrary.simpleMessage(
      "Unknown country code",
    ),
    "swift_field_country_not_allowed": MessageLookupByLibrary.simpleMessage(
      "Country not supported",
    ),
    "swift_field_head_office": MessageLookupByLibrary.simpleMessage(
      "Head office",
    ),
    "swift_field_hint": MessageLookupByLibrary.simpleMessage(
      "Enter SWIFT / BIC",
    ),
    "swift_field_iban_mismatch": MessageLookupByLibrary.simpleMessage(
      "BIC country doesn\'t match the IBAN",
    ),
    "swift_field_length": MessageLookupByLibrary.simpleMessage(
      "BIC is 8 or 11 characters",
    ),
    "swift_field_location": MessageLookupByLibrary.simpleMessage(
      "Invalid location code",
    ),
    "swift_field_required": MessageLookupByLibrary.simpleMessage(
      "SWIFT / BIC is required",
    ),
    "swift_field_test_warning": MessageLookupByLibrary.simpleMessage(
      "Test BIC — not for live payments",
    ),
    "switch_analytics": MessageLookupByLibrary.simpleMessage(
      "Share usage data",
    ),
    "switch_analytics_desc": MessageLookupByLibrary.simpleMessage(
      "Anonymous analytics that help improve the app",
    ),
    "switch_biometric": MessageLookupByLibrary.simpleMessage(
      "Biometric unlock",
    ),
    "switch_biometric_desc": MessageLookupByLibrary.simpleMessage(
      "Face ID / fingerprint on launch",
    ),
    "switch_crash_reports": MessageLookupByLibrary.simpleMessage(
      "Send crash reports",
    ),
    "switch_dark_mode": MessageLookupByLibrary.simpleMessage("Dark mode"),
    "switch_haptics": MessageLookupByLibrary.simpleMessage("Haptic feedback"),
    "switch_notifications": MessageLookupByLibrary.simpleMessage(
      "Push notifications",
    ),
    "switch_off": MessageLookupByLibrary.simpleMessage("Off"),
    "switch_on": MessageLookupByLibrary.simpleMessage("On"),
    "tags_field_hint": MessageLookupByLibrary.simpleMessage("Add a tag…"),
    "tags_field_max_reached": m205,
    "tags_field_min": m206,
    "tags_field_not_allowed": MessageLookupByLibrary.simpleMessage(
      "Pick from the suggestions",
    ),
    "tags_field_too_long": m207,
    "text_field_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "text_field_caps_lock_on": MessageLookupByLibrary.simpleMessage(
      "Caps Lock is on",
    ),
    "text_field_chars": MessageLookupByLibrary.simpleMessage("chars"),
    "text_field_clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "text_field_clear_all": MessageLookupByLibrary.simpleMessage("Clear All"),
    "text_field_email_domain_not_allowed": m208,
    "text_field_email_domain_unreachable": MessageLookupByLibrary.simpleMessage(
      "This email domain can\'t receive mail",
    ),
    "text_field_generate_password": MessageLookupByLibrary.simpleMessage(
      "Generate password",
    ),
    "text_field_hold_to_reveal": MessageLookupByLibrary.simpleMessage(
      "Hold to reveal password",
    ),
    "text_field_name_parts_progress": m209,
    "text_field_password_breached": m210,
    "text_field_password_confirm_hint": MessageLookupByLibrary.simpleMessage(
      "Confirm your password",
    ),
    "text_field_password_create_hint": MessageLookupByLibrary.simpleMessage(
      "Create a password",
    ),
    "text_field_password_hint": MessageLookupByLibrary.simpleMessage(
      "Enter your password",
    ),
    "text_field_profanity_warning": MessageLookupByLibrary.simpleMessage(
      "May contain inappropriate language",
    ),
    "text_field_redo": MessageLookupByLibrary.simpleMessage("Redo"),
    "text_field_req_digit": MessageLookupByLibrary.simpleMessage(
      "Contains a number",
    ),
    "text_field_req_lowercase": MessageLookupByLibrary.simpleMessage(
      "Contains a lowercase letter",
    ),
    "text_field_req_min_length": m211,
    "text_field_req_no_spaces": MessageLookupByLibrary.simpleMessage(
      "No spaces",
    ),
    "text_field_req_special_char": MessageLookupByLibrary.simpleMessage(
      "Contains a special character",
    ),
    "text_field_req_uppercase": MessageLookupByLibrary.simpleMessage(
      "Contains an uppercase letter",
    ),
    "text_field_reveal": MessageLookupByLibrary.simpleMessage("Reveal"),
    "text_field_reveal_password_message": MessageLookupByLibrary.simpleMessage(
      "Your screen is being recorded or shared — anyone watching will see what you typed.",
    ),
    "text_field_reveal_password_title": MessageLookupByLibrary.simpleMessage(
      "Reveal password?",
    ),
    "text_field_screen_capture_warning": MessageLookupByLibrary.simpleMessage(
      "Screen is being recorded or shared — input stays hidden",
    ),
    "text_field_strength_medium": MessageLookupByLibrary.simpleMessage(
      "Medium",
    ),
    "text_field_strength_strong": MessageLookupByLibrary.simpleMessage(
      "Strong",
    ),
    "text_field_strength_weak": MessageLookupByLibrary.simpleMessage("Weak"),
    "text_field_toggle_visibility": MessageLookupByLibrary.simpleMessage(
      "Show or hide password",
    ),
    "text_field_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "text_field_voice_input": MessageLookupByLibrary.simpleMessage(
      "Voice input",
    ),
    "text_field_word": MessageLookupByLibrary.simpleMessage("word"),
    "text_field_words": MessageLookupByLibrary.simpleMessage("words"),
    "text_read_less": MessageLookupByLibrary.simpleMessage("Read less"),
    "text_read_more": MessageLookupByLibrary.simpleMessage("Read more"),
    "theme_mode_dark": MessageLookupByLibrary.simpleMessage("Dark"),
    "theme_mode_light": MessageLookupByLibrary.simpleMessage("Light"),
    "theme_mode_system": MessageLookupByLibrary.simpleMessage("System"),
    "time_field_format_12": MessageLookupByLibrary.simpleMessage("12h"),
    "time_field_format_24": MessageLookupByLibrary.simpleMessage("24h"),
    "time_field_hour_word": MessageLookupByLibrary.simpleMessage("HH"),
    "time_field_incomplete": m212,
    "time_field_interval": m213,
    "time_field_max_time": m214,
    "time_field_min_time": m215,
    "time_field_minute_word": MessageLookupByLibrary.simpleMessage("mm"),
    "time_field_must_be_after": m216,
    "time_field_now": MessageLookupByLibrary.simpleMessage("Now"),
    "time_field_outside_window": m217,
    "time_field_pick_time": MessageLookupByLibrary.simpleMessage("Pick a time"),
    "time_field_required": MessageLookupByLibrary.simpleMessage(
      "Time cannot be empty",
    ),
    "time_field_second_word": MessageLookupByLibrary.simpleMessage("ss"),
    "time_range_duration": m218,
    "time_range_end": MessageLookupByLibrary.simpleMessage("End time"),
    "time_range_start": MessageLookupByLibrary.simpleMessage("Start time"),
    "timezone_africa_accra": MessageLookupByLibrary.simpleMessage("Accra"),
    "timezone_africa_addis_ababa": MessageLookupByLibrary.simpleMessage(
      "Addis Ababa",
    ),
    "timezone_africa_algiers": MessageLookupByLibrary.simpleMessage("Algiers"),
    "timezone_africa_cairo": MessageLookupByLibrary.simpleMessage("Cairo"),
    "timezone_africa_casablanca": MessageLookupByLibrary.simpleMessage(
      "Casablanca",
    ),
    "timezone_africa_johannesburg": MessageLookupByLibrary.simpleMessage(
      "Johannesburg",
    ),
    "timezone_africa_khartoum": MessageLookupByLibrary.simpleMessage(
      "Khartoum",
    ),
    "timezone_africa_kinshasa": MessageLookupByLibrary.simpleMessage(
      "Kinshasa",
    ),
    "timezone_africa_lagos": MessageLookupByLibrary.simpleMessage("Lagos"),
    "timezone_africa_mogadishu": MessageLookupByLibrary.simpleMessage(
      "Mogadishu",
    ),
    "timezone_africa_nairobi": MessageLookupByLibrary.simpleMessage("Nairobi"),
    "timezone_africa_nouakchott": MessageLookupByLibrary.simpleMessage(
      "Nouakchott",
    ),
    "timezone_africa_tripoli": MessageLookupByLibrary.simpleMessage("Tripoli"),
    "timezone_africa_tunis": MessageLookupByLibrary.simpleMessage("Tunis"),
    "timezone_america_anchorage": MessageLookupByLibrary.simpleMessage(
      "Anchorage",
    ),
    "timezone_america_argentina_buenos_aires":
        MessageLookupByLibrary.simpleMessage("Buenos Aires"),
    "timezone_america_bogota": MessageLookupByLibrary.simpleMessage("Bogota"),
    "timezone_america_caracas": MessageLookupByLibrary.simpleMessage("Caracas"),
    "timezone_america_chicago": MessageLookupByLibrary.simpleMessage("Chicago"),
    "timezone_america_denver": MessageLookupByLibrary.simpleMessage("Denver"),
    "timezone_america_lima": MessageLookupByLibrary.simpleMessage("Lima"),
    "timezone_america_los_angeles": MessageLookupByLibrary.simpleMessage(
      "Los Angeles",
    ),
    "timezone_america_mexico_city": MessageLookupByLibrary.simpleMessage(
      "Mexico City",
    ),
    "timezone_america_new_york": MessageLookupByLibrary.simpleMessage(
      "New York",
    ),
    "timezone_america_noronha": MessageLookupByLibrary.simpleMessage(
      "Fernando de Noronha",
    ),
    "timezone_america_santiago": MessageLookupByLibrary.simpleMessage(
      "Santiago",
    ),
    "timezone_america_sao_paulo": MessageLookupByLibrary.simpleMessage(
      "Sao Paulo",
    ),
    "timezone_america_st_johns": MessageLookupByLibrary.simpleMessage(
      "St. John\'s",
    ),
    "timezone_america_toronto": MessageLookupByLibrary.simpleMessage("Toronto"),
    "timezone_asia_aden": MessageLookupByLibrary.simpleMessage("Sanaa"),
    "timezone_asia_almaty": MessageLookupByLibrary.simpleMessage("Almaty"),
    "timezone_asia_amman": MessageLookupByLibrary.simpleMessage("Amman"),
    "timezone_asia_baghdad": MessageLookupByLibrary.simpleMessage("Baghdad"),
    "timezone_asia_bahrain": MessageLookupByLibrary.simpleMessage("Manama"),
    "timezone_asia_bangkok": MessageLookupByLibrary.simpleMessage("Bangkok"),
    "timezone_asia_beirut": MessageLookupByLibrary.simpleMessage("Beirut"),
    "timezone_asia_colombo": MessageLookupByLibrary.simpleMessage("Colombo"),
    "timezone_asia_damascus": MessageLookupByLibrary.simpleMessage("Damascus"),
    "timezone_asia_dhaka": MessageLookupByLibrary.simpleMessage("Dhaka"),
    "timezone_asia_dubai": MessageLookupByLibrary.simpleMessage("Dubai"),
    "timezone_asia_ho_chi_minh": MessageLookupByLibrary.simpleMessage(
      "Ho Chi Minh",
    ),
    "timezone_asia_hong_kong": MessageLookupByLibrary.simpleMessage(
      "Hong Kong",
    ),
    "timezone_asia_jakarta": MessageLookupByLibrary.simpleMessage("Jakarta"),
    "timezone_asia_jerusalem": MessageLookupByLibrary.simpleMessage(
      "Jerusalem",
    ),
    "timezone_asia_kabul": MessageLookupByLibrary.simpleMessage("Kabul"),
    "timezone_asia_karachi": MessageLookupByLibrary.simpleMessage("Karachi"),
    "timezone_asia_kathmandu": MessageLookupByLibrary.simpleMessage(
      "Kathmandu",
    ),
    "timezone_asia_kolkata": MessageLookupByLibrary.simpleMessage("Delhi"),
    "timezone_asia_kuala_lumpur": MessageLookupByLibrary.simpleMessage(
      "Kuala Lumpur",
    ),
    "timezone_asia_kuwait": MessageLookupByLibrary.simpleMessage("Kuwait City"),
    "timezone_asia_manila": MessageLookupByLibrary.simpleMessage("Manila"),
    "timezone_asia_muscat": MessageLookupByLibrary.simpleMessage("Muscat"),
    "timezone_asia_qatar": MessageLookupByLibrary.simpleMessage("Doha"),
    "timezone_asia_riyadh": MessageLookupByLibrary.simpleMessage("Riyadh"),
    "timezone_asia_seoul": MessageLookupByLibrary.simpleMessage("Seoul"),
    "timezone_asia_shanghai": MessageLookupByLibrary.simpleMessage("Shanghai"),
    "timezone_asia_singapore": MessageLookupByLibrary.simpleMessage(
      "Singapore",
    ),
    "timezone_asia_taipei": MessageLookupByLibrary.simpleMessage("Taipei"),
    "timezone_asia_tashkent": MessageLookupByLibrary.simpleMessage("Tashkent"),
    "timezone_asia_tehran": MessageLookupByLibrary.simpleMessage("Tehran"),
    "timezone_asia_tokyo": MessageLookupByLibrary.simpleMessage("Tokyo"),
    "timezone_asia_yangon": MessageLookupByLibrary.simpleMessage("Yangon"),
    "timezone_atlantic_cape_verde": MessageLookupByLibrary.simpleMessage(
      "Praia",
    ),
    "timezone_atlantic_reykjavik": MessageLookupByLibrary.simpleMessage(
      "Reykjavik",
    ),
    "timezone_australia_adelaide": MessageLookupByLibrary.simpleMessage(
      "Adelaide",
    ),
    "timezone_australia_brisbane": MessageLookupByLibrary.simpleMessage(
      "Brisbane",
    ),
    "timezone_australia_darwin": MessageLookupByLibrary.simpleMessage("Darwin"),
    "timezone_australia_lord_howe": MessageLookupByLibrary.simpleMessage(
      "Lord Howe",
    ),
    "timezone_australia_melbourne": MessageLookupByLibrary.simpleMessage(
      "Melbourne",
    ),
    "timezone_australia_perth": MessageLookupByLibrary.simpleMessage("Perth"),
    "timezone_australia_sydney": MessageLookupByLibrary.simpleMessage("Sydney"),
    "timezone_europe_amsterdam": MessageLookupByLibrary.simpleMessage(
      "Amsterdam",
    ),
    "timezone_europe_athens": MessageLookupByLibrary.simpleMessage("Athens"),
    "timezone_europe_berlin": MessageLookupByLibrary.simpleMessage("Berlin"),
    "timezone_europe_dublin": MessageLookupByLibrary.simpleMessage("Dublin"),
    "timezone_europe_istanbul": MessageLookupByLibrary.simpleMessage(
      "Istanbul",
    ),
    "timezone_europe_kyiv": MessageLookupByLibrary.simpleMessage("Kyiv"),
    "timezone_europe_lisbon": MessageLookupByLibrary.simpleMessage("Lisbon"),
    "timezone_europe_london": MessageLookupByLibrary.simpleMessage("London"),
    "timezone_europe_madrid": MessageLookupByLibrary.simpleMessage("Madrid"),
    "timezone_europe_moscow": MessageLookupByLibrary.simpleMessage("Moscow"),
    "timezone_europe_paris": MessageLookupByLibrary.simpleMessage("Paris"),
    "timezone_europe_rome": MessageLookupByLibrary.simpleMessage("Rome"),
    "timezone_europe_stockholm": MessageLookupByLibrary.simpleMessage(
      "Stockholm",
    ),
    "timezone_europe_zurich": MessageLookupByLibrary.simpleMessage("Zurich"),
    "timezone_pacific_apia": MessageLookupByLibrary.simpleMessage("Apia"),
    "timezone_pacific_auckland": MessageLookupByLibrary.simpleMessage(
      "Auckland",
    ),
    "timezone_pacific_chatham": MessageLookupByLibrary.simpleMessage("Chatham"),
    "timezone_pacific_fiji": MessageLookupByLibrary.simpleMessage("Suva"),
    "timezone_pacific_guadalcanal": MessageLookupByLibrary.simpleMessage(
      "Honiara",
    ),
    "timezone_pacific_guam": MessageLookupByLibrary.simpleMessage("Guam"),
    "timezone_pacific_honolulu": MessageLookupByLibrary.simpleMessage(
      "Honolulu",
    ),
    "timezone_pacific_kiritimati": MessageLookupByLibrary.simpleMessage(
      "Kiritimati",
    ),
    "timezone_pacific_marquesas": MessageLookupByLibrary.simpleMessage(
      "Marquesas",
    ),
    "timezone_pacific_pago_pago": MessageLookupByLibrary.simpleMessage(
      "Pago Pago",
    ),
    "timezone_pacific_port_moresby": MessageLookupByLibrary.simpleMessage(
      "Port Moresby",
    ),
    "timezone_pacific_tongatapu": MessageLookupByLibrary.simpleMessage(
      "Nuku\'alofa",
    ),
    "toggle_group_align_center": MessageLookupByLibrary.simpleMessage(
      "Align center",
    ),
    "toggle_group_align_end": MessageLookupByLibrary.simpleMessage("Align end"),
    "toggle_group_align_justify": MessageLookupByLibrary.simpleMessage(
      "Justify",
    ),
    "toggle_group_align_start": MessageLookupByLibrary.simpleMessage(
      "Align start",
    ),
    "toggle_group_channel_email": MessageLookupByLibrary.simpleMessage("Email"),
    "toggle_group_channel_push": MessageLookupByLibrary.simpleMessage("Push"),
    "toggle_group_channel_sms": MessageLookupByLibrary.simpleMessage("SMS"),
    "toggle_group_count_any": MessageLookupByLibrary.simpleMessage("Any"),
    "toggle_group_daypart_afternoon": MessageLookupByLibrary.simpleMessage(
      "Afternoon",
    ),
    "toggle_group_daypart_evening": MessageLookupByLibrary.simpleMessage(
      "Evening",
    ),
    "toggle_group_daypart_morning": MessageLookupByLibrary.simpleMessage(
      "Morning",
    ),
    "toggle_group_daypart_night": MessageLookupByLibrary.simpleMessage("Night"),
    "toggle_group_format_bold": MessageLookupByLibrary.simpleMessage("Bold"),
    "toggle_group_format_italic": MessageLookupByLibrary.simpleMessage(
      "Italic",
    ),
    "toggle_group_format_strikethrough": MessageLookupByLibrary.simpleMessage(
      "Strikethrough",
    ),
    "toggle_group_format_underline": MessageLookupByLibrary.simpleMessage(
      "Underline",
    ),
    "toggle_group_overflow_label": m219,
    "toggle_group_overflow_tooltip": MessageLookupByLibrary.simpleMessage(
      "More options",
    ),
    "toggle_group_semantic_label": MessageLookupByLibrary.simpleMessage(
      "Toggle group",
    ),
    "toggle_group_sort_asc": MessageLookupByLibrary.simpleMessage("Ascending"),
    "toggle_group_sort_desc": MessageLookupByLibrary.simpleMessage(
      "Descending",
    ),
    "transfer_addresses": m220,
    "transfer_basket": m221,
    "transfer_body": MessageLookupByLibrary.simpleMessage(
      "You collected these before signing in. They live on this phone only — we can move them to your account now.",
    ),
    "transfer_confirm": MessageLookupByLibrary.simpleMessage(
      "Move them to my account",
    ),
    "transfer_discard_body": MessageLookupByLibrary.simpleMessage(
      "They only live on this phone, so they will be gone once you continue. Nothing is charged either way.",
    ),
    "transfer_discard_confirm": MessageLookupByLibrary.simpleMessage(
      "Leave them",
    ),
    "transfer_discard_title": MessageLookupByLibrary.simpleMessage(
      "Leave them behind?",
    ),
    "transfer_done": m222,
    "transfer_partial": m223,
    "transfer_saved": m224,
    "transfer_skip": MessageLookupByLibrary.simpleMessage("Not these"),
    "transfer_title": MessageLookupByLibrary.simpleMessage(
      "Bring your picks with you?",
    ),
    "update_hard_button": MessageLookupByLibrary.simpleMessage("Update now"),
    "update_hard_message": MessageLookupByLibrary.simpleMessage(
      "You\'re running an older version. Update to keep using the app.",
    ),
    "update_hard_title": MessageLookupByLibrary.simpleMessage(
      "Update required",
    ),
    "update_soft_later_button": MessageLookupByLibrary.simpleMessage(
      "Maybe later",
    ),
    "update_soft_message": MessageLookupByLibrary.simpleMessage(
      "A newer version is ready. Update for the latest improvements.",
    ),
    "update_soft_skip_button": MessageLookupByLibrary.simpleMessage(
      "Skip this version",
    ),
    "update_soft_title": MessageLookupByLibrary.simpleMessage(
      "New version available",
    ),
    "update_soft_update_button": MessageLookupByLibrary.simpleMessage("Update"),
    "update_unavailable_message": MessageLookupByLibrary.simpleMessage(
      "We can\'t open the store right now. Try again from your home screen.",
    ),
    "update_unavailable_title": MessageLookupByLibrary.simpleMessage(
      "Update unavailable",
    ),
    "update_version_label": MessageLookupByLibrary.simpleMessage("Version"),
    "url_field_dismiss_paste": MessageLookupByLibrary.simpleMessage("Dismiss"),
    "url_field_domain_blocked": m225,
    "url_field_domain_not_allowed": m226,
    "url_field_https_required": MessageLookupByLibrary.simpleMessage(
      "Use a secure https:// link",
    ),
    "url_field_lookalike_host": MessageLookupByLibrary.simpleMessage(
      "Address uses lookalike characters — check it carefully",
    ),
    "url_field_punycode_host": MessageLookupByLibrary.simpleMessage(
      "Encoded international domain — check it carefully",
    ),
    "url_field_scheme_not_allowed": m227,
    "validator_age_at_least_n_years": m228,
    "validator_age_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Age cannot be empty",
    ),
    "validator_age_must_be_at_least_12": MessageLookupByLibrary.simpleMessage(
      "Age must be at least 12 years old",
    ),
    "validator_age_must_be_less_than_100": MessageLookupByLibrary.simpleMessage(
      "Age must be less than 100 years old",
    ),
    "validator_age_under_n_years": m229,
    "validator_card_cvv_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "CVV cannot be empty",
    ),
    "validator_card_cvv_must_be_n_digits": m230,
    "validator_card_cvv_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "CVV must be 3 or 4 digits",
    ),
    "validator_card_expiry_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Card expiry cannot be empty"),
    "validator_card_expiry_month_invalid": MessageLookupByLibrary.simpleMessage(
      "Month must be between 01 and 12",
    ),
    "validator_card_expiry_must_be_in_the_future":
        MessageLookupByLibrary.simpleMessage("Card has expired"),
    "validator_card_expiry_must_be_mm_yy": MessageLookupByLibrary.simpleMessage(
      "Card expiry must be MM/YY",
    ),
    "validator_card_expiry_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Card expiry must be MM/YY or MM/YYYY",
    ),
    "validator_card_number_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Card number cannot be empty"),
    "validator_card_number_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Card number is invalid",
    ),
    "validator_confirm_password_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage(
          "Confirm password cannot be empty",
        ),
    "validator_confirm_password_must_be_the_same_as_password":
        MessageLookupByLibrary.simpleMessage(
          "Confirm password must be the same as password",
        ),
    "validator_contains_inappropriate_language":
        MessageLookupByLibrary.simpleMessage("Contains inappropriate language"),
    "validator_date_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Date cannot be empty",
    ),
    "validator_date_must_be_in_the_future":
        MessageLookupByLibrary.simpleMessage("Date must be in the future"),
    "validator_date_must_be_in_the_past": MessageLookupByLibrary.simpleMessage(
      "Date must be in the past",
    ),
    "validator_date_of_birth_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Date of birth cannot be empty"),
    "validator_date_of_birth_must_be_valid":
        MessageLookupByLibrary.simpleMessage(
          "Date of birth must be between 1900 and the current date",
        ),
    "validator_email_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Email cannot be empty",
    ),
    "validator_email_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Email must be valid",
    ),
    "validator_father_name_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Father\'s name cannot be empty"),
    "validator_father_name_must_be_at_least_3_characters":
        MessageLookupByLibrary.simpleMessage(
          "Father\'s name must be at least 3 characters long",
        ),
    "validator_father_name_must_be_less_than_50_characters":
        MessageLookupByLibrary.simpleMessage(
          "Father\'s name must be less than 50 characters",
        ),
    "validator_father_name_must_contain_only_letters_and_spaces":
        MessageLookupByLibrary.simpleMessage(
          "Father\'s name must contain only letters and spaces",
        ),
    "validator_field_is_required": MessageLookupByLibrary.simpleMessage(
      "This field is required",
    ),
    "validator_file_extension_not_allowed":
        MessageLookupByLibrary.simpleMessage("File extension is not allowed"),
    "validator_file_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "File name cannot be empty",
    ),
    "validator_file_name_invalid": MessageLookupByLibrary.simpleMessage(
      "File name contains invalid characters",
    ),
    "validator_file_size_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "File size is missing",
    ),
    "validator_file_size_too_large": MessageLookupByLibrary.simpleMessage(
      "File is too large",
    ),
    "validator_first_name_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("First name cannot be empty"),
    "validator_first_name_must_be_at_least_3_characters":
        MessageLookupByLibrary.simpleMessage(
          "First name must be at least 3 characters long",
        ),
    "validator_first_name_must_be_less_than_50_characters":
        MessageLookupByLibrary.simpleMessage(
          "First name must be less than 50 characters",
        ),
    "validator_first_name_must_contain_only_letters_and_spaces":
        MessageLookupByLibrary.simpleMessage(
          "First name must contain only letters and spaces",
        ),
    "validator_form_invalid": MessageLookupByLibrary.simpleMessage(
      "Form is invalid",
    ),
    "validator_full_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Full name cannot be empty",
    ),
    "validator_full_name_must_be_less_than_100_characters":
        MessageLookupByLibrary.simpleMessage(
          "Full name must be less than 100 characters",
        ),
    "validator_full_name_must_contain_only_letters_and_spaces":
        MessageLookupByLibrary.simpleMessage(
          "Full name must contain only letters and spaces",
        ),
    "validator_full_name_must_have_at_least_n_parts": m231,
    "validator_gender_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Gender cannot be empty",
    ),
    "validator_iban_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "IBAN cannot be empty",
    ),
    "validator_iban_length_for_country": m232,
    "validator_iban_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "IBAN is invalid",
    ),
    "validator_image_url_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Image URL cannot be empty",
    ),
    "validator_image_url_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Image URL must be valid",
    ),
    "validator_invalid_country_code": MessageLookupByLibrary.simpleMessage(
      "Invalid country code",
    ),
    "validator_invalid_format": MessageLookupByLibrary.simpleMessage(
      "Invalid format",
    ),
    "validator_ip_address_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("IP address cannot be empty"),
    "validator_ip_address_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "IP address is invalid",
    ),
    "validator_last_name_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Last name cannot be empty",
    ),
    "validator_last_name_must_be_at_least_3_characters":
        MessageLookupByLibrary.simpleMessage(
          "Last name must be at least 3 characters long",
        ),
    "validator_last_name_must_be_less_than_50_characters":
        MessageLookupByLibrary.simpleMessage(
          "Last name must be less than 50 characters",
        ),
    "validator_last_name_must_contain_only_letters_and_spaces":
        MessageLookupByLibrary.simpleMessage(
          "Last name must contain only letters and spaces",
        ),
    "validator_latitude_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Latitude cannot be empty",
    ),
    "validator_latitude_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Latitude must be between -90 and 90",
    ),
    "validator_list_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Please select at least one item",
    ),
    "validator_list_must_have_at_least": m233,
    "validator_list_must_have_at_most": m234,
    "validator_longitude_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Longitude cannot be empty",
    ),
    "validator_longitude_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Longitude must be between -180 and 180",
    ),
    "validator_mac_address_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("MAC address cannot be empty"),
    "validator_mac_address_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "MAC address is invalid",
    ),
    "validator_middle_name_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Middle name cannot be empty"),
    "validator_middle_name_must_be_at_least_3_characters":
        MessageLookupByLibrary.simpleMessage(
          "Middle name must be at least 3 characters long",
        ),
    "validator_middle_name_must_be_less_than_50_characters":
        MessageLookupByLibrary.simpleMessage(
          "Middle name must be less than 50 characters",
        ),
    "validator_middle_name_must_contain_only_letters_and_spaces":
        MessageLookupByLibrary.simpleMessage(
          "Middle name must contain only letters and spaces",
        ),
    "validator_must_be_a_valid_integer": MessageLookupByLibrary.simpleMessage(
      "Must be a valid integer",
    ),
    "validator_must_be_a_valid_number": MessageLookupByLibrary.simpleMessage(
      "Must be a valid number",
    ),
    "validator_must_be_at_least_n": m235,
    "validator_must_be_at_least_n_characters": m236,
    "validator_must_be_at_most_n": m237,
    "validator_must_be_at_most_n_characters": m238,
    "validator_name_must_use_arabic_letters":
        MessageLookupByLibrary.simpleMessage("Name must use Arabic letters"),
    "validator_name_must_use_latin_letters":
        MessageLookupByLibrary.simpleMessage("Name must use English letters"),
    "validator_number_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Number cannot be empty",
    ),
    "validator_otp_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "OTP cannot be empty",
    ),
    "validator_otp_must_be_n_digits": m239,
    "validator_passport_expiry_date_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage(
          "Passport expiry date cannot be empty",
        ),
    "validator_passport_expiry_date_must_be_at_least_6_months_from_now":
        MessageLookupByLibrary.simpleMessage(
          "Passport expiry date must be at least 6 months from now",
        ),
    "validator_passport_number_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Passport number cannot be empty"),
    "validator_passport_number_must_be_at_least_3_characters":
        MessageLookupByLibrary.simpleMessage(
          "Passport number must be at least 3 characters long",
        ),
    "validator_passport_number_must_be_less_than_50_characters":
        MessageLookupByLibrary.simpleMessage(
          "Passport number must be less than 50 characters",
        ),
    "validator_password_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Password cannot be empty",
    ),
    "validator_password_must_be_at_least_6_characters":
        MessageLookupByLibrary.simpleMessage(
          "Password must be at least 6 characters long",
        ),
    "validator_password_must_contain_at_least_one_lowercase_letter":
        MessageLookupByLibrary.simpleMessage(
          "Password must contain at least one lowercase letter",
        ),
    "validator_password_must_contain_at_least_one_number":
        MessageLookupByLibrary.simpleMessage(
          "Password must contain at least one number",
        ),
    "validator_password_must_contain_at_least_one_special_character":
        MessageLookupByLibrary.simpleMessage(
          "Password must contain at least one special character",
        ),
    "validator_password_must_contain_at_least_one_uppercase_letter":
        MessageLookupByLibrary.simpleMessage(
          "Password must contain at least one uppercase letter",
        ),
    "validator_phone_number_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Phone number cannot be empty"),
    "validator_phone_number_is_too_long": MessageLookupByLibrary.simpleMessage(
      "Phone number is too long",
    ),
    "validator_phone_number_is_too_short": MessageLookupByLibrary.simpleMessage(
      "Phone number is too short",
    ),
    "validator_phone_number_must_contain_only_digits":
        MessageLookupByLibrary.simpleMessage(
          "Phone number must contain only digits",
        ),
    "validator_port_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Port cannot be empty",
    ),
    "validator_port_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Port must be between 1 and 65535",
    ),
    "validator_postal_code_cannot_be_empty":
        MessageLookupByLibrary.simpleMessage("Postal code cannot be empty"),
    "validator_postal_code_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Postal code is invalid",
    ),
    "validator_url_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "URL cannot be empty",
    ),
    "validator_url_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "URL must be valid",
    ),
    "validator_url_must_start_with_http_or_https":
        MessageLookupByLibrary.simpleMessage(
          "URL must start with http:// or https://",
        ),
    "validator_username_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Username cannot be empty",
    ),
    "validator_username_must_be_at_least_3_characters":
        MessageLookupByLibrary.simpleMessage(
          "Username must be at least 3 characters long",
        ),
    "validator_username_must_be_less_than_20_characters":
        MessageLookupByLibrary.simpleMessage(
          "Username must be less than 20 characters",
        ),
    "validator_username_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Username must be valid",
    ),
    "validator_video_url_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "Video URL cannot be empty",
    ),
    "validator_video_url_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "Video URL must be valid",
    ),
    "validator_vin_cannot_be_empty": MessageLookupByLibrary.simpleMessage(
      "VIN cannot be empty",
    ),
    "validator_vin_must_be_valid": MessageLookupByLibrary.simpleMessage(
      "VIN is invalid",
    ),
    "video_audio_track": MessageLookupByLibrary.simpleMessage("Audio track"),
    "video_cancel_autoplay": MessageLookupByLibrary.simpleMessage("Cancel"),
    "video_cast": MessageLookupByLibrary.simpleMessage(
      "Play on another screen",
    ),
    "video_chapters": MessageLookupByLibrary.simpleMessage("Chapters"),
    "video_enter_fullscreen": MessageLookupByLibrary.simpleMessage(
      "Enter fullscreen",
    ),
    "video_exit_fullscreen": MessageLookupByLibrary.simpleMessage(
      "Exit fullscreen",
    ),
    "video_load_failed": MessageLookupByLibrary.simpleMessage(
      "Failed to load video",
    ),
    "video_lock_screen": MessageLookupByLibrary.simpleMessage("Lock screen"),
    "video_loop_clear": MessageLookupByLibrary.simpleMessage("Clear loop"),
    "video_loop_set_a": MessageLookupByLibrary.simpleMessage("Loop from here"),
    "video_loop_set_b": MessageLookupByLibrary.simpleMessage("Loop to here"),
    "video_mute": MessageLookupByLibrary.simpleMessage("Mute"),
    "video_next": MessageLookupByLibrary.simpleMessage("Next video"),
    "video_no_audio_device": MessageLookupByLibrary.simpleMessage(
      "No audio output device",
    ),
    "video_off": MessageLookupByLibrary.simpleMessage("Off"),
    "video_pause": MessageLookupByLibrary.simpleMessage("Pause"),
    "video_play": MessageLookupByLibrary.simpleMessage("Play"),
    "video_play_now": MessageLookupByLibrary.simpleMessage("Play now"),
    "video_playback_speed": MessageLookupByLibrary.simpleMessage(
      "Playback speed",
    ),
    "video_player": MessageLookupByLibrary.simpleMessage("Video player"),
    "video_previous": MessageLookupByLibrary.simpleMessage("Previous video"),
    "video_quality": MessageLookupByLibrary.simpleMessage("Quality"),
    "video_replay": MessageLookupByLibrary.simpleMessage(
      "Replay from the start",
    ),
    "video_replay_start": MessageLookupByLibrary.simpleMessage(
      "Play from start",
    ),
    "video_screenshot": MessageLookupByLibrary.simpleMessage(
      "Take a screenshot",
    ),
    "video_seek": MessageLookupByLibrary.simpleMessage("Playback position"),
    "video_seek_back": m240,
    "video_seek_forward": m241,
    "video_settings": MessageLookupByLibrary.simpleMessage("Playback settings"),
    "video_sleep_end": MessageLookupByLibrary.simpleMessage(
      "End of this video",
    ),
    "video_sleep_minutes": m242,
    "video_sleep_off": MessageLookupByLibrary.simpleMessage("No timer"),
    "video_sleep_timer": MessageLookupByLibrary.simpleMessage("Sleep timer"),
    "video_subtitle_delay": MessageLookupByLibrary.simpleMessage(
      "Subtitle delay",
    ),
    "video_subtitle_earlier": MessageLookupByLibrary.simpleMessage("Earlier"),
    "video_subtitle_larger": MessageLookupByLibrary.simpleMessage("Larger"),
    "video_subtitle_later": MessageLookupByLibrary.simpleMessage("Later"),
    "video_subtitle_normal": MessageLookupByLibrary.simpleMessage("Normal"),
    "video_subtitle_reset": MessageLookupByLibrary.simpleMessage("In sync"),
    "video_subtitle_size": MessageLookupByLibrary.simpleMessage(
      "Subtitle size",
    ),
    "video_subtitle_smaller": MessageLookupByLibrary.simpleMessage("Smaller"),
    "video_subtitles": MessageLookupByLibrary.simpleMessage("Subtitles"),
    "video_subtitles_off": MessageLookupByLibrary.simpleMessage(
      "Subtitles off",
    ),
    "video_subtitles_on": MessageLookupByLibrary.simpleMessage("Subtitles on"),
    "video_unlock_screen": MessageLookupByLibrary.simpleMessage(
      "Unlock screen",
    ),
    "video_unmute": MessageLookupByLibrary.simpleMessage("Unmute"),
    "video_up_next": MessageLookupByLibrary.simpleMessage("Up next"),
    "video_zoom_fill": MessageLookupByLibrary.simpleMessage("Fill the frame"),
    "video_zoom_fit": MessageLookupByLibrary.simpleMessage("Fit the frame"),
    "vin_field_checksum": MessageLookupByLibrary.simpleMessage(
      "Invalid VIN (check digit mismatch)",
    ),
    "vin_field_hint": MessageLookupByLibrary.simpleMessage("Enter VIN"),
    "vin_field_length": MessageLookupByLibrary.simpleMessage(
      "VIN is 17 characters",
    ),
    "vin_field_required": MessageLookupByLibrary.simpleMessage(
      "VIN is required",
    ),
    "vin_field_year": m243,
    "wallet_balance_after": m244,
    "wallet_credit": MessageLookupByLibrary.simpleMessage("Added to balance"),
    "wallet_debit": MessageLookupByLibrary.simpleMessage("Taken from balance"),
    "wallet_empty_body": MessageLookupByLibrary.simpleMessage(
      "Everything added to your balance, and everything taken from it, shows up here.",
    ),
    "wallet_reason_admin_adjustment": MessageLookupByLibrary.simpleMessage(
      "Adjusted by the studio",
    ),
    "wallet_reason_booking_absent": MessageLookupByLibrary.simpleMessage(
      "No-show refund",
    ),
    "wallet_reason_booking_cancelled": MessageLookupByLibrary.simpleMessage(
      "Cancelled booking refund",
    ),
    "wallet_reason_booking_payment": MessageLookupByLibrary.simpleMessage(
      "Workshop booking",
    ),
    "wallet_reason_booking_rescheduled": MessageLookupByLibrary.simpleMessage(
      "Booking changed",
    ),
    "wallet_reason_delivery_fee": MessageLookupByLibrary.simpleMessage(
      "Delivery fee",
    ),
    "wallet_reason_gift": MessageLookupByLibrary.simpleMessage("Gift balance"),
    "wallet_reason_gift_purchase": MessageLookupByLibrary.simpleMessage(
      "Gift bought",
    ),
    "wallet_reason_order_payment": MessageLookupByLibrary.simpleMessage(
      "Shop order",
    ),
    "wallet_reason_shop_order_cancelled": MessageLookupByLibrary.simpleMessage(
      "Cancelled order",
    ),
    "wizard_back": MessageLookupByLibrary.simpleMessage("Back"),
    "wizard_clear_draft": MessageLookupByLibrary.simpleMessage("Clear draft"),
    "wizard_discard": MessageLookupByLibrary.simpleMessage("Discard"),
    "wizard_discard_draft_body": MessageLookupByLibrary.simpleMessage(
      "Closing will keep your progress saved so you can pick up later.",
    ),
    "wizard_discard_draft_title": MessageLookupByLibrary.simpleMessage(
      "Discard draft?",
    ),
    "wizard_keep_draft": MessageLookupByLibrary.simpleMessage("Keep draft"),
    "wizard_next": MessageLookupByLibrary.simpleMessage("Next"),
    "wizard_submit": MessageLookupByLibrary.simpleMessage("Submit"),
    "wizard_submit_failed": MessageLookupByLibrary.simpleMessage(
      "Submit failed",
    ),
    "workshop_audience_couples": MessageLookupByLibrary.simpleMessage(
      "Couples",
    ),
    "workshop_audience_families": MessageLookupByLibrary.simpleMessage(
      "Families",
    ),
    "workshop_audience_kids": MessageLookupByLibrary.simpleMessage("Kids"),
    "workshop_audience_men": MessageLookupByLibrary.simpleMessage("Men only"),
    "workshop_audience_mixed": MessageLookupByLibrary.simpleMessage(
      "Everyone welcome",
    ),
    "workshop_audience_women": MessageLookupByLibrary.simpleMessage(
      "Women only",
    ),
    "workshop_book": MessageLookupByLibrary.simpleMessage("Book"),
    "workshop_duration_hour": MessageLookupByLibrary.simpleMessage("1 hour"),
    "workshop_duration_minutes": m245,
    "workshop_empty": MessageLookupByLibrary.simpleMessage(
      "No workshops available right now",
    ),
    "workshop_gift": MessageLookupByLibrary.simpleMessage("Gift"),
    "workshop_location": MessageLookupByLibrary.simpleMessage("Location"),
    "workshop_map_pending": MessageLookupByLibrary.simpleMessage(
      "The map opens here once the studio\'s key is wired.",
    ),
    "workshop_no_location": MessageLookupByLibrary.simpleMessage(
      "The studio has not published a location yet.",
    ),
    "workshop_not_specified": MessageLookupByLibrary.simpleMessage(
      "Not specified",
    ),
    "workshop_open_in_maps": MessageLookupByLibrary.simpleMessage(
      "Open in Maps",
    ),
    "workshop_piece_hold": m246,
    "workshop_price_per_person": m247,
    "workshop_price_per_piece": MessageLookupByLibrary.simpleMessage(
      "Priced per piece",
    ),
    "workshop_seats_per_session": m248,
    "workshop_studio_location": MessageLookupByLibrary.simpleMessage(
      "The studio",
    ),
    "workshop_subtitle": MessageLookupByLibrary.simpleMessage(
      "See every available workshop and book the slot that suits you.",
    ),
    "workshop_tab_book": MessageLookupByLibrary.simpleMessage(
      "Book a workshop",
    ),
    "workshop_tab_mine": MessageLookupByLibrary.simpleMessage("My workshops"),
    "workshop_title": MessageLookupByLibrary.simpleMessage(
      "Terracotta workshops",
    ),
    "workshop_view_transactions": MessageLookupByLibrary.simpleMessage(
      "View transactions",
    ),
    "workshop_wallet_balance": MessageLookupByLibrary.simpleMessage(
      "Terracotta balance",
    ),
  };
}
