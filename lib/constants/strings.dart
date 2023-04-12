import 'package:be_there/screens/CreateMeetup/create_meetup.dart';

const String AppTitle = "BeThere";
const String NoMeetupsScheduledText = "No meetups scheduled.";
const String UpcomingMeetupsHeading = "Upcoming Meetups";
const String SignInWithGoogleButton = "Sign in with Google";

const String UsersCollection = "users";
const String MeetupsCollection = "meetups";

// CurrentMeetupPage
const String CurrentMeetupPageHeading = "Current Meetup";
const String NextMeetupPageHeading = "Next Meetup";
const String StartedMeetupSnackbarText = "Starting meetup.";
const String FinishedMeetupSnackbarText = "Meetup complete.";
const String LiveIconText = "LIVE";

// CreateMeetupPage
const String CreateMeetupHeading = "Create meetup";

const String MeetupNameText = "Add title";
const String MeetupNameErrorText = "Please enter a title";

const String MeetupDateText = "Add a date";

const String MeetupTimeText = "Add a time";

const String MeetupAddressText = "Add location";
const String MeetupAddressErrorText = "Please enter a location";

const String MeetupInformalLocationText = "Add a meeting spot name";

const String MeetupFriendsText = "Invite friends";
const String CreatedMeetupSnackbarText = "Created meetup.";
const String CreatedMeetupFailSnackbarText = "Failed to create meetup. Please try again.";

const Map<CreateMeetupStatus, String> CreateMeetupStatusStrings = {
  CreateMeetupStatus.valid: "",
  CreateMeetupStatus.noTitle: "Please add a title.",
  CreateMeetupStatus.invalidDate: "Date is invalid.",
  CreateMeetupStatus.noAddress: "Please choose a location.",
  CreateMeetupStatus.noInvites: "Invite at least 1 friend.",
};

// const String MeetupHasNoTitleErrorText = "Please add a title.";
// const String MeetupInvalidDateErrorText = "Date is invalid.";
// const String MeetupNoAddressErrorText = "Please choose a location.";
// const String MeetupNoFriendsInvitedErrorText = "Invite at least 1 friend.";

// InvitedMeetups Page
const String InvitedMeetupsHeading = "Meetup Invites";
const String NoInvitesTitle = "You're up to date.";
const String NoInvitesSubtitle = "New meetup invites will show up here.";

const String AcceptMeetupInviteText = "Accepted invite to ";
const String AcceptMeetupInviteFailText = "Could not accept meetup invite.";
const String DeclineMeetupInviteFailText = "Could not decline meetup invite.";


// Friends
const String FriendsHeading = "Friends";
const String AddFriendByEmailText = "Add friend by email";
const String EmailPlaceholderText = "Email";
const String SendFriendRequestText = "Send friend request";
const String FriendRequestSuccessfulText = "Friend request sent";
const String FriendRequestFailText = "User does not exist";
const String CannotAddYourselfText = "You cannot add yourself.";
const String EmailInvalidText = "Email is invalid.";
const String UnfriendMenuButton = "Unfriend";
const String AcceptFriendRequestFailText = "Could not accept friend request.";
const String DeclineFriendRequestFailText = "Could not decline friend request.";
const String UnfriendFailText = "Could not unfriend this user.";
const String InviteFailText = "Could not invite this user.";

// Friend Requests
const String FriendRequestsHeading = "Friend Requests";
const String NoFriendRequestsTitle = "You're up to date.";
const String NoFriendRequestsSubtitle = "New friend requests will show up here.";